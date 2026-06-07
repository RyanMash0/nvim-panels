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

	local buf_info = state.buffer_info
	local buf_order = state.buffer_order
	local sel_info = buf_info[sel]
	local sel_pos = sel_info and sel_info.position
	local yanked_info = buf_info[yanked]
	local yanked_pos = yanked_info and yanked_info.position
	local before = yanked_pos < sel_pos and 1 or 0

	if sel == state.yanked then
		return
	end

	table.remove(buf_order, yanked_pos)
	table.insert(buf_order, sel_pos + offset - before, yanked)
	state.yanked = nil

	ui.render()
end

function M.buffer_put_before()
	buffer_put_rel(0)
end

function M.buffer_put_after()
	buffer_put_rel(1)
end

function M.generate_buf_scroll(back)
	return function()
		local b = back == 'b'
		local flags = 'W' .. back
		local win = state:get_window()
		local line = vim.api.nvim_win_get_cursor(win)[1]

		if line == 1 and b then
			local new_pos = vim.fn.searchpos([[⎿\zs.⏌]], flags, line)
			if new_pos[1] ~= 1 then return end
			local edge_pos = vim.fn.searchpos([[\(^ \zs.\|⏌ \zs.\)]], flags, line)

			edge_pos[2] = edge_pos[2] - 1
			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, edge_pos)
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 1 and not b then
			local new_pos = vim.fn.searchpos([[⎿\zs.⏌]], flags, line)
			if new_pos[1] ~= 1 then return end

			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, { new_pos[1], new_pos[2] + 1 })
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 2 and b then
			local new_pos = vim.fn.searchpos([[\(^ \zs.\|⎹ \zs.\)]], flags, line)
			if new_pos[1] ~= 2 then return end

			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, { new_pos[1], new_pos[2] - 1 })
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 2 and not b then
			local new_pos = vim.fn.searchpos([[\(^ \zs.\|⎹ \zs.\)]], flags, line)
			if new_pos[1] ~= 2 then return end
			local edge_pos = vim.fn.searchpos([[⎹]], flags, line)

			edge_pos[2] = edge_pos[2] - 1
			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, edge_pos)
			vim.api.nvim_win_set_cursor(win, new_pos)
		end
	end
end

return M
