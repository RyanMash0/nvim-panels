local M = {}

local config = require('nvim-panels.filetree.config')
local fs_operations = require('nvim-panels.filetree.fs_operations')
local state = require('nvim-panels.filetree.state')
local ui = require('nvim-panels.filetree.ui')
local utils = require('nvim-panels.filetree.utils')

function M.setup()
	local opts = { buffer = state.get_buffer(), expr = false, remap = false, }
	local keys = config.options.keymaps

	local move = fs_operations.move
	local rename = fs_operations.rename
	local copy = fs_operations.copy
	local delete = fs_operations.delete
	local new_file = fs_operations.new_file
	local new_dir = fs_operations.new_dir
	local target = utils.mark_target
	local source = utils.mark_source
	local clear = function()
		state.clear_marked()
		vim.schedule(ui.render)
	end
	local go_to_dir = utils.go_to_dir
	local refresh = vim.schedule_wrap(ui.render)
	local expand_target = utils.open_subdirectories
	local close_target = utils.close_subdirectories
	local close_all = function()
		for path in state.expanded_iterator() do
			utils.unmark_subdirectories(path)
		end
		state.clear_expanded()
		vim.schedule(ui.render)
	end
	local toggle_keymaps = function()
		config.options.show_keymaps = not config.options.show_keymaps
		vim.schedule(ui.render)
	end
	local ascend = vim.schedule_wrap(ui.ascend)
	local action = vim.schedule_wrap(ui.action)
	local descend = vim.schedule_wrap(ui.descend)

	vim.keymap.set('n', keys.move, move, opts)
	vim.keymap.set('n', keys.rename, rename, opts)
	vim.keymap.set('n', keys.copy, copy, opts)
	vim.keymap.set('n', keys.delete, delete, opts)
	vim.keymap.set('n', keys.new_file, new_file, opts)
	vim.keymap.set('n', keys.new_dir, new_dir, opts)
	vim.keymap.set('n', keys.mark_target, target, opts)
	vim.keymap.set('n', keys.mark_source, source, opts)
	vim.keymap.set('n', keys.clear_marked, clear, opts)
	vim.keymap.set('n', keys.go_to_dir, go_to_dir, opts)
	vim.keymap.set('n', keys.refresh, refresh, opts)
	vim.keymap.set('n', keys.expand_target, expand_target, opts)
	vim.keymap.set('n', keys.close_target, close_target, opts)
	vim.keymap.set('n', keys.close_all, close_all, opts)
	vim.keymap.set('n', keys.toggle_keymaps, toggle_keymaps, opts)
	vim.keymap.set('n', keys.ascend, ascend, opts)
	vim.keymap.set('n', keys.action, action, opts)
	vim.keymap.set('n', keys.action_alt, action, opts)
	vim.keymap.set('n', keys.descend, descend, opts)
	vim.keymap.set('n', keys.descend_alt, descend, opts)

	state.set_on_click(action)
end

return M
