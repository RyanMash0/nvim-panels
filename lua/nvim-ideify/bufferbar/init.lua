---@class nvim-ideify.bufferbar
local M = {}

local g_state = require('nvim-ideify.state')

function M.get_config()
	return (require('nvim-ideify.bufferbar.config'))
end

function M.get_constants()
	return (require('nvim-ideify.bufferbar.constants'))
end

function M.get_keymaps()
	return (require('nvim-ideify.bufferbar.keymaps'))
end

function M.get_state()
	return (require('nvim-ideify.bufferbar.state'))
end

function M.get_ui()
	return (require('nvim-ideify.bufferbar.ui'))
end

function M.buffer_next()
	local g_utils = require('nvim-ideify.utils')
	local state = require('nvim-ideify.bufferbar.state')
	if not g_state.opened then
		vim.cmd('bnext')
		return
	end

	local win = vim.api.nvim_get_current_win()
	if g_utils.is_plugin_win(win) then return end

	local cur_buf = vim.api.nvim_win_get_buf(win)
	local cur_buf_entry = state.get_entry_by_buf(cur_buf)
	if not cur_buf_entry then
		vim.cmd('bnext')
		return
	end

	local new_pos = cur_buf_entry.position + 1
	local num_bufs = state.get_num_bufs()
	new_pos = new_pos <= num_bufs and new_pos or 1
	local new_buf = state.get_buf_by_pos(new_pos)
	if not new_buf then
		vim.cmd('bnext')
		return
	end

	vim.api.nvim_win_set_buf(win, new_buf)
end

function M.buffer_previous()
	local g_utils = require('nvim-ideify.utils')
	local state = require('nvim-ideify.bufferbar.state')
	if not g_state.opened then
		vim.cmd('bprevious')
		return
	end

	local win = vim.api.nvim_get_current_win()
	if g_utils.is_plugin_win(win) then return end

	local cur_buf = vim.api.nvim_win_get_buf(win)
	local cur_buf_entry = state.get_entry_by_buf(cur_buf)
	if not cur_buf_entry then
		vim.cmd('bprevious')
		return
	end

	local new_pos = cur_buf_entry.position - 1
	local num_bufs = state.get_num_bufs()
	new_pos = new_pos >= 1 and new_pos or num_bufs
	local new_buf = state.get_buf_by_pos(new_pos)
	if not new_buf then
		vim.cmd('bprevious')
		return
	end

	vim.api.nvim_win_set_buf(win, new_buf)
end

vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'IDEifyBufferBar',
	callback = function(args)
		if not g_state.active then return end
		local state = require('nvim-ideify.bufferbar.state')
		local ui = require('nvim-ideify.bufferbar.ui')
		local win = state.get_window()
		local g_utils = require('nvim-ideify.utils')
		local buf_entry = state.get_entry_by_buf(args.buf)

		vim.schedule(function()
			if buf_entry and buf_entry.first and g_utils.win_valid(win) then
				vim.api.nvim_win_set_cursor(win, { 2, buf_entry.last})
				vim.api.nvim_win_set_cursor(win, { 2, buf_entry.first})
				vim.api.nvim_win_set_cursor(win, { 1, buf_entry.first + 1})
			end

			ui.render()
		end)
	end
})

vim.api.nvim_create_autocmd('BufModifiedSet', {
	group = 'IDEifyBufferBar',
	callback = function()
		if not g_state.active then return end
		local ui = require('nvim-ideify.bufferbar.ui')
		vim.schedule(ui.render)
	end
})

vim.api.nvim_create_autocmd({'BufAdd', 'BufNew'}, {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local buf = args.buf
		if not state.get_entry_by_buf(buf) and vim.bo[buf].buflisted then
			state.register_new_buf(buf)
		end
	end,
})

vim.api.nvim_create_autocmd('BufDelete', {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local ui = require('nvim-ideify.bufferbar.ui')
		local buf = args.buf
		local buf_entry = state.get_entry_by_buf(buf)
		local position
		if not buf_entry then return end

		position = buf_entry.position
		state.remove_buffer(position)
		vim.schedule(ui.render)
	end,
})

vim.api.nvim_create_autocmd('ColorScheme', {
	group = 'IDEifyBufferBar',
	callback = function()
		local config = require('nvim-ideify.bufferbar.config')
		config.add_highlights()
	end
})

return M
