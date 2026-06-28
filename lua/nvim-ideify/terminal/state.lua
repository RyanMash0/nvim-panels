local M = {}

local g_constants = require('nvim-ideify.constants')

local constants = require('nvim-ideify.terminal.constants')

local buffer = g_constants.NOID
local window = g_constants.NOID
local on_click = nil

local pos_to_buf = {}
local buf_to_pos = {}

---
---@return nvim-ideify.buf_id
function M.get_buffer()
	return buffer
end

---
---@param buf_id nvim-ideify.buf_id
function M.set_buffer(buf_id)
	buffer = buf_id
	pos_to_buf = {}
	buf_to_pos = {}
end

---
---@return nvim-ideify.win_id
function M.get_window()
	return window
end

---
---@param win_id nvim-ideify.win_id
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
function M.clear_buf_list()
	pos_to_buf = {}
	buf_to_pos = {}
end

---
function M.register_main_buf()
	pos_to_buf[1] = buffer
	buf_to_pos[buffer] = 1
end

---
---@param buf_id nvim-ideify.buf_id
function M.register_buf(buf_id)
	local pos = #pos_to_buf + 1
	if pos > constants.MAX_BUFFERS then return end

	pos_to_buf[pos] = buf_id
	buf_to_pos[buf_id] = pos
end

---
---@param buf_id nvim-ideify.buf_id
function M.remove_buf(buf_id)
	local pos = buf_to_pos[buf_id]
	if not pos then return end

	table.remove(pos_to_buf, pos)
	buf_to_pos = {}
	for key, val in pairs(pos_to_buf) do
		buf_to_pos[val] = key
	end
end

---
---@param buf_id? nvim-ideify.buf_id
---@return integer?
function M.get_pos_by_buf(buf_id)
	return buf_id and buf_to_pos[buf_id] or nil
end

---
---@param pos? integer
---@return nvim-ideify.buf_id?
function M.get_buf_by_pos(pos)
	return pos and pos_to_buf[pos] or nil
end

---
local function iter(_, i)
	i = i + 1
	local buf = pos_to_buf[i]
	if not buf then return end

	return i, buf
end

---
---@param start_pos? integer
---@return nvim-ideify.terminal.do_buf_iterator, nil, integer
function M.buf_iterator(start_pos)
	return iter, nil, (start_pos and start_pos - 1) or 0
end

return M
