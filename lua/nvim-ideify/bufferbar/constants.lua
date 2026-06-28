local M = {}

---@type nvim-ideify.module.constants.config
M.config = {
	buffer = {
		listed = false,
		scratch = true,
	},
	window = {
		style = 'minimal'
	},
}

---@type nvim-ideify.ns_id
M.namespace = vim.api.nvim_create_namespace('IDEifyBufferBar')

---@enum nvim-ideify.bufferbar.enum.scroll
M.scroll = {
	BACK = 'b',
	FORWARD = '',
}

return M
