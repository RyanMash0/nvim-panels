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
M.namespace = vim.api.nvim_create_namespace('IDEifyFileTree')

---@enum nvim-ideify.filetree.trash_confirm
M.confirm = {
	N = 0,
	Y = 1,
	A = 2,
}

---@type -1
M.BASE_DEPTH = -1

return M
