local M = {}

M.config = {
	window = {},
	buffer = {
		listed = false,
		scratch = true,
	},
}

M.namespace = vim.api.nvim_create_namespace('IDEifyFileTree')

---@enum nvim-ideify.filetree.trash_confirm
M.confirm = {
	N = 0,
	Y = 1,
	A = 2,
}

M.BASE_DEPTH = -1

return M
