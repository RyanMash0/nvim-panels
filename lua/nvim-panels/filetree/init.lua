---@class nvim-panels.filetree
local M = {}

function M.get_config()
	return (require('nvim-panels.filetree.config'))
end

function M.get_constants()
	return (require('nvim-panels.filetree.constants'))
end

function M.get_keymaps()
	return (require('nvim-panels.filetree.keymaps'))
end

function M.get_state()
	return (require('nvim-panels.filetree.state'))
end

function M.get_ui()
	return (require('nvim-panels.filetree.ui'))
end

vim.api.nvim_create_augroup('PanelsFileTree', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = 'PanelsFileTree',
	callback = function()
		local config = require('nvim-panels.filetree.config')
		config.add_highlights()
	end
})

vim.api.nvim_create_autocmd('WinEnter', {
	group = 'PanelsFileTree',
	callback = function()
		local g_state = require('nvim-panels.state')
		local g_utils = require('nvim-panels.utils')
		local state = require('nvim-panels.filetree.state')
		local config = require('nvim-panels.filetree.config')
		if not config.options.do_cursorline then return end

		local cur_win = vim.api.nvim_get_current_win()
		local win = state.get_window()

		if cur_win == win then
			g_state.guicursor = vim.o.guicursor
			vim.o.guicursor = 'a:PanelsTreeNoCursor'
			vim.wo[win].cursorline = true
			return
		end

		vim.o.guicursor = g_state.guicursor
		if g_utils.win_valid(win) then
			vim.wo[win].cursorline = false
		end
	end
})

return M
