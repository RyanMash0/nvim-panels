local M = {}
local state = require('nvim-ideify.bufferbar.state')
local ui = require('nvim-ideify.bufferbar.ui')

function M.setup()
	local opts = { buffer = state:get_buffer(), expr = true, remap = false }
	local action = vim.schedule_wrap(ui.action)

	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<C-M>', action, opts)

	state:set_on_click(action)

	local function generate_buf_scroll(flags)
		return function()
			local win = state:get_window()
			local line = vim.api.nvim_win_get_cursor(win)[1]
			if line == 1 then
				vim.fn.search([[\( \zs/\| \zs\./\|⎿\zsx\|⎿\zs+\)]], flags, line)
				else
				vim.fn.search([[\(^ \zs.\|⎹ \zs.\)]], flags, line)
				end
			--\|\zs⎺
		end
	end

	opts.expr = nil
	vim.keymap.set('n', 'w', generate_buf_scroll('W'), opts)
	vim.keymap.set('n', 'b', generate_buf_scroll('Wb'), opts)

	vim.keymap.set('n', '<S-ScrollWheelUp>', generate_buf_scroll('Wb'), opts)
	vim.keymap.set('n', '<S-ScrollWheelDown>', generate_buf_scroll('W'), opts)
end

return M
