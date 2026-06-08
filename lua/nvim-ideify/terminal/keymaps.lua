local M = {}
local state = require('nvim-ideify.terminal.state')
local utils = require('nvim-ideify.terminal.utils')

function M.setup()
	local extra_buffers = state.extra_buffers
	local add = vim.schedule_wrap(utils.buffer_add)
	local delete = vim.schedule_wrap(utils.buffer_delete)
	local function generate_switch(num)
		return vim.schedule_wrap(function() utils.buffer_switch(num) end)
	end
	vim.schedule_wrap(utils.buffer_switch)
	for _, buf in pairs(extra_buffers) do
		vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = buf, remap = false })

		vim.keymap.set('n', 'ba', add, { buffer = buf, remap = false })
		vim.keymap.set('n', 'bd', delete, { buffer = buf, remap = false })

		for i = 1, 10 do
			pcall(vim.keymap.del,'n', tostring(i - 1), { buffer = buf })
		end

		for i = 1, #extra_buffers do
			vim.keymap.set('n', tostring(i - 1), generate_switch(i), { buffer = buf, remap = false })
		end
	end
end

return M
