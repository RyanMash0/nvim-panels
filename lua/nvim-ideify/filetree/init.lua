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

return M
