local M = {}
local state = require('nvim-ideify.filetree.state')
local config = require('nvim-ideify.filetree.config')
local ui = require('nvim-ideify.filetree.ui')
local utils = require('nvim-ideify.filetree.utils')

function M.setup()
	local opts = { buffer = state:get_buffer(), expr = false, remap = false, }
	local action = vim.schedule_wrap(ui.action)
	local make = vim.schedule_wrap(ui.render)
	local descend = vim.schedule_wrap(ui.descend)
	local ascend = vim.schedule_wrap(ui.ascend)
	local close = vim.schedule_wrap(function()
		state.expanded = {}
		ui.render()
	end)
	local rename = vim.schedule_wrap(utils.file_rename)
	local delete = vim.schedule_wrap(utils.file_delete)
	local delete_v = vim.schedule_wrap(utils.file_delete_visual)
	local esc = vim.schedule_wrap(function()
		state.fs_target = {}
		state.fs_sources = {}
		ui.render()
		return '<Esc>'
	end)
	local toggle = vim.schedule_wrap(function()
		config.options.show_keymaps = not config.options.show_keymaps
		ui.render()
	end)
	local target = vim.schedule_wrap(utils.mark_target)
	local source = vim.schedule_wrap(utils.mark_source)
	local move = vim.schedule_wrap(utils.file_move)
	local copy = vim.schedule_wrap(utils.file_copy)

	vim.keymap.set('n', 'mt', target, opts)
	vim.keymap.set('n', 'ms', source, opts)
	vim.keymap.set('n', '<Esc>', esc, opts)
	vim.keymap.set('n', 'C', copy, opts)
	vim.keymap.set('n', 'M', move, opts)
	vim.keymap.set('v', 'D', delete_v, opts)
	vim.keymap.set('n', 'D', delete, opts)
	vim.keymap.set('n', 'R', rename, opts)
	vim.keymap.set('n', 'c', close, opts)
	vim.keymap.set('n', 'r', make, opts)
	vim.keymap.set('n', 't', toggle, opts)
	vim.keymap.set('n', '-', ascend, opts)
	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<S-CR>', descend, opts)
	vim.keymap.set('n', '<C-M>', action, opts)
	vim.keymap.set('n', '<S-C-M>', descend, opts)

	state:set_on_click(action)
end

return M
