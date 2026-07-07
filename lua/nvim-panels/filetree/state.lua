local M = {}

local g_constants = require('nvim-panels.constants')

local buffer = g_constants.NOID
local window = g_constants.NOID
local on_click = nil

local header_height = 0
local cwd = vim.uv.cwd() or vim.fn.cwd()
local line_to_entry = {}
local line_to_text = {}
local fs_expanded = {}
local fs_target = {}
local fs_sources = {}

---
---@return nvim-panels.buf_id
function M.get_buffer()
	return buffer
end

---
---@param buf_id nvim-panels.buf_id
function M.set_buffer(buf_id)
	buffer = buf_id
end

---
---@return nvim-panels.win_id
function M.get_window()
	return window
end

---
---@param win_id nvim-panels.win_id
function M.set_window(win_id)
	window = win_id
end

---
---@return fun()?
function M.get_on_click()
	return on_click
end

---
---@param fun fun()
function M.set_on_click(fun)
	on_click = fun
end

---
---@return integer
function M.get_header_height()
	return header_height
end

---
---@param height integer
function M.set_header_height(height)
	header_height = height
end

---
---@return string
function M.get_cwd()
	return cwd
end

---
---@param dir string
function M.set_cwd(dir)
	cwd = dir
end

---
---@param line integer
---@return nvim-panels.filetree.entry
function M.get_entry_by_line(line)
	return line_to_entry[line]
end

---
---@param line integer
---@return string
function M.get_text_by_line(line)
	return line_to_text[line]
end

---
---@param text string
---@param line integer
function M.set_text_by_line(text, line)
	line_to_text[line] = text
end

---
---@return string[]
function M.get_text()
	return line_to_text
end

---
function M.clear_text()
	line_to_text = {}
end

---
---@param entry? nvim-panels.filetree.entry
---@param text? string
---@param line? integer
function M.insert_tree_entry(entry, text, line)
	if not entry or not text then return end

	if not line then
		table.insert(line_to_entry, entry)
		table.insert(line_to_text, text)
	else
		table.insert(line_to_entry, line, entry)
		table.insert(line_to_text, line, text)
	end
end

---
---@param line? integer
function M.remove_tree_entry(line)
	if not line then return end

	table.remove(line_to_entry, line)
	table.remove(line_to_text, line)
end

---
function M.clear_entries()
	line_to_entry = {}
end

---
local function tree_iterator(_, i)
	i = i + 1
	local entry = line_to_entry[i]
	if not entry then return end

	return i, entry
end

---
---@param start_pos? integer
---@return nvim-panels.filetree.do_tree_iterator, nil, integer
function M.tree_iterator(start_pos)
	return tree_iterator, nil, (start_pos and start_pos - 1) or 0
end

---
---@param path? string
---@return boolean
function M.is_expanded(path)
	return path and fs_expanded[path] or false
end

---
---@param path? string
function M.register_expanded(path)
	if not path then return end
	fs_expanded[path] = true
end

---
---@param path? string
function M.remove_expanded(path)
	if not path then return end
	fs_expanded[path] = nil
end

---
function M.clear_expanded()
	fs_expanded = {}
end

---
---@return nvim-panels.do_generic_iterator, table<string, boolean>, string?
function M.expanded_iterator()
	return next, fs_expanded, nil
end

---
---@return string
function M.get_target()
	local target, _ = next(fs_target)
	return target or M.get_cwd()
end

---
---@param path? string
function M.mark_target(path)
	if not path then return end
	for source in M.sources_iterator() do
		if vim.fs.relpath(source, path) then
			M.remove_source(source)
		end
	end

	local was_target = fs_target[path]
	M.remove_target()

	if was_target then return end

	fs_target[path] = true

	if fs_sources[path] then
		M.remove_source(path)
	end
end

---
function M.remove_target()
	fs_target = {}
end

---
---@param path? string
---@return boolean
function M.is_target(path)
	return path and fs_target[path] or false
end

---
---@param path? string
function M.mark_source(path)
	if not path then return end
	local sub_target = vim.fs.relpath(path, M.get_target())
	if sub_target and sub_target ~= '.' then
		M.remove_target()
	end

	if fs_sources[path] then
		M.remove_source(path)
		return
	end

	for source in M.sources_iterator() do
		if vim.fs.relpath(path, source) then
			M.remove_source(source)
		elseif vim.fs.relpath(source, path) then
			M.remove_source(source)
		end
	end

	fs_sources[path] = true

	if fs_target[path] then
		M.remove_target()
	end
end

---
---@param path string
function M.remove_source(path)
	fs_sources[path] = nil
end

---
---@param path? string
---@return boolean
function M.is_source(path)
	return path and fs_sources[path] or false
end

---
function M.clear_marked()
	fs_target = {}
	fs_sources = {}
end

---
---@return nvim-panels.do_generic_iterator, table<string, boolean>, string?
function M.sources_iterator()
	return next, fs_sources, nil
end

---
---@param path string
---@param new_path? string
local function update_expanded_subdirs(path, new_path)
	local new_subpath
	local relpath
	for expanded in M.expanded_iterator() do
		relpath = vim.fs.relpath(path, expanded)
		if relpath then
			new_subpath = new_path and vim.fs.joinpath(new_path, relpath) or nil
			M.remove_expanded(expanded)
			M.register_expanded(new_subpath)
		end
	end
end

---
---@param path string
---@param new_path? string
function M.update_item(path, new_path)
	if fs_target[path] then
		M.mark_target(new_path)
	end

	if fs_sources[path] then
		M.remove_source(path)
		M.mark_source(new_path)
	end

	if fs_expanded[path] then
		M.remove_expanded(path)
		M.register_expanded(new_path)
		update_expanded_subdirs(path, new_path)
	end
end

return M
