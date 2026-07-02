---@class nvim-panels.terminal
local M = {}

function M.get_config()
	return (require('nvim-panels.terminal.config'))
end

function M.get_constants()
	return (require('nvim-panels.terminal.constants'))
end

function M.get_keymaps()
	return (require('nvim-panels.terminal.keymaps'))
end

function M.get_state()
	return (require('nvim-panels.terminal.state'))
end

function M.get_ui()
	return (require('nvim-panels.terminal.ui'))
end

vim.api.nvim_create_augroup('PanelsTerminal', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = 'PanelsTerminal',
	callback = function()
		local g_utils = require('nvim-panels.utils')
		local config = require('nvim-panels.terminal.config')
		g_utils.get_term_bg(config.add_highlights)
	end
})

return M
