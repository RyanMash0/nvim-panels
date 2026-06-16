local M = {}

---@enum nvim-ideify.position
M.position = {
	LEFT = 'left',
	RIGHT = 'right',
	TOP = 'top',
	BOTTOM = 'bottom',
}

---@enum nvim-ideify.split
M.split = {
	LEFT = 'left',
	RIGHT = 'right',
	ABOVE = 'above',
	BELOW = 'below',
}

---@enum nvim-ideify.type
M.type = {
	WIN = 'win',
	BUF = 'buf',
}

---@enum nvim-ideify.fs_err
M.fs_err = {
	NONE = 0,
	EXISTS = 1,
	NOENTRY = 2,
	NOTEMPTY = 3,
	OTHER = 4,
}

M.rel_trash_path = '/.local/share/Trash/nvim-ideify'

M.trash_path = vim.fs.joinpath(vim.uv.os_homedir(), M.rel_trash_path)

return M
