local M = {}

---@type nvim-panels.module.constants.config
M.config = {
	buffer = {
		listed = false,
		scratch = true,
	},
	window = {
		style = 'minimal'
	},
}

---@type nvim-panels.ns_id
M.namespace = vim.api.nvim_create_namespace('PanelsBufferBar')

---@enum nvim-panels.bufferbar.enum.scroll
M.scroll = {
	BACK = 'b',
	FORWARD = '',
}

return M
