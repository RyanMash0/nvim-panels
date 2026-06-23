---@class nvim-ideify.constants
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

---@enum nvim-ideify.fs_type
M.fs_type = {
	HEADER = 'header',
	FILE = 'file',
	DIRECTORY = 'directory',
	LINK = 'link',
	FIFO = 'other',
	SOCKET = 'socket',
	CHAR = 'char',
	BLOCK = 'block',
	UNKNOWN = 'unknown',
}

---@type table<nvim-ideify.buf_id, boolean>
M.ui2_buffers = {
	[2] = true,
	[3] = true,
	[4] = true,
	[5] = true,
}

---@type nvim-ideify.invalid_id
M.NOID = -1

return M
