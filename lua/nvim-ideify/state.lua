---@class nvim-ideify.state
local M = {}

local constants = require('nvim-ideify.constants')

M.active = false
M.opened = false
M.equalalways = vim.o.equalalways
M.wins = {
	main = constants.NOID,
	last = constants.NOID,
}

return M
