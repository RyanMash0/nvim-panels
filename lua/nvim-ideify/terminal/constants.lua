local M = {}

---@type nvim-ideify.module.constants.config
M.config = {
	buffer = {
		listed = false,
		scratch = true,
	},
	window = {},
}

---@type nvim-ideify.ns_id
M.namespace = vim.api.nvim_create_namespace('IDEifyTerminal')

---@type 10
M.MAX_BUFFERS = 10

---@type nvim-ideify.terminal.statusline
M.statusline = {
	sep = ' %*|',
	hl = {
		selected = '%#IDEifyTerminalCurrent# ',
		normal = '%* ',
	},
}

return M
