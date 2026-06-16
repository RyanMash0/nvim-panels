local M = {}

local config = require('nvim-ideify.terminal.config')
local constants = require('nvim-ideify.terminal.constants')
local state = require('nvim-ideify.terminal.state')
local utils = require('nvim-ideify.terminal.utils')

function M.setup()
	local opts = { remap = false }
	local keys = config.options.keymaps

	local function generate_switch(num)
		return function() utils.buffer_switch(num) end
	end

	for _, buf in state.buf_iterator() do
		opts.buffer = buf

		vim.keymap.set('t', keys.esc, '<C-\\><C-n>', opts)
		vim.keymap.set('n', keys.add, utils.buffer_add, opts)
		vim.keymap.set('n', keys.delete, utils.buffer_delete, opts)

		for i = 1, constants.MAX_BUFFERS do
			pcall(vim.keymap.del,'n', tostring(i - 1), { buf = buf })
		end

		for i, _ in state.buf_iterator() do
			vim.keymap.set('n', tostring(i - 1), generate_switch(i), opts)
		end
	end
end

return M
