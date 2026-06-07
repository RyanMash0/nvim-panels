local M = {}

M.defaults = {
	name_pref_length = 20,
	window = {
		start_opts = {
			style = 'minimal'
		},
		opts = {
			wrap = false,
			winfixbuf = true,
			statusline = '[Buffers]',
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			modifiable = false,
			buflisted = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	vim.defer_fn(function()
		local yank_hl_pre = vim.api.nvim_get_hl(0, { name = 'Green' })
		local yank_hl = {}
		for key, val in pairs(yank_hl_pre) do
			yank_hl[key] = val
		end
		yank_hl.reverse = true

		vim.api.nvim_set_hl(0, 'IDEifyBufferBarYank', yank_hl)
	end, 3000)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
