local M = {}

local g_config = require('nvim-ideify.config')

local async = require('nvim-ideify.filetree.async')
local constants = require('nvim-ideify.filetree.constants')
local state = require('nvim-ideify.filetree.state')
local ui = require('nvim-ideify.filetree.ui')
local utils = require('nvim-ideify.filetree.utils')

local function print_errors(err_log)
	for _, item in ipairs(err_log) do
		vim.notify(item.err or item, vim.log.levels.ERROR)
	end
end

local function get_success(old, new, operation)
	return 'Successfully ' .. operation .. ' <' .. old .. '> to <' .. new .. '>'
end

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

function M.rename()
	local path, _ = utils.get_current_entry()
	local dirname = vim.fs.dirname(path)
	local basename = vim.fs.basename(path)
	vim.ui.input(
		{prompt = 'Rename ' .. basename .. ' to: ',},
		function(input)
			if input == nil then input = basename end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(dirname, input)

				local err_log, path_log = async.await_move_multi({ { path, new_path }, })

				print_errors(err_log)
				print_successes(path_log, 'renamed', true, false)

				vim.schedule(ui.render)
			end)()
		end
	)
end

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

function M.delete()
	local trash_path = g_config.options.trash_path
	coroutine.wrap(function()
		local basename
		local new_path
		local items = {}
		local confirm = constants.confirm
		local response = confirm.Y
		for path in state.sources_iterator() do
			if response ~= confirm.A then
				response = get_delete_prompt(path)
			end

			if response ~= confirm.N then
				basename = vim.fs.basename(path)
				new_path = vim.fs.joinpath(trash_path, basename)
				table.insert(items, { path, new_path })
			end
		end

		local err_log, path_log = async.await_move_multi(items)

		print_errors(err_log)
		print_successes(path_log, 'moved', true, true)

		vim.schedule(state.clear_marked)
		vim.schedule(ui.render)
	end)()
end

function M.move()
	local target = state.get_target()
	coroutine.wrap(function()
		local basename
		local new_path
		local items = {}
		for path in state.sources_iterator() do
			basename = vim.fs.basename(path)
			new_path = vim.fs.joinpath(target, basename)
			table.insert(items, { path, new_path })
		end

		local err_log, path_log = async.await_move_multi(items)

		print_errors(err_log)
		print_successes(path_log, 'moved', true, false)

		vim.schedule(state.clear_marked)
		vim.schedule(ui.render)
	end)()
end

function M.copy()
	local target = state.get_target()
	local err_logs = {}
	local path_logs = {}
	local err_log, path_log
	coroutine.wrap(function()
		for path in state.sources_iterator() do
			err_log, path_log = async.await_copy_recursive(path, target)
			table.insert(err_logs, err_log)
			table.insert(path_logs, path_log)
		end

		for _, item in ipairs(err_logs) do
			print_errors(item)
		end

		for _, item in ipairs(path_logs) do
			print_successes(item, 'copied', false, false)
		end

		vim.schedule(state.clear_marked)
		vim.schedule(ui.render)
	end)()
end

function M.file_new()
	local target = state.get_target()

	vim.ui.input(
		{prompt = 'File name: ',},
		function(input)
			if input == nil or input == '' then return end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(target, input)
				local err, success = async.await_create_file(new_path)
				if err then
					print_errors({ { err = err, success = success } })
				end

				vim.schedule(state.clear_marked)
				vim.schedule(ui.render)
			end)()
		end
	)
end

function M.dir_new()
	local target = state.get_target()

	vim.ui.input(
		{prompt = 'Directory name: ',},
		function(input)
			if input == nil or input == '' then return end

			coroutine.wrap(function()
				local new_path = vim.fs.joinpath(target, input)
				local err, success = async.await_mkdir(new_path)
				if err then
					print_errors({ { err = err, success = success } })
				end

				vim.schedule(state.clear_marked)
				vim.schedule(ui.render)
			end)()
		end
	)
end

return M
