---@class nvim-panels.state
local M = {}

local constants = require('nvim-panels.constants')

M.active = false
M.opened = false
M.equalalways = vim.o.equalalways
M.wins = {
	main = constants.NOID,
	last = constants.NOID,
}
M.editor_wins = {}
M.height_ratio = 1
M.width_ratio = 1
M.guicursor = vim.o.guicursor


return M
