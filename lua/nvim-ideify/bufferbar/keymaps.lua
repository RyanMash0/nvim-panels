local M = {}
local state = require('nvim-ideify.bufferbar.state')
local ui = require('nvim-ideify.bufferbar.ui')
local utils = require('nvim-ideify.bufferbar.utils')

function M.setup()
	local opts = { buffer = state.buffer, expr = true, remap = false }
	local action = vim.schedule_wrap(ui.action)
	local generate_buf_scroll = utils.generate_buf_scroll
	local buffer_yank = vim.schedule_wrap(utils.buffer_yank)
	local buffer_put_before = vim.schedule_wrap(utils.buffer_put_before)
	local buffer_put_after = vim.schedule_wrap(utils.buffer_put_after)
	local esc = vim.schedule_wrap(function()
		state.yanked = nil
		ui.render()
	end)

	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<C-M>', action, opts)

	opts.expr = nil
	vim.keymap.set('n', '<Esc>', esc, opts)
	vim.keymap.set('n', 'y', buffer_yank, opts)
	vim.keymap.set('n', 'p', buffer_put_after, opts)
	vim.keymap.set('n', 'P', buffer_put_before, opts)
	vim.keymap.set('n', 'w', generate_buf_scroll(''), opts)
	vim.keymap.set('n', 'b', generate_buf_scroll('b'), opts)
	vim.keymap.set('n', '<S-ScrollWheelUp>', generate_buf_scroll('b'), opts)
	vim.keymap.set('n', '<S-ScrollWheelDown>', generate_buf_scroll(''), opts)

	state:set_on_click(action)
end

return M
