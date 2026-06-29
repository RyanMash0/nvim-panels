local M = {}

local g_constants = require('nvim-ideify.constants')

local config = require('nvim-ideify.filetree.config')
local state = require('nvim-ideify.filetree.state')

---
function M.go_to_dir()
	local ui = require('nvim-ideify.filetree.ui')
	local fs_type = g_constants.fs_type
	vim.ui.input({
		prompt = "Path: ",
		completion = fs_type.FILE,
	}, function(input)
		if not input then return end
		local path = vim.fs.normalize(input)
		path = vim.fs.abspath(input)
		local stat, err = vim.uv.fs_stat(path)

		if err or not stat or stat.type ~= fs_type.DIRECTORY then
			vim.notify('Invalid Directory', vim.log.levels.ERROR)
			return
		end
		ui.change_dir(path)
	end)
end

---
---@param path string
function M.unmark_subdirectories(path)
	local target = state.get_target()
	local relpath = vim.fs.relpath(path, target)
	if relpath and relpath ~= '.' then
		state.remove_target()
	end

	for source in state.sources_iterator() do
		relpath = vim.fs.relpath(path, source)
		if relpath and relpath ~= '.' then
			state.remove_source(source)
		end
	end
end

---
---@param text string
---@param path string
---@param incl_base boolean
---@return string[]
function M.get_path_array(text, path, incl_base)
	local win_id = state.get_window()
	local win_conf = vim.api.nvim_win_get_config(win_id)
	local size = win_conf.width or win_conf.height
	local spaces = '    '
	--local spaces = string.rep(' ', #text)

	local path_item_array = {}
	for parent in vim.fs.parents(path) do
		parent = vim.fs.basename(parent) .. '/'
		if parent == './' and not incl_base then break end
		table.insert(path_item_array, 1, parent)
	end

	local path_array_tables = { { text }, }
	local idx = 1
	local cur_len = #text
	for _, item in ipairs(path_item_array) do
		if cur_len + #item < size then
			table.insert(path_array_tables[idx], item)
			cur_len = cur_len + #item
		else
			path_array_tables[idx + 1] = { spaces, item }
			cur_len = #spaces + #item
			idx = idx + 1
		end
	end

	local path_array = {}
	for i = 1, #path_array_tables do
		table.insert(path_array, table.concat(path_array_tables[i]))
	end

	return path_array
end

---
---@return string[]
function M.get_target_array()
	local target = state.get_target()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()

	target = vim.fs.relpath(cwd, target) .. '/'

	return M.get_path_array(' Target: ', target, true)
end

---
---@return string[]
function M.get_cwd_array()
	local path = vim.uv.cwd() or vim.fn.getcwd()
	local home_dir = vim.uv.os_homedir()
	if home_dir then
		path = path:gsub(home_dir, '~')
	end

	return M.get_path_array(' Working Dir: ', path, false)
end

---
---@return string[]
function M.get_default_header()
	local win_id = state.get_window()
	local win_conf = vim.api.nvim_win_get_config(win_id)
	local size = win_conf.width or win_conf.height
	local border = string.rep('=', size)
	local title_line = ' File Tree'
	local cwd_array = M.get_cwd_array()
	local target_array = M.get_target_array()
	local header = {}

	table.insert(header, border)
	table.insert(header, title_line)

	for _, item in ipairs(cwd_array) do
		table.insert(header, item)
	end

	for _, item in ipairs(target_array) do
		table.insert(header, item)
	end

	table.insert(header, border)

	return header
end

---
---@return string[]
function M.get_full_header()
	local header = config.options.header() or M.get_default_header()

	if config.options.show_keymaps then
		for _, line in pairs(config.options.keymaps_info) do
			table.insert(header, line)
		end
	end

	state.set_header_height(#header)
	return header
end

---
---@return string, nvim-ideify.enum.fs_type
function M.get_current_entry()
	local win = state.get_window()
	local line = vim.api.nvim_win_get_cursor(win)[1]
	local entry = state.get_entry_by_line(line)
	return entry.path, entry.type
end

---
function M.mark_target()
	local ui = require('nvim-ideify.filetree.ui')
	local fs_type = g_constants.fs_type
	local path, type = M.get_current_entry()
	if type ~= fs_type.DIRECTORY then return end

	state.mark_target(path)
	vim.schedule(ui.render)
end

---
function M.mark_source()
	local ui = require('nvim-ideify.filetree.ui')
	local path, _ = M.get_current_entry()

	state.mark_source(path)
	vim.schedule(ui.render)
end

---
function M.open_subdirectories()
	local ui = require('nvim-ideify.filetree.ui')
	local fs_type = g_constants.fs_type
	local target = state.get_target()
	local path

	state.register_expanded(target)
	for name, type in vim.fs.dir(target) do
		if type == fs_type.DIRECTORY then
			path = vim.fs.joinpath(target, name)
			state.register_expanded(path)
		end
	end

	state.remove_target()
	vim.schedule(ui.render)
end

---
function M.close_subdirectories()
	local ui = require('nvim-ideify.filetree.ui')
	local fs_type = g_constants.fs_type
	local target = state.get_target()
	local path

	for name, type in vim.fs.dir(target) do
		if type == fs_type.DIRECTORY then
			path = vim.fs.joinpath(target, name)
			state.remove_expanded(path)
		end
	end

	M.unmark_subdirectories(target)
	state.remove_target()
	vim.schedule(ui.render)
end

return M
