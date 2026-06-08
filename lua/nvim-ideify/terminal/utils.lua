local M = {}

local state = require('nvim-ideify.terminal.state')
local config = require('nvim-ideify.terminal.config')

function M.buffer_add()
	local ui = require('nvim-ideify.terminal.ui')
	local extra_buffers = state.extra_buffers
	if #extra_buffers >= 10 then return end
	local listed = config.options.buffer.listed
	local scratch = config.options.buffer.scratch
	local buf_opts = config.options.buffer.opts
	local new_buf = vim.api.nvim_create_buf(listed, scratch)

	for key, val in pairs(buf_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', buf = new_buf })
	end

	local idx = #extra_buffers + 1
	state.extra_buffers[idx] = new_buf
	state.extra_buffers_r[new_buf] = idx

	ui.render()
end

function M.buffer_delete()
	local ui = require('nvim-ideify.terminal.ui')
	local g_ui = require('nvim-ideify.ui')
	local extra_buffers = state.extra_buffers
	local extra_buffers_r = state.extra_buffers_r
	local buf = vim.api.nvim_win_get_buf(state.window)
	local num = extra_buffers_r[buf]

	if not num then return end

	vim.api.nvim_buf_delete(buf, { force = true })
	table.remove(extra_buffers, num)
	state.extra_buffers_r = {}
	for key, val in pairs(state.extra_buffers) do
		state.extra_buffers_r[val] = key
	end

	g_ui.reset()
	ui.render()
	vim.api.nvim_set_current_win(state.window)
end

function M.buffer_switch(num)
	if num < 1 or num > 10 then return end

	local ui = require('nvim-ideify.terminal.ui')
	local extra_buffers = state.extra_buffers
	local buf = extra_buffers[num]
	local win = state.window

	vim.wo[win].winfixbuf = false
	vim.api.nvim_win_set_buf(win, buf)
	vim.wo[win].winfixbuf = true

	ui.render()
end

return M
