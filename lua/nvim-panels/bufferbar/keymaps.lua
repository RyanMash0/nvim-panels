local M = {}

local config = require('nvim-panels.bufferbar.config')
local constants = require('nvim-panels.bufferbar.constants')
local state = require('nvim-panels.bufferbar.state')
local ui = require('nvim-panels.bufferbar.ui')
local utils = require('nvim-panels.bufferbar.utils')

function M.setup()
	local opts = { buffer = state.get_buffer(), remap = false }
	local keys = config.options.keymaps
	local f = constants.scroll.FORWARD
	local b = constants.scroll.BACK

	local action = vim.schedule_wrap(ui.action)
	local clear_yanked = function()
		state.set_yanked(nil)
		vim.schedule(ui.render)
	end
	local buffer_yank = utils.buffer_yank
	local buffer_put_after = utils.buffer_put_after
	local buffer_put_before = utils.buffer_put_before
	local toggle_minimal = function()
		config.options.minimal = not config.options.minimal
		vim.schedule(ui.render)
	end
	local generate_buf_scroll = utils.generate_buf_scroll

	vim.keymap.set('n', keys.action, action, opts)
	vim.keymap.set('n', keys.action_alt, action, opts)
	vim.keymap.set('n', keys.clear_yanked, clear_yanked, opts)
	vim.keymap.set('n', keys.yank, buffer_yank, opts)
	vim.keymap.set('n', keys.put_after, buffer_put_after, opts)
	vim.keymap.set('n', keys.put_before, buffer_put_before, opts)
	vim.keymap.set('n', keys.toggle_minimal, toggle_minimal, opts)
	vim.keymap.set('n', keys.scroll_right, generate_buf_scroll(f), opts)
	vim.keymap.set('n', keys.scroll_left, generate_buf_scroll(b), opts)
	vim.keymap.set('n', keys.mouse_scroll_left, generate_buf_scroll(f), opts)
	vim.keymap.set('n', keys.mouse_scroll_right, generate_buf_scroll(b), opts)

	state.set_on_click(action)
end

return M
