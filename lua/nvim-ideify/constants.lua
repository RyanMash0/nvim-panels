---@class nvim-ideify.constants
local M = {}

---@enum nvim-ideify.enum.position
M.position = {
	LEFT = 'left',
	RIGHT = 'right',
	TOP = 'top',
	BOTTOM = 'bottom',
}

---@enum nvim-ideify.enum.split
M.split = {
	LEFT = 'left',
	RIGHT = 'right',
	ABOVE = 'above',
	BELOW = 'below',
}

---@enum nvim-ideify.enum.type
M.type = {
	BUF = 'buf',
	WIN = 'win',
}

---@enum nvim-ideify.enum.fs_err
M.fs_err = {
	NONE = 0,
	EXISTS = 1,
	NOENTRY = 2,
	NOTEMPTY = 3,
	OTHER = 4,
}

---@enum nvim-ideify.enum.fs_type
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

---@enum nvim-ideify.winlayout.type
M.winlayout_type = {
	ROW = 'row',
	COL = 'col',
	LEAF = 'leaf',
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
