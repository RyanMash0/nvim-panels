local M = {}

local constants = require('nvim-ideify.terminal.constants')

local buffer = -1
local window = -1
local win_config = {}
local on_click = nil

local pos_to_buf = {}
local buf_to_pos = {}

function M.get_buffer()
	return buffer
end

function M.set_buffer(buf_id)
	buffer = buf_id
	pos_to_buf = {}
	buf_to_pos = {}
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

function M.clear_buf_list()
	pos_to_buf = {}
	buf_to_pos = {}
end

function M.register_main_buf()
	pos_to_buf[1] = buffer
	buf_to_pos[buffer] = 1
end

function M.register_buf(buf_id)
	local pos = #pos_to_buf + 1
	if pos > constants.MAX_BUFFERS then return end

	pos_to_buf[pos] = buf_id
	buf_to_pos[buf_id] = pos
end

function M.remove_buf(buf_id)
	local pos = buf_to_pos[buf_id]
	if not pos then return end

	table.remove(pos_to_buf, pos)
	buf_to_pos = {}
	for key, val in pairs(pos_to_buf) do
		buf_to_pos[val] = key
	end
end

function M.get_pos_by_buf(buf_id)
	return buf_to_pos[buf_id or -1]
end

function M.get_buf_by_pos(pos)
	return pos_to_buf[pos or -1]
end

local function iter(_, i)
	i = i + 1
	local buf = pos_to_buf[i]
	if not buf then return end

	return i, buf
end

function M.buf_iterator(start_pos)
	return iter, nil, (start_pos and start_pos - 1) or 0
end

return M
