---@type nvim-ideify.state
local M = {
	active = false,
	opened = false,
	equalalways = vim.o.equalalways,
	wins = {
		main = -1,
		last = -1,
	},
}

return M
