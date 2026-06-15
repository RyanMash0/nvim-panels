local M = {}

M.defaults = {
	base_statusline = '[Terminal]',
	window = {
		number = false,
		winfixbuf = true,
	},
	buffer = {
		buflisted = false,
	},
	keymaps = {
		add = 'ba',
		delete = 'bd',
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

