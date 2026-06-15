local M = {}
local state = require('nvim-ideify.terminal.state')
local utils = require('nvim-ideify.terminal.utils')
local constants = require('nvim-ideify.terminal.constants')
local config = require('nvim-ideify.terminal.config')

function M.setup()
	local function generate_switch(num)
		return function() utils.buffer_switch(num) end
	end

	local add = config.options.keymaps.add
	local delete = config.options.keymaps.delete

	local opts = { remap = false }

	for _, buf in state.buf_iterator() do
		opts.buffer = buf
		vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts)

		vim.keymap.set('n', add, utils.buffer_add, opts)
		vim.keymap.set('n', delete, utils.buffer_delete, opts)

		for i = 1, constants.MAX_BUFFERS do
			pcall(vim.keymap.del,'n', tostring(i - 1), { buf = buf })
		end

		for i, _ in state.buf_iterator() do
			vim.keymap.set('n', tostring(i - 1), generate_switch(i), opts)
		end
	end
end

return M
