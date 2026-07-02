local M = {}

---@type nvim-panels.module.constants.config
M.config = {
	buffer = {
		listed = false,
		scratch = true,
	},
	window = {},
}

---@type nvim-panels.ns_id
M.namespace = vim.api.nvim_create_namespace('PanelsTerminal')

---@type 10
M.MAX_BUFFERS = 10

---@type nvim-panels.terminal.statusline
M.statusline = {
	sep = ' %*|',
	hl = {
		selected = '%#PanelsTerminalCurrent# ',
		normal = '%* ',
	},
}

return M
