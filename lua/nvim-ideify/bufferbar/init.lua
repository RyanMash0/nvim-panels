local M = {}

function M:get_ui()
	return require('nvim-ideify.bufferbar.ui')
end

function M:get_config()
	return require('nvim-ideify.bufferbar.config')
end

function M:get_state()
	return require('nvim-ideify.bufferbar.state')
end

function M:get_keymaps()
	return require('nvim-ideify.bufferbar.keymaps')
end

function M.buffer_next()
	local g_utils = require('nvim-ideify.utils')
	local g_state = require('nvim-ideify.state')
	local state = require('nvim-ideify.bufferbar.state')
	if not g_state.opened then
		local cmd = vim.api.nvim_replace_termcodes('<Cmd>', true, false, false)
		local cr = vim.api.nvim_replace_termcodes('<CR>', true, false, false)
		vim.api.nvim_feedkeys(cmd .. 'bn' .. cr, 'n', false)
	end

	local win = vim.api.nvim_get_current_win()
	if g_utils.is_plugin_win(win) then return end

	local cur_buf = vim.api.nvim_win_get_buf(win)
	local cur_buf_info = state.buffer_info[cur_buf]
	if not cur_buf_info then return end
	local new_pos = cur_buf_info.position + 1
	local num_bufs = #state.buffer_order
	new_pos = new_pos <= num_bufs and new_pos or 1
	local new_buf = state.buffer_order[new_pos]

	vim.api.nvim_win_set_buf(win, new_buf)
end

function M.buffer_previous()
	local g_utils = require('nvim-ideify.utils')
	local g_state = require('nvim-ideify.state')
	local state = require('nvim-ideify.bufferbar.state')
	if not g_state.opened then
		local cmd = vim.api.nvim_replace_termcodes('<Cmd>', true, false, false)
		local cr = vim.api.nvim_replace_termcodes('<CR>', true, false, false)
		vim.api.nvim_feedkeys(cmd .. 'bp' .. cr, 'n', false)
	end

	local win = vim.api.nvim_get_current_win()
	if g_utils.is_plugin_win(win) then return end

	local cur_buf = vim.api.nvim_win_get_buf(win)
	local cur_buf_info = state.buffer_info[cur_buf]
	if not cur_buf_info then return end
	local new_pos = cur_buf_info.position - 1
	local num_bufs = #state.buffer_order
	new_pos = new_pos >= 1 and new_pos or num_bufs
	local new_buf = state.buffer_order[new_pos]

	vim.api.nvim_win_set_buf(win, new_buf)
end

vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local g_utils = require('nvim-ideify.utils')
		local buf_info = state.buffer_info[args.buf]

		vim.defer_fn(function()
			if buf_info and buf_info.first and g_utils.win_valid(state:get_window()) then
				vim.api.nvim_win_set_cursor(state:get_window(), { 2, buf_info.last})
				vim.api.nvim_win_set_cursor(state:get_window(), { 2, buf_info.first})
				vim.api.nvim_win_set_cursor(state:get_window(), { 2, buf_info.first + 1})
			end

			M:get_ui().render()
		end, 10)
	end
})

vim.api.nvim_create_autocmd('BufModifiedSet', {
	group = 'IDEifyBufferBar',
	callback = function()
		vim.defer_fn(M:get_ui().render, 10)
	end
})

vim.api.nvim_create_autocmd({'BufAdd', 'BufNew'}, {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local buf = args.buf
		local position = #state.buffer_order + 1
		if not state.buffer_info[buf] and vim.bo[buf].buflisted then
			state.buffer_info[buf] = { position = position }
			state.buffer_order[position] =  buf
		end
	end,
})

vim.api.nvim_create_autocmd({'BufDelete'}, {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local buf = args.buf
		local buf_info = state.buffer_info[buf]
		local position
		if not buf_info then return end

		position = buf_info.position
		state.buffer_info[buf] = nil
		table.remove(state.buffer_order, position)
	end,
})

return M
