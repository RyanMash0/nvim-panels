local M = {}

local buffer = -1
local window = -1
local win_config = {}
local on_click = nil

local header_height = 0
local line_to_entry = {}
local line_to_text = {}
local fs_expanded = {}
local fs_target = {}
local fs_sources = {}

function M.get_buffer()
	return buffer
end

function M.set_buffer(buf_id)
	buffer = buf_id
end

function M.get_window()
	return window
end

function M.set_window(win_id)
	window = win_id
end

function M.get_win_config()
	return win_config
end

function M.set_win_config(config)
	win_config = config
end

function M.get_on_click()
	return on_click
end

function M.set_on_click(fun)
	on_click = fun
end

function M.set_header_height(height)
	header_height = height
end

function M.get_header_height()
	return header_height
end

function M.get_entry_by_line(line)
	return line_to_entry[line]
end

function M.get_text_by_line(line)
	return line_to_text[line]
end

function M.set_text_by_line(text, line)
	line_to_text[line] = text
end

function M.get_text()
	return line_to_text
end

function M.clear_text()
	line_to_text = {}
end

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

function M.remove_tree_entry(line)
	if not line then return end

	table.remove(line_to_entry, line)
	table.remove(line_to_text, line)
end

function M.clear_entries()
	line_to_entry = {}
end

local function tree_iterator(_, i)
	i = i + 1
	local entry = line_to_entry[i]
	if not entry then return end

	return i, entry
end

function M.tree_iterator(start_pos)
	return tree_iterator, nil, (start_pos and start_pos - 1) or 0
end

function M.is_expanded(path)
	return fs_expanded[path or '']
end

function M.register_expanded(path)
	if not path then return end
	fs_expanded[path] = true
end

function M.remove_expanded(path)
	if not path then return end
	fs_expanded[path] = nil
end

function M.clear_expanded()
	fs_expanded = {}
end

function M.expanded_iterator()
	return next, fs_expanded, nil
end

function M.get_target()
	local target, _ = next(fs_target)
	return target or vim.uv.cwd() or vim.fn.getcwd()
end

function M.mark_target(path)
	if not path then return end
	for source in M.sources_iterator() do
		if vim.fs.relpath(source, M.get_target()) then
			return
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

function M.remove_target()
	fs_target = {}
end

function M.is_target(path)
	return fs_target[path or '']
end

function M.mark_source(path)
	if not path then return end
	if vim.fs.relpath(path, M.get_target()) then
		return
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

function M.remove_source(path)
	fs_sources[path] = nil
end

function M.is_source(path)
	return fs_sources[path or '']
end

function M.clear_marked()
	fs_target = {}
	fs_sources = {}
end

function M.sources_iterator()
	return next, fs_sources, nil
end

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
