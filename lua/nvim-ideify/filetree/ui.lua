local M = {}
local state = require('nvim-ideify.filetree.state')
local utils = require('nvim-ideify.filetree.utils')
local constants = require('nvim-ideify.filetree.constants')
local g_state = require('nvim-ideify.state')
local g_utils = require('nvim-ideify.utils')

M.get_default_header = utils.get_default_header
M.get_cwd_array = utils.get_cwd_array
M.get_target_array = utils.get_target_array
M.get_path_array = utils.get_path_array

local function get_cur_line()
	local win_id = state.get_window()
	local pos = vim.api.nvim_win_get_cursor(win_id)
	pos[1] = pos[1] - (state.get_header_height() or 0)
	return math.max(pos[1], 1)
end

local function set_cur_line(line)
	local buf_id = state.get_buffer()
	local win_id = state.get_window()
	local max_row = vim.api.nvim_buf_line_count(buf_id)
	line = line + (state.get_header_height() or 0)
	line = line <= max_row and line or max_row
	vim.api.nvim_win_set_cursor(win_id, { line, 0 })
end

local function get_entries(start_line)
	local parent = state.get_entry_by_line(start_line)
	local depth = parent.depth + 1
	local path = parent.path
	local prefix = ''
	prefix = g_utils.repeat_str('| ', depth)

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
	for name, type in vim.fs.dir(path) do
		entries = entries + 1
		entry_path = vim.fs.joinpath(path, name)
		entry = {
			depth = depth,
			path = entry_path,
			type = type,
		}

		expanded = state.is_expanded(entry_path)

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

		state.insert_tree_entry(entry, prefix..name, line + 1)

		if expanded then
			extra = extra + get_entries(line + 1)
		end
	end

	return entries + extra
end

local function print_paths()
	local buf_id = state.get_buffer()
	local cur_line = get_cur_line()
	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, state.get_text())
	vim.bo[buf_id].modifiable = false
	set_cur_line(cur_line)
end

local function expand(line)
	local parent = state.get_entry_by_line(line)
	state.register_expanded(parent.path)
	local name = state.get_text_by_line(line)
	name = name:gsub('>', 'v', 1)
	state.set_text_by_line(name, line)
	get_entries(line)
	print_paths()
end

local function close(line)
	local parent = state.get_entry_by_line(line)
	state.remove_expanded(parent.path)

	local name = state.get_text_by_line(line)
	name = name:gsub('v', '>', 1)
	state.set_text_by_line(name, line)

	local path
	local cur_entry = state.get_entry_by_line(line + 1)
	while ((cur_entry and cur_entry.depth) or -1) > parent.depth do
		path = cur_entry.path
		state.remove_source(path)
		if state.is_target(path) then
			state.remove_target()
		end
		state.remove_tree_entry(line + 1)
		cur_entry = state.get_entry_by_line(line + 1)
	end

	print_paths()
end

function M.change_dir(path)
	g_utils.check_or_make_main_win()
	vim.schedule(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			vim.api.nvim_win_call(win, function()
				vim.cmd.lcd({ args = { path }, mods = { silent = true }})
			end)
		end
		M.render()
		vim.api.nvim_set_current_win(state.get_window())
		require('nvim-ideify.bufferbar').get_ui().render()
	end)
end

function M.ascend()
	vim.schedule(function()
		local cwd = vim.uv.cwd() or vim.fn.getcwd()
		local new_path = vim.fs.dirname(cwd)

		state.clear_marked()
		M.change_dir(new_path)
	end)
end

function M.descend()
	local path, type = utils.get_current_entry()
	if type ~= 'directory' then return end
	state.clear_marked()
	M.change_dir(path)
end

function M.action()
	local win = state.get_window()
	local line = vim.api.nvim_win_get_cursor(win)[1]
	local header_height = state.get_header_height()

	if line <= header_height then
		return
	elseif line == header_height + 1 then
		M.ascend()
		return
	end

	local parent = state.get_entry_by_line(line)
	if parent.type == 'file' then
		g_utils.check_or_make_main_win()
		local last_win =
			g_utils.win_valid(g_state.wins.last) and g_state.wins.last
		last_win = last_win or g_state.wins.main
		vim.api.nvim_set_current_win(last_win)

		local new_buf = vim.fn.bufnr(parent.path, false)
		if new_buf == -1 then
			vim.cmd.edit({ args = { parent.path } })
		else
			g_utils.set_last_win_buf(new_buf)
			vim.bo[new_buf].buflisted = true
		end
		vim.api.nvim_set_current_win(state.get_window())
		return
	end

	local expanded = state.is_expanded(parent.path)
	if parent.type == 'directory' and expanded then
		close(line)
	elseif parent.type == 'directory' and not expanded then
		expand(line)
	end

	M.highlight()
	return ''
end

function M.highlight()
	local buf_id = state.get_buffer()
	local ns_id = constants.namespace
	vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
	local dir_hl = vim.api.nvim_get_hl_id_by_name('netrwDir')
	local bar_hl = vim.api.nvim_get_hl_id_by_name('Special')
	local plain_hl = vim.api.nvim_get_hl_id_by_name('netrwPlain')
	local header_hl = vim.api.nvim_get_hl_id_by_name('netrwComment')
	local target_hl = vim.api.nvim_get_hl_id_by_name('IDEifyTreeTarget')
	local source_hl = vim.api.nvim_get_hl_id_by_name('IDEifyTreeSource')

	local name_start
	local line_len
	local hl_group
	for i, entry in state.tree_iterator() do
		name_start = entry.depth > 0 and entry.depth * 2 or 0
		line_len = #state.get_text_by_line(i)
		vim.api.nvim_buf_set_extmark(
			buf_id, ns_id, i - 1, 0,
			{end_col = name_start, hl_group = bar_hl}
		)

		if entry.type == 'Header' then
			hl_group = header_hl
		elseif entry.type == 'directory' then
			hl_group = dir_hl
		else
			hl_group = plain_hl
		end

		if state.is_target(entry.path) then
			hl_group = target_hl
		end

		if state.is_source(entry.path) then
			hl_group = source_hl
		end

		vim.api.nvim_buf_set_extmark(
			buf_id, ns_id, i - 1, name_start,
			{end_col = line_len, hl_group = hl_group}
		)
	end
end

function M.render()
	local path = vim.uv.cwd() or vim.fn.getcwd()
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
	local header = utils.get_full_header()

	local header_height = state.get_header_height()

	state.clear_entries()
	state.clear_text()
	for _, text in ipairs(header) do
		state.insert_tree_entry(header_entry, text)
	end
	state.insert_tree_entry(parent_dir_entry, '../')

	get_entries(header_height + 1)
	print_paths()

	M.highlight()
end

return M
