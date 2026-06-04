local M = {}
local state = require('nvim-ideify.filetree.state')
local utils = require('nvim-ideify.filetree.utils')
local g_state = require('nvim-ideify.state')
local g_utils = require('nvim-ideify.utils')

local function generate_tree_action(line, func)
	local buf_id = state:get_buffer()
	vim.bo[buf_id].modifiable = true
	func(line)
	vim.bo[buf_id].modifiable = false
end

local function print_paths(start_line)
	local tree = state.tree
	local buf_id = state:get_buffer()
	local parent = tree[start_line]
	local depth = parent.depth + 1
	local path = parent.path
	local dir_iterator = vim.fs.dir(path)
	local prefix = ''
	for _ = 1, depth do
		prefix = prefix .. '| '
	end

	local indicator
	if depth < 0 then
		indicator = {dir_closed = '', dir_open = '', other = ''}
	else
		indicator = {dir_closed = '> ', dir_open = 'v ', other = '+ '}
	end

	local dirs = 0
	local other = 0
	local entries = 0
	local extra = 0
	local dir_type
	local line
	local expanded
	local entry
	local entry_path
	for name, type in dir_iterator do
		entries = entries + 1
		entry_path = path .. '/' .. name
		entry = {
			depth = depth,
			path = entry_path,
			type = type,
		}
		expanded = state.expanded[entry_path]

		if type == 'directory' then
			line = start_line + dirs + extra
			dirs = dirs + 1
			if expanded then dir_type = indicator.dir_open
			else dir_type = indicator.dir_closed end
			name = dir_type .. name .. '/'
		else
			line = start_line + dirs + other + extra
			other = other + 1
			name = indicator.other .. name
		end

		table.insert(tree, line + 1, entry)
		vim.api.nvim_buf_set_lines(buf_id, line, line, true, {prefix..name})

		if state.expanded[entry_path] then
			extra = extra + print_paths(line + 1)
		end
	end

	return entries + extra
end

local function expand(line)
	local buf_id = state:get_buffer()
	local parent = state.tree[line]
	local expanded = state.expanded
	expanded[parent.path] = true
	local name = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	name = name:gsub('>', 'v', 1)
	vim.api.nvim_buf_set_lines(buf_id, line - 1, line, true, {name})
	print_paths(line)
end

local function close(line)
	local buf_id = state:get_buffer()
	local tree = state.tree
	local parent = tree[line]
	local expanded = state.expanded
	expanded[parent.path] = nil

	local name = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	name = name:gsub('v', '>', 1)
	vim.api.nvim_buf_set_lines(buf_id, line - 1, line, true, {name})

	local path
	local i = 1
	while tree[line + i].depth > parent.depth do
		path = tree[line + i].path
		state.fs_sources[path] = nil
		state.fs_target[path] = nil
		i = i + 1
	end

	M.render()
end

function M.change_dir(path)
	g_utils.check_or_make_main_win()
	vim.schedule(function ()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			vim.api.nvim_win_call(win, function () vim.cmd('silent lcd' .. path) end)
		end
		M.render()
		vim.api.nvim_set_current_win(state:get_window())
		require('nvim-ideify.bufferbar'):get_ui().render()
	end)
end

function M.ascend()
	vim.schedule(function ()
		local new_path = vim.fs.abspath('.'):gsub('/[^/]+$', '')
		if new_path == '' then new_path = '/' end
		state.fs_sources = {}
		state.fs_target = {}
		M.change_dir(new_path)
	end)
end

function M.descend()
	local line = vim.fn.line('.')
	if state.tree[line].type ~= 'directory' then return end
	local path = state.tree[line].path
	state.fs_sources = {}
	state.fs_target = {}
	M.change_dir(path)
end

function M.action()
	local buf_id = state:get_buffer()
	local line = vim.fn.line('.')
	local header_height = state:get_header_height()

	if line <= header_height then
		return
	elseif line == header_height + 1 then
		M.ascend()
		return
	end

	local line_str = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	line_str = line_str:gsub('| ', ''):gsub('/', ''):gsub('[>v+] ', '')

	local tree = state.tree
	local parent = tree[line]
	if parent.type == 'file' then
		g_utils.check_or_make_main_win()
		local last_win =
			g_utils.win_valid(g_state.wins.last) and g_state.wins.last
		local win = last_win or g_state.wins.main
		vim.api.nvim_set_current_win(win)
		vim.cmd('edit ' .. parent.path)
		vim.api.nvim_set_current_win(state:get_window())
		return
	end

	if parent.type == 'directory' and state.expanded[parent.path] then
		generate_tree_action(line, close)
	elseif parent.type == 'directory' and not state.expanded[parent.path] then
		generate_tree_action(line, expand)
	end

	M.highlight()
	return ''
end

function M.highlight()
	local buf_id = state:get_buffer()
	local ns_id = state:get_namespace()
	vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
	local tree = state.tree
	local dir_hl = vim.api.nvim_get_hl_id_by_name('netrwDir')
	local bar_hl = vim.api.nvim_get_hl_id_by_name('Special')
	local plain_hl = vim.api.nvim_get_hl_id_by_name('netrwPlain')
	local header_hl = vim.api.nvim_get_hl_id_by_name('netrwComment')
	local target_hl = vim.api.nvim_get_hl_id_by_name('IDEifyTreeTarget')
	local source_hl = vim.api.nvim_get_hl_id_by_name('IDEifyTreeSource')

	local name_start
	local line_len
	local hl_group
	for i, entry in ipairs(tree) do
		name_start = entry.depth > 0 and entry.depth * 2 or 0
		line_len = #vim.api.nvim_buf_get_lines(buf_id, i - 1, i, true)[1]
		vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, 0, {end_col = name_start, hl_group = bar_hl})

		if entry.type == 'Header' then
			hl_group = header_hl
		elseif entry.type == 'directory' then
			hl_group = dir_hl
		else
			hl_group = plain_hl
		end

		if state.fs_target[entry.path] then
			hl_group = target_hl
		end

		if state.fs_sources[entry.path] then
			hl_group = source_hl
		end

		vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, name_start, {end_col = line_len, hl_group = hl_group})
	end
end

local function get_cur_line()
	local win_id = state:get_window()
	local pos = vim.api.nvim_win_get_cursor(win_id)
	pos[1] = pos[1] - (state:get_header_height() or 0)
	return math.max(pos[1], 1)
end

local function set_cur_line(line)
	local buf_id = state:get_buffer()
	local win_id = state:get_window()
	local max_row = vim.api.nvim_buf_line_count(buf_id)
	line = line + (state:get_header_height() or 0)
	line = line <= max_row and line or max_row
	vim.api.nvim_win_set_cursor(win_id, { line, 0 })
end

function M.render()
	local buf_id = state:get_buffer()
	local win_id = state:get_window()
	local path = vim.fs.abspath('.')
	local header_entry = {
		depth = -1,
		path = path,
		type = 'Header',
	}
	local parent_dir_entry = {
		depth = -1,
		path = path,
		type = 'directory',
	}
	local cur_line = get_cur_line()

	local header = utils.get_full_header()

	local header_height = state:get_header_height()
	table.insert(header, '../')

	local starting_array = {}
	for _ = 1, header_height do
		table.insert(starting_array, header_entry)
	end
	table.insert(starting_array, parent_dir_entry)

	state.tree = starting_array

	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(buf_id, 0, 1, true, header)
	vim.api.nvim_win_set_cursor(win_id, {header_height + 1, 0})
	print_paths(header_height + 1)
	vim.bo[buf_id].modifiable = false
	M.highlight()
	set_cur_line(cur_line)
end

return M
