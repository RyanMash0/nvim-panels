local M = {}

M.config = {
	window = {},
	buffer = {
		listed = false,
		scratch = true,
	},
}

M.namespace = vim.api.nvim_create_namespace('IDEifyTerminal')

M.MAX_BUFFERS = 10

M.statusline = {
	sep = ' %#Statusline#|',
	hl = {
		selected = '%#TabLineSel# ',
		normal = '%#StatusLine# ',
	},
}

return M
