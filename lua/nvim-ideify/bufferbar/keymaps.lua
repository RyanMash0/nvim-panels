local M = {}

local config = require('nvim-ideify.bufferbar.config')
local state = require('nvim-ideify.bufferbar.state')
local ui = require('nvim-ideify.bufferbar.ui')
local utils = require('nvim-ideify.bufferbar.utils')

function M.setup()
	local opts = { buffer = state.get_buffer(), expr = true, remap = false }
	local action = vim.schedule_wrap(ui.action)
	local generate_buf_scroll = utils.generate_buf_scroll
	local buffer_yank = utils.buffer_yank
	local buffer_put_before = utils.buffer_put_before
	local buffer_put_after = utils.buffer_put_after
	local esc = function()
		state.set_yanked(nil)
		vim.schedule(ui.render)
	end
	local toggle = function()
		config.options.minimal = not config.options.minimal
		vim.schedule(ui.render)
	end

	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<C-M>', action, opts)

	opts.expr = nil
	vim.keymap.set('n', '<Esc>', esc, opts)
	vim.keymap.set('n', 'y', buffer_yank, opts)
	vim.keymap.set('n', 'p', buffer_put_after, opts)
	vim.keymap.set('n', 'P', buffer_put_before, opts)
	vim.keymap.set('n', 'm', toggle, opts)
	vim.keymap.set('n', 'w', generate_buf_scroll(''), opts)
	vim.keymap.set('n', 'b', generate_buf_scroll('b'), opts)
	vim.keymap.set('n', '<S-ScrollWheelUp>', generate_buf_scroll('b'), opts)
	vim.keymap.set('n', '<S-ScrollWheelDown>', generate_buf_scroll(''), opts)

	state.set_on_click(action)
end

return M
