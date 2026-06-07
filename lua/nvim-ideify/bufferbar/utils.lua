local M = {}

local state = require('nvim-ideify.bufferbar.state')

function M.get_sel_buffer()
	local win = state:get_window()
	local col = vim.api.nvim_win_get_cursor(win)[2]
	local buffer_info = state:get_buffer_info()
	for key, val in pairs(buffer_info) do
		if val and col >= val.first and col <= val.last then
			return key
		end
	end
end

function M.buffer_yank()
	local ui = require('nvim-ideify.bufferbar.ui')
	local buf = M.get_sel_buffer()
	state.yanked = buf
	ui.render()
end

local function buffer_put_rel(offset)
	local ui = require('nvim-ideify.bufferbar.ui')
	local sel = M.get_sel_buffer()
	local yanked = state.yanked
	if not state.yanked then return end

	local buffer_info = state.buffer_info
	local positions = state.buffer_order
	local sel_info = buffer_info[sel]
	local sel_pos = sel_info and sel_info.position
	local yanked_info = buffer_info[yanked]
	local yanked_pos = yanked_info and yanked_info.position
	local before = yanked_pos < sel_pos and 1 or 0

	if sel == state.yanked then
		return
	end

	table.remove(positions, yanked_pos)
	table.insert(positions, sel_pos + offset - before, yanked)
	state.yanked = nil

	ui.render()
end

function M.buffer_put_before()
	buffer_put_rel(0)
end

function M.buffer_put_after()
	buffer_put_rel(1)
end

function M.generate_buf_scroll(flags)
	return function()
		local win = state:get_window()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		if line == 1 then
			vim.fn.search([[\( \zs/\| \zs\./\|⎿\zsx\|⎿\zs+\)]], flags, line)
		else
			vim.fn.search([[\(^ \zs.\|⎹ \zs.\)]], flags, line)
		end
		--\|\zs⎺
	end
end

return M
