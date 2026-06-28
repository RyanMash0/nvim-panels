---@class nvim-ideify.terminal.config
local M = {}

M.defaults = {
	window = {
		number = false,
		winfixbuf = true,
	},
	buffer = {
		buflisted = false,
	},
	base_statusline = '[Terminal]',
	keymaps = {
		esc = '<S-Esc>',
		add = 'ba',
		delete = 'bd',
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

