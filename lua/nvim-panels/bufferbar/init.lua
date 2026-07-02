---@class nvim-panels.bufferbar
local M = {}

local g_state = require('nvim-panels.state')

function M.get_config()
	return (require('nvim-panels.bufferbar.config'))
end

function M.get_constants()
	return (require('nvim-panels.bufferbar.constants'))
end

function M.get_keymaps()
	return (require('nvim-panels.bufferbar.keymaps'))
end

function M.get_state()
	return (require('nvim-panels.bufferbar.state'))
end

function M.get_ui()
	return (require('nvim-panels.bufferbar.ui'))
end

function M.buffer_next()
	local g_utils = require('nvim-panels.utils')
	local state = require('nvim-panels.bufferbar.state')
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
	local g_utils = require('nvim-panels.utils')
	local state = require('nvim-panels.bufferbar.state')
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

vim.api.nvim_create_augroup('PanelsBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'PanelsBufferBar',
	callback = function()
		if not g_state.active then return end
		local ui = require('nvim-panels.bufferbar.ui')
		vim.schedule(ui.render)
	end
})

vim.api.nvim_create_autocmd('BufModifiedSet', {
	group = 'PanelsBufferBar',
	callback = function()
		if not g_state.active then return end
		local ui = require('nvim-panels.bufferbar.ui')
		vim.schedule(ui.render)
	end
})

vim.api.nvim_create_autocmd({'BufAdd', 'BufNew'}, {
	group = 'PanelsBufferBar',
	callback = function(args)
		local state = require('nvim-panels.bufferbar.state')
		local buf = args.buf
		if vim.bo[buf].buflisted then
			state.register_new_buf(buf)
		end
	end,
})

vim.api.nvim_create_autocmd('BufDelete', {
	group = 'PanelsBufferBar',
	callback = function(args)
		local state = require('nvim-panels.bufferbar.state')
		local ui = require('nvim-panels.bufferbar.ui')
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
	group = 'PanelsBufferBar',
	callback = function()
		local g_utils = require('nvim-panels.utils')
		local config = require('nvim-panels.bufferbar.config')
		g_utils.get_term_bg(config.add_highlights)
	end
})

return M
