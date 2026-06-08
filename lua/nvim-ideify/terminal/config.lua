local M = {}

M.defaults = {
	base_statusline = '[Terminal]',
	window = {
		start_opts = {},
		opts = {
			number = false,
			relativenumber = false,
			winfixbuf = true,
			statusline = '[Terminal]',
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			buflisted = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

