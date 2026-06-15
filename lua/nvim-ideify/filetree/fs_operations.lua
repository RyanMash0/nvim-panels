local M = {}

local g_constants = require('nvim-ideify.constants')
local constants = require('nvim-ideify.filetree.constants')
local state = require('nvim-ideify.filetree.state')
local ui = require('nvim-ideify.filetree.ui')
local utils = require('nvim-ideify.filetree.utils')
local async = require('nvim-ideify.filetree.async')

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

				local err_log = async.await_move_multi({ { path, new_path }, })

				state.update_item(path, new_path)
				ui.render()
			end)()
		end
	)
end

local function get_delete_prompt(path)
	local co = coroutine.running()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local relpath = vim.fs.relpath(cwd, path)
	local confirm = constants.confirm
	vim.ui.input(
		{
			prompt = 'Confirm (RECURSIVE) deletion of <' .. relpath .. '> ([Y]es, [n]o, [a]ll): ',
		},
		function(input)
			if input == nil then input = 'N'
			elseif input == '' then input = 'Y'
			else input = input:sub(1, 1):lower() end

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
	local trash_path = g_constants.trash_path
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
				state.update_item(path, nil)
			end
		end

		local err_log = async.await_move_multi(items)

		state.clear_marked()
		ui.render()
		vim.notify('Items successfully moved to ~' .. g_constants.rel_trash_path, vim.log.levels.INFO)
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
			state.update_item(path, new_path)
		end

		local err_log = async.await_move_multi(items)

		state.clear_marked()
		ui.render()
	end)()
end

function M.copy()
	local target = state.get_target()
	coroutine.wrap(function()
		local err_logs = {}
		for path in state.sources_iterator() do
			table.insert(err_logs, async.await_copy_recursive(path, target))
		end

		state.clear_marked()
		ui.render()
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
				state.remove_target()
				ui.render()
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
				state.remove_target()
				ui.render()
			end)()
		end
	)
end

return M
