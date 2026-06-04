local M = {}
local state = require('nvim-ideify.filetree.state')
local ui = require('nvim-ideify.filetree.ui')
local utils = require('nvim-ideify.filetree.utils')

function M.setup()
	local opts = { buffer = state:get_buffer(), expr = true, remap = false }
	local action = vim.schedule_wrap(ui.action)
	local make = vim.schedule_wrap(ui.render)
	local descend = vim.schedule_wrap(ui.descend)
	local ascend = vim.schedule_wrap(ui.ascend)
	local close = vim.schedule_wrap(function()
		state.expanded = {}
		ui.render()
	end)
	-- local rename = vim.schedule_wrap(utils.file_rename)
	-- local delete = vim.schedule_wrap(utils.file_delete)
	-- local delete_v = vim.schedule_wrap(utils.file_delete_visual)
	-- local esc = vim.schedule_wrap(function()
	-- 	state.fs_target = {}
	-- 	state.fs_marked = {}
	-- 	ui.render()
	-- 	return '<Esc>'
	-- end)
	--
	-- vim.keymap.set('n', '<Esc>', esc, opts)
	-- vim.keymap.set('v', 'D', delete_v, opts)
	-- vim.keymap.set('n', 'D', delete, opts)
	-- vim.keymap.set('n', 'R', rename, opts)
	vim.keymap.set('n', 'c', close, opts)
	vim.keymap.set('n', 'r', make, opts)
	vim.keymap.set('n', '-', ascend, opts)
	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<S-CR>', descend, opts)
	vim.keymap.set('n', '<C-M>', action, opts)
	vim.keymap.set('n', '<S-C-M>', descend, opts)

	state:set_on_click(action)
end

return M
