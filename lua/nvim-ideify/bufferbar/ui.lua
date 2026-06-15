local M = {}
local config = require('nvim-ideify.bufferbar.config')
local state = require('nvim-ideify.bufferbar.state')
local constants = require('nvim-ideify.bufferbar.constants')
local utils = require('nvim-ideify.bufferbar.utils')
local g_utils = require('nvim-ideify.utils')

local function truncate_end(str, num)
	if #str <= num then return str end
	return str:sub(1, num - 3) .. '...'
end

local function truncate_middle(path, num)
	if #path <= num then return path end
	local suffix = vim.fs.basename(path)
	local tmp = path
	local prefix
	while tmp ~= '.' do
		prefix = tmp
		tmp = vim.fs.dirname(tmp)
	end

	return prefix .. '/.../' .. suffix .. '/'
end

local function extend_length(str, num)
	if #str == num then return str end
	for _ = 1, num - #str do
		str = str .. ' '
	end
	return str
end

local function buffer_delete(buf)
		local cur_buf = g_utils.get_last_win_buf()
		local del_entry = state.get_entry_by_buf(buf)
		local del_pos = del_entry.position
		local is_last_buf = del_pos == state.get_num_bufs()
		local new_pos = is_last_buf and del_pos - 1 or del_pos + 1
		local new_buf = state.get_buf_by_pos(new_pos)
		if not g_utils.buf_valid(new_buf) then new_buf = 0 end
		vim.api.nvim_buf_delete(buf, {})
		M.render()
		local col = state.get_button_by_buf(new_buf)
		vim.api.nvim_win_set_cursor(state.get_window(), col and { 1, col } or { 2, 1 })

		if buf ~= cur_buf then return cur_buf end

		return new_buf
end

local function buffer_switch()
	local switch_buf = utils.get_sel_buffer()

	return switch_buf
end

function M.action()
	local win_id = state.get_window()
	local pos = vim.api.nvim_win_get_cursor(win_id)
	local cur_col = pos[2]
	local button = pos[1] == 1 and state.get_buf_by_button(cur_col)
	local check_button = button and not vim.bo[button].modified
	local buf = check_button and buffer_delete(button) or buffer_switch()

	g_utils.set_last_win_buf(buf)
end

function M.highlight()
	g_utils.check_or_make_main_win()
	local buf_id = state.get_buffer()
	local ns = constants.namespace
	vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
	local cur_buf = g_utils.get_last_win_buf()
	local yanked = state.get_yanked()
	local hl_region = state.get_entry_by_buf(cur_buf)
	local yank_hl_region = state.get_entry_by_buf(yanked)
	local hl_group = vim.api.nvim_get_hl_id_by_name('TabLineSel')
	local yank_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarYank')
	local close_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarClose')
	local modified_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarModified')
	if not hl_region or hl_region == vim.NIL then return end
	local button_len = #config.options.styling.button.close

	for buf, entry in state.buf_entries_iterator() do
		if not entry.last then return end
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, entry.last - button_len, {
			end_col = entry.last,
			hl_group = vim.bo[buf].modified and modified_hl_group or close_hl_group,
		})
	end

	if cur_buf ~= yanked then
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, hl_region.first, {
			end_col = hl_region.last,
			hl_group = hl_group,
		})

		vim.api.nvim_buf_set_extmark(buf_id, ns, 1, hl_region.first, {
			end_col = hl_region.last,
			hl_group = hl_group,
		})
	end

	if yank_hl_region then
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, yank_hl_region.first, {
			end_col = yank_hl_region.last,
			hl_group = yank_hl_group,
		})

		vim.api.nvim_buf_set_extmark(buf_id, ns, 1, yank_hl_region.first, {
			end_col = yank_hl_region.last,
			hl_group = yank_hl_group,
		})
	end
end

function M.render()
	local buf_id = state.get_buffer()
	if not g_utils.buf_valid(buf_id) then return end
	state.clear_buf_data()

	local remove_bufs = {}
	for i, buf in state.buf_iterator() do
		if not vim.bo[buf].buflisted then
			table.insert(remove_bufs, 1, i)
		end
	end

	for _, i in ipairs(remove_bufs) do
		state.remove_buffer(i)
	end

	local buf_name
	local file_name
	local dir_name
	local dir_table = {}
	local file_table = {}
	local pref_len = config.options.name_pref_length
	local truncate_len
	local max_len
	local interact
	local cur_len = 0
	local minimal = config.options.minimal
	local normal_pad_pre = config.options.styling.padding.normal.before
	local min_pad_pre = config.options.styling.padding.minimal.before
	local pad_pre = minimal and min_pad_pre or normal_pad_pre
	local normal_pad_post = config.options.styling.padding.normal.after
	local min_pad_post = config.options.styling.padding.minimal.after
	local pad_post = minimal and min_pad_post or normal_pad_post
	local sep = config.options.styling.separator
	local close = config.options.styling.button.close
	local modified = config.options.styling.button.modified
	local button_bot = config.options.styling.button.below
	local button_pos = config.options.styling.button.pos
	local extra_len = #pad_pre + #pad_post + #close
	local sep_len = #sep
	local cwd = vim.uv.cwd() or vim.fn.getcwd()

	for i, buf in state.buf_iterator() do
		buf_name = vim.api.nvim_buf_get_name(buf)

		dir_name = vim.fs.dirname(buf_name)
		dir_name = vim.fs.relpath(cwd, dir_name) or ''
		if dir_name == '.' then dir_name = '' end
		dir_name = truncate_middle(dir_name, pref_len)
		dir_name = './' .. dir_name

		truncate_len = math.max(pref_len, #dir_name)
		file_name = vim.fs.basename(buf_name)

		if minimal then
			dir_name = file_name:match('^[^%.]+') or ''
			file_name = file_name:gsub('[^%.]+', '') or ''
		else
			file_name = truncate_end(file_name, truncate_len)
		end

		max_len = math.max(#dir_name, #file_name)

		file_name = extend_length(file_name, max_len)
		dir_name = extend_length(dir_name, max_len)

		state.register_buf_entry(buf, cur_len, max_len + extra_len, i)
		cur_len = cur_len + max_len + extra_len + sep_len

		if vim.bo[buf].modified then interact = modified
		else interact = close end

		table.insert(dir_table, pad_pre)
		table.insert(dir_table, dir_name)
		table.insert(dir_table, pad_post)
		table.insert(dir_table, interact)
		table.insert(dir_table, sep)

		table.insert(file_table, pad_pre)
		table.insert(file_table, file_name)
		table.insert(file_table, pad_post)
		table.insert(file_table, button_bot)
		table.insert(file_table, sep)
		state.register_button(buf, cur_len - sep_len - button_pos)
	end

	local dir_str = table.concat(dir_table)
	local file_str = table.concat(file_table)

	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {dir_str, file_str})
	vim.bo[buf_id].modifiable = false
	M.highlight()
end

return M
