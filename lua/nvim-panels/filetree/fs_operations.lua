local M = {}

local g_config = require('nvim-panels.config')

local async = require('nvim-panels.filetree.async')
local constants = require('nvim-panels.filetree.constants')
local state = require('nvim-panels.filetree.state')
local ui = require('nvim-panels.filetree.ui')
local utils = require('nvim-panels.filetree.utils')

---
---@param err_log nvim-panels.filetree.err_log_entry[]
local function print_errors(err_log)
	for _, item in ipairs(err_log) do
		vim.notify(item.err or 'Error occurred', vim.log.levels.ERROR)
	end
end

---
---@param old string
---@param new string
---@param operation string
---@return string
local function get_success(old, new, operation)
	return 'Successfully ' .. operation .. ' <' .. old .. '> to <' .. new .. '>'
end

---
---@param path_log nvim-panels.filetree.path_log_entry[]
---@param operation string
---@param change_entry boolean
---@param delete boolean
local function print_successes(path_log, operation, change_entry, delete)
	if not path_log then return end
	local old_path
	local path
	local success
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	for _, item in ipairs(path_log) do
		old_path = vim.fs.relpath(cwd, item[1]) or item[1]
		path = vim.fs.relpath(cwd, item[2]) or item[2]
		success = get_success(old_path, path, operation)
		vim.notify(success, vim.log.levels.INFO)
		if change_entry then
			state.update_item(item[1], not delete and item[2] or nil)
		end
	end
end

---
---@param target string
---@return nvim-panels.filetree.path_list
local function new_path_list(target)
	local items = {}
	return {
		add_path = function(path)
			local basename = vim.fs.basename(path)
			local new_path = vim.fs.joinpath(target, basename)
			table.insert(items, { path, new_path })
		end,
		get_paths = function()
			return items
		end,
	}
end

---
function M.rename()
	local path, _ = utils.get_current_entry()
	local dirname = vim.fs.dirname(path)
	local basename = vim.fs.basename(path)
	vim.ui.input(
		{prompt = 'Rename ' .. basename .. ' to: ',},
		function(input)
			if input == nil then return end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(dirname, input)

				local err_log, path_log = async.await_move_multi({ { path, new_path } })

				vim.schedule(function()
					print_errors(err_log)
					print_successes(path_log, 'renamed', true, false)

					ui.render()
				end)
			end)()
		end
	)
end

---
---@param path string
---@return nvim-panels.filetree.enum.trash_confirm
local function get_delete_prompt(path)
	local co = coroutine.running()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local relpath = vim.fs.relpath(cwd, path)
	local confirm = constants.confirm
	local prompt_prefix = 'Confirm (RECURSIVE) deletion of <'
	local prompt_suffix = '> ([Y]es, [n]o, [a]ll): '
	vim.ui.input(
		{
			prompt = prompt_prefix .. relpath .. prompt_suffix,
		},
		function(input)
			if input == nil then input = 'N'
			elseif input == '' then input = 'Y'
			else input = input:sub(1, 1):upper() end

			if not confirm[input] then
				vim.notify('Invalid input', vim.log.levels.ERROR)
				vim.schedule(function() coroutine.resume(co, confirm.N) end)
				return
			end

			vim.schedule(function() coroutine.resume(co, confirm[input]) end)
		end
	)
	return coroutine.yield()
end

---
function M.delete()
	coroutine.wrap(function()
		local path_list = new_path_list(g_config.options.trash_path)
		local confirm = constants.confirm
		local response = confirm.Y
		local empty = true

		for path in state.sources_iterator() do
			empty = false
			if response ~= confirm.A then
				response = get_delete_prompt(path)
			end

			if response ~= confirm.N then
				path_list.add_path(path)
			end
		end

		if empty then
			local item = utils.get_current_entry()
			response = get_delete_prompt(item)
			if response ~= confirm.N then
				path_list.add_path(item)
			end
		end

		local err_log, path_log = async.await_move_multi(path_list.get_paths())

		vim.schedule(function()
			print_errors(err_log)
			print_successes(path_log, 'moved', true, true)

			state.clear_marked()
			ui.render()
		end)
	end)()
end

---
function M.move()
	coroutine.wrap(function()
		local path_list = new_path_list(state.get_target())
		local empty = true
		for path in state.sources_iterator() do
			empty = false
			path_list.add_path(path)
		end

		if empty then
			local item = utils.get_current_entry()
			path_list.add_path(item)
		end

		local err_log, path_log = async.await_move_multi(path_list.get_paths())

		vim.schedule(function()
			print_errors(err_log)
			print_successes(path_log, 'moved', true, false)

			state.clear_marked()
			ui.render()
		end)
	end)()
end

---
---@param target string
---@return nvim-panels.filetree.copy_log
local function new_copy_log(target)
	local err_logs = {}
	local path_logs = {}
	return {
		copy_path = function(path)
			local err_log, path_log = async.await_copy_recursive(path, target)
			table.insert(err_logs, err_log)
			table.insert(path_logs, path_log)
		end,
		get_logs = function()
			return err_logs, path_logs
		end,
	}
end

---
function M.copy()
	coroutine.wrap(function()
		local log = new_copy_log(state.get_target())
		local empty = true
		for path in state.sources_iterator() do
			empty = false
			log.copy_path(path)
		end

		if empty then
			local item = utils.get_current_entry()
			log.copy_path(item)
		end

		local err_logs, path_logs = log.get_logs()

		vim.schedule(function()
			for _, item in ipairs(err_logs) do
				print_errors(item)
			end

			for _, item in ipairs(path_logs) do
				print_successes(item, 'copied', false, false)
			end

			state.clear_marked()
			ui.render()
		end)
	end)()
end

---
function M.new_file()
	local target = state.get_target()

	vim.ui.input(
		{prompt = 'File name: ',},
		function(input)
			if input == nil or input == '' then return end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(target, input)
				local err, success = async.await_create_file(new_path)

				vim.schedule(function()
					if err then
						print_errors({ { err = err, success = success } })
					end

					state.clear_marked()
					ui.render()
				end)
			end)()
		end
	)
end

---
function M.new_dir()
	local target = state.get_target()

	vim.ui.input(
		{prompt = 'Directory name: ',},
		function(input)
			if input == nil or input == '' then return end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(target, input)
				local err, success = async.await_mkdir(new_path)

				vim.schedule(function()
					if err then
						print_errors({ { err = err, success = success } })
					end

					state.clear_marked()
					ui.render()
				end)
			end)()
		end
	)
end

return M
