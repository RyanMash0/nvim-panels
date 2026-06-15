local M = {}

local state = require('nvim-ideify.terminal.state')
local config = require('nvim-ideify.terminal.config')
local constants = require('nvim-ideify.terminal.constants')
local g_utils = require('nvim-ideify.utils')

function M.buffer_add()
	local ui = require('nvim-ideify.terminal.ui')
	local buf_conf = constants.config.buffer
	local buf_opts = config.options.buffer
	local buf = g_utils.create_buf_with_opts(buf_conf, buf_opts)

	state.register_buf(buf)

	vim.schedule(ui.render)
end

function M.buffer_delete()
	local ui = require('nvim-ideify.terminal.ui')
	local g_ui = require('nvim-ideify.ui')
	local buf = vim.api.nvim_win_get_buf(state.get_window())

	vim.api.nvim_buf_delete(buf, { force = true })
	state.remove_buf(buf)

	g_ui.reset()
	vim.api.nvim_set_current_win(state.get_window())

	vim.schedule(ui.render)
end

function M.buffer_switch(pos)
	local ui = require('nvim-ideify.terminal.ui')
	local buf = state.get_buf_by_pos(pos)
	local win = state.get_window()

	vim.wo[win].winfixbuf = false
	vim.api.nvim_win_set_buf(win, buf)
	vim.wo[win].winfixbuf = true

	vim.schedule(ui.render)
end

return M
