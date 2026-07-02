---@class nvim-ideify.filetree
local M = {}

function M.get_config()
	return (require('nvim-ideify.filetree.config'))
end

function M.get_constants()
	return (require('nvim-ideify.filetree.constants'))
end

function M.get_keymaps()
	return (require('nvim-ideify.filetree.keymaps'))
end

function M.get_state()
	return (require('nvim-ideify.filetree.state'))
end

function M.get_ui()
	return (require('nvim-ideify.filetree.ui'))
end

vim.api.nvim_create_augroup('IDEifyFileTree', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = 'IDEifyFileTree',
	callback = function()
		local config = require('nvim-ideify.filetree.config')
		config.add_highlights()
	end
})

vim.api.nvim_create_autocmd('WinEnter', {
	group = 'IDEifyFileTree',
	callback = function()
		local g_state = require('nvim-ideify.state')
		local state = require('nvim-ideify.filetree.state')
		local config = require('nvim-ideify.filetree.config')
		if not config.options.do_cursorline then return end

		local cur_win = vim.api.nvim_get_current_win()
		local win = state.get_window()

		if cur_win == state.get_window() then
			g_state.guicursor = vim.o.guicursor
			vim.wo[win].cursorline = true
			vim.o.guicursor = 'a:IDEifyTreeNoCursor'
		else
			vim.o.guicursor = g_state.guicursor
			vim.wo[win].cursorline = false
		end
	end
})

return M
