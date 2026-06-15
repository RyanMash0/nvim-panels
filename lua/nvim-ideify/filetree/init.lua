local M = {}

function M.get_config()
	return require('nvim-ideify.filetree.config')
end

function M.get_constants()
	return require('nvim-ideify.filetree.constants')
end

function M.get_keymaps()
	return require('nvim-ideify.filetree.keymaps')
end

function M.get_state()
	return require('nvim-ideify.filetree.state')
end

function M.get_ui()
	return require('nvim-ideify.filetree.ui')
end

vim.api.nvim_create_augroup('IDEifyFileTree', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = 'IDEifyFileTree',
	callback = function()
		local config = M.get_config()
		config.add_highlights()
	end
})

return M
