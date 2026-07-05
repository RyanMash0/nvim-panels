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
M.namespace = vim.api.nvim_create_namespace('PanelsFileTree')

---@enum nvim-panels.filetree.enum.trash_confirm
M.confirm = {
	N = 0,
	Y = 1,
	A = 2,
}

---@type -1
M.BASE_DEPTH = -1

---@type 'NONE'
M.NO_PATH = 'NONE'

return M
