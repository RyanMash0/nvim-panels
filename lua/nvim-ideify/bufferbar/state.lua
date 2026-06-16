local M = {}

local g_constants = require('nvim-ideify.constants')

local buffer = g_constants.NOID
local window = g_constants.NOID
local win_config = {}
local on_click = nil

local buf_to_entry = {}
local pos_to_buf = {}
local button_to_buf = {}
local buf_to_button = {}
local yanked = nil

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

function M.get_yanked()
	return yanked
end

function M.set_yanked(buf)
	yanked = buf
end

function M.register_button(buf, col)
	buf_to_button[buf] = col
	button_to_buf[col] = buf
end

function M.register_buf_entry(buf, first, len, pos)
	buf_to_entry[buf] = {
		first = first,
		last = first + len,
		position = pos
	}
end

function M.register_new_buf(buf)
	table.insert(pos_to_buf, buf)
	buf_to_entry[buf] = { position = M.get_num_bufs() }
end

function M.remove_buffer(pos)
	table.remove(pos_to_buf, pos)
end

function M.insert_buffer(buf, pos)
	if not buf then return end

	if not pos then
		table.insert(pos_to_buf, buf)
	else
		table.insert(pos_to_buf, pos, buf)
	end
end

local function buf_iterator(_, i)
	i = i + 1
	local buf = pos_to_buf[i]
	if not buf then return end

	return i, buf
end

function M.buf_iterator(start_pos)
	return buf_iterator, nil, (start_pos and start_pos - 1) or 0
end

function M.buf_entries_iterator()
	return next, buf_to_entry, nil
end

function M.get_entry_by_buf(buf)
	return buf_to_entry[buf or g_constants.NOID]
end

function M.get_buf_by_pos(pos)
	return pos_to_buf[pos or g_constants.NOID]
end

function M.get_buf_by_button(button)
	return button_to_buf[button or g_constants.NOID]
end

function M.get_button_by_buf(buf)
	return buf_to_button[buf or g_constants.NOID]
end

function M.get_num_bufs()
	return #pos_to_buf
end

function M.clear_buf_data()
	buf_to_entry = {}
	button_to_buf = {}
	buf_to_button = {}
end

return M
