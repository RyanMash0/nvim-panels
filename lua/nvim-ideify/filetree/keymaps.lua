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
		for path, _ in pairs(state.expanded) do
			utils.unmark_subdirectories(path)
		end
		state.expanded = {}
		ui.render()
	end)
	local rename = vim.schedule_wrap(utils.fs_rename)
	local delete = vim.schedule_wrap(utils.fs_delete)
	local delete_v = vim.schedule_wrap(utils.fs_delete_visual)
	local esc = vim.schedule_wrap(function()
		state.fs_target = {}
		state.fs_sources = {}
		ui.render()
	end)
	local toggle = vim.schedule_wrap(function()
		config.options.show_keymaps = not config.options.show_keymaps
		ui.render()
	end)
	local target = vim.schedule_wrap(utils.mark_target)
	local source = vim.schedule_wrap(utils.mark_source)
	local move = vim.schedule_wrap(utils.fs_move)
	local copy = vim.schedule_wrap(utils.fs_copy)
	local file_new = vim.schedule_wrap(utils.file_new)
	local dir_new = vim.schedule_wrap(utils.dir_new)
	local expand_level = vim.schedule_wrap(utils.open_subdirectories)
	local close_level = vim.schedule_wrap(utils.close_subdirectories)
	local change_dir = vim.schedule_wrap(utils.go_to_dir)

	vim.keymap.set('n', 'G', change_dir, opts)
	vim.keymap.set('n', 'mt', target, opts)
	vim.keymap.set('n', 'ms', source, opts)
	vim.keymap.set('n', '<Esc>', esc, opts)
	vim.keymap.set('n', 'C', copy, opts)
	vim.keymap.set('n', 'Nd', dir_new, opts)
	vim.keymap.set('n', 'Nf', file_new, opts)
	vim.keymap.set('n', 'M', move, opts)
	vim.keymap.set('v', 'D', delete_v, opts)
	vim.keymap.set('n', 'D', delete, opts)
	vim.keymap.set('n', 'R', rename, opts)
	vim.keymap.set('n', 'ca', close, opts)
	vim.keymap.set('n', 'ct', close_level, opts)
	vim.keymap.set('n', 'et', expand_level, opts)
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
