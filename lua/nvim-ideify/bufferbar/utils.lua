local M = {}

local state = require('nvim-ideify.bufferbar.state')
local config = require('nvim-ideify.bufferbar.config')

function M.string_to_reg(str)
	return str:gsub('([\\\\%.%*%^%$%[%]])', '\\%1')
end

function M.get_sel_buffer()
	local win = state.get_window()
	local col = vim.api.nvim_win_get_cursor(win)[2]
	for key, val in state.buf_entries_iterator() do
		if val and col >= val.first and col <= val.last then
			return key
		end
	end
end

function M.buffer_yank()
	local ui = require('nvim-ideify.bufferbar.ui')
	local buf = M.get_sel_buffer()
	state.set_yanked(buf)

	vim.schedule(ui.render)
end

local function buffer_put_rel(offset)
	local ui = require('nvim-ideify.bufferbar.ui')
	local sel = M.get_sel_buffer()
	local yanked = state.get_yanked()
	if not yanked then return end

	local sel_info = state.get_entry_by_buf(sel)
	local sel_pos = sel_info and sel_info.position
	local yanked_info = state.get_entry_by_buf(yanked)
	local yanked_pos = yanked_info and yanked_info.position
	local before = yanked_pos < sel_pos and 1 or 0

	if sel == yanked then
		return
	end

	state.remove_buffer(yanked_pos)
	state.insert_buffer(yanked, sel_pos + offset - before)
	state.set_yanked(nil)

	vim.schedule(ui.render)
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
		local win = state.get_window()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		local minimal = config.options.minimal
		local new_pos
		local edge_pos
		local og_close = config.options.styling.button.close
		local close = config.options.regex.close
		local mod = config.options.regex.modified
		local min_pad_pre = config.options.regex.min_pad_pre
		local pad_pre = config.options.regex.pad_pre
		local sep = config.options.regex.separator
		local button_pos = #og_close - config.options.styling.button.pos
		local button_break = M.string_to_reg(og_close:sub(1,button_pos)):len()
		local close_expr = close:sub(1, button_break) .. [[\zs]] .. close:sub(button_break + 1)
		local mod_expr = mod:sub(1, button_break) .. [[\zs]] .. mod:sub(button_break + 1)
		local pre_pad_group = [[\(]] .. pad_pre .. [[\|]] .. min_pad_pre .. [[\)]]
		local button_reg = [[\(]] .. close_expr .. [[\|]] .. mod_expr .. [[\)]]
		local tab_start_reg = [[\(^]] .. pre_pad_group .. [[\zs.\|]] .. sep .. pre_pad_group .. [[\zs.\)]]

		if line == 1 and b then
			new_pos = vim.fn.searchpos(button_reg, flags, line)
			if new_pos[1] ~= 1 then return end
			edge_pos = vim.fn.searchpos(tab_start_reg, flags, line)

			edge_pos[2] = edge_pos[2] - 1
			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, edge_pos)
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 1 and not b then
			new_pos = vim.fn.searchpos(button_reg, flags, line)
			if new_pos[1] ~= 1 then return end

			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, { new_pos[1], new_pos[2] + 1 })
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 2 and b then
			new_pos = vim.fn.searchpos(tab_start_reg, flags, line)
			if new_pos[1] ~= 2 then return end

			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, { new_pos[1], new_pos[2] - (minimal and #min_pad_pre or #pad_pre) })
			vim.api.nvim_win_set_cursor(win, new_pos)
		elseif line == 2 and not b then
			new_pos = vim.fn.searchpos(tab_start_reg, flags, line)
			if new_pos[1] ~= 2 then return end
			edge_pos = vim.fn.searchpos(sep, flags, line)

			edge_pos[2] = edge_pos[2] - 1
			new_pos[2] = new_pos[2] - 1
			vim.api.nvim_win_set_cursor(win, edge_pos)
			vim.api.nvim_win_set_cursor(win, new_pos)
		end
	end
end

return M
