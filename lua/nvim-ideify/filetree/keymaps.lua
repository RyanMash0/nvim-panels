local M = {}
local state = require('nvim-ideify.filetree.state')
local config = require('nvim-ideify.filetree.config')
local ui = require('nvim-ideify.filetree.ui')
local utils = require('nvim-ideify.filetree.utils')
local fs_operations = require('nvim-ideify.filetree.fs_operations')

function M.setup()
	local opts = { buffer = state.get_buffer(), expr = false, remap = false, }
	local action = vim.schedule_wrap(ui.action)
	local make = vim.schedule_wrap(ui.render)
	local descend = vim.schedule_wrap(ui.descend)
	local ascend = vim.schedule_wrap(ui.ascend)
	local close = function()
		for path in state.expanded_iterator() do
			utils.unmark_subdirectories(path)
		end
		state.clear_expanded()
		vim.schedule(ui.render)
	end
	local rename = fs_operations.rename
	local delete = fs_operations.delete
	local esc = function()
		state.clear_marked()
		vim.schedule(ui.render)
	end
	local toggle = function()
		config.options.show_keymaps = not config.options.show_keymaps
		vim.schedule(ui.render)
	end
	local target = utils.mark_target
	local source = utils.mark_source
	local move = fs_operations.move
	local copy = fs_operations.copy
	local file_new = fs_operations.file_new
	local dir_new = fs_operations.dir_new
	local expand_level = utils.open_subdirectories
	local close_level = utils.close_subdirectories
	local change_dir = utils.go_to_dir

	vim.keymap.set('n', 'G', change_dir, opts)
	vim.keymap.set('n', 'mt', target, opts)
	vim.keymap.set('n', 'ms', source, opts)
	vim.keymap.set('n', '<Esc>', esc, opts)
	vim.keymap.set('n', 'C', copy, opts)
	vim.keymap.set('n', 'Nd', dir_new, opts)
	vim.keymap.set('n', 'Nf', file_new, opts)
	vim.keymap.set('n', 'M', move, opts)
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

	state.set_on_click(action)
end

return M
