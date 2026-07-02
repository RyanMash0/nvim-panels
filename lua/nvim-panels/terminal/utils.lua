local M = {}

local g_utils = require('nvim-panels.utils')
local g_constants = require('nvim-panels.constants')

local config = require('nvim-panels.terminal.config')
local constants = require('nvim-panels.terminal.constants')
local state = require('nvim-panels.terminal.state')

---
function M.buffer_add()
	local ui = require('nvim-panels.terminal.ui')
	local buf_conf = constants.config.buffer
	local buf_opts = config.options.buffer
	local buf = vim.api.nvim_create_buf(buf_conf.listed, buf_conf.scratch)
	g_utils.set_opts(g_constants.type.BUF, buf, buf_opts)

	state.register_buf(buf)

	vim.schedule(ui.render)
end

---
function M.buffer_delete()
	local g_ui = require('nvim-panels.ui')
	local ui = require('nvim-panels.terminal.ui')
	local buf = vim.api.nvim_win_get_buf(state.get_window())

	vim.api.nvim_buf_delete(buf, { force = true })
	state.remove_buf(buf)

	g_ui.show()
	ui.render()
	vim.api.nvim_set_current_win(state.get_window())
end

---
---@param pos integer
function M.buffer_switch(pos)
	local ui = require('nvim-panels.terminal.ui')
	local buf = state.get_buf_by_pos(pos)
	if not buf then return end
	local win = state.get_window()

	vim.wo[win].winfixbuf = false
	vim.api.nvim_win_set_buf(win, buf)
	vim.wo[win].winfixbuf = true

	vim.schedule(ui.render)
end

return M
