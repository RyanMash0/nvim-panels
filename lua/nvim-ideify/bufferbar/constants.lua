local M = {}

M.config = {
	window = {
		style = 'minimal'
	},
	buffer = {
		listed = false,
		scratch = true,
	},
}

M.namespace = vim.api.nvim_create_namespace('IDEifyBufferBar')

return M
