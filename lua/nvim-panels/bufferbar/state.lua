local M = {}

local g_constants = require('nvim-panels.constants')

local buffer = g_constants.NOID
local window = g_constants.NOID
local on_click = nil

local buf_to_entry = {}
local pos_to_buf = {}
local button_to_buf = {}
local buf_to_button = {}
local yanked = nil

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
---@return nvim-panels.buf_id?
function M.get_yanked()
	return yanked
end

---
---@param buf? nvim-panels.buf_id
function M.set_yanked(buf)
	yanked = buf
end

---
---@param buf nvim-panels.buf_id
---@param col integer
function M.register_button(buf, col)
	buf_to_button[buf] = col
	button_to_buf[col] = buf
end

---
---@param buf nvim-panels.buf_id
---@param first integer
---@param len integer
---@param pos integer
function M.register_buf_entry(buf, first, len, pos)
	buf_to_entry[buf] = {
		first = first,
		last = first + len,
		position = pos
	}
end

---
---@param buf nvim-panels.buf_id
function M.register_new_buf(buf)
	if buf_to_entry[buf] then return end
	table.insert(pos_to_buf, buf)
	buf_to_entry[buf] = { position = M.get_num_bufs() }
end

---
---@param pos integer
function M.remove_buffer(pos)
	local buf = pos_to_buf[pos]
	table.remove(pos_to_buf, pos)
	buf_to_entry[buf] = nil
end

---
---@param buf? nvim-panels.buf_id
---@param pos? integer
function M.insert_buffer(buf, pos)
	if not buf then return end

	if not pos then
		table.insert(pos_to_buf, buf)
	else
		table.insert(pos_to_buf, pos, buf)
	end
end

---
local function buf_iterator(_, i)
	i = i + 1
	local buf = pos_to_buf[i]
	if not buf then return end

	return i, buf
end

---
---@param start_pos? integer
---@return nvim-panels.bufferbar.do_buf_iterator, nil, integer
function M.buf_iterator(start_pos)
	return buf_iterator, nil, (start_pos and start_pos - 1) or 0
end

---
---@return nvim-panels.do_generic_iterator, table<nvim-panels.buf_id, nvim-panels.bufferbar.entry>, nvim-panels.buf_id?
function M.buf_entries_iterator()
	return next, buf_to_entry, nil
end

---
---@param buf? nvim-panels.buf_id
---@return nvim-panels.bufferbar.entry?
function M.get_entry_by_buf(buf)
	return buf and buf_to_entry[buf] or nil
end

---
---@param pos? integer
---@return nvim-panels.buf_id?
function M.get_buf_by_pos(pos)
	return pos and pos_to_buf[pos] or nil
end

---
---@param col? integer
---@return nvim-panels.buf_id?
function M.get_buf_by_button(col)
	return col and button_to_buf[col] or nil
end

---
---@param buf? nvim-panels.buf_id
---@return integer?
function M.get_button_by_buf(buf)
	return buf and buf_to_button[buf] or nil
end

---
---@return integer
function M.get_num_bufs()
	return #pos_to_buf
end

---
function M.clear_buf_data()
	buf_to_entry = {}
	button_to_buf = {}
	buf_to_button = {}
end

return M
