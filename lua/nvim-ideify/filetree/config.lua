local M = {}

M.defaults = {
	cache = true,
	show_keymaps = true,
	header = function () return nil end,
	keymaps = {
		' ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐',
		' ╎ Keymaps:                ╎',
		' ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤',
		' ╎ [M]ove, [R]ename,       ╎',
		' ╎ [C]opy, [D]elete,       ╎',
		' ╎                         ╎',
		' ╎ [N]ew [f]ile (Nf),      ╎',
		' ╎ [N]ew [d]irectory (Nd), ╎',
		' ╎                         ╎',
		' ╎ [m]ark [t]arget (mt),   ╎',
		' ╎ [m]ark [s]ource (ms),   ╎',
		' ╎ [<Esc>] to cancel mark, ╎',
		' ╎                         ╎',
		' ╎ [r]efresh, [c]lose all, ╎',
		' ╎ [t]oggle this menu      ╎',
		' └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘',
	},
	window = {
		start_opts = {},
		opts = {
			wrap = false,
			number = false,
			winfixbuf = true,
			statusline = '[Files]',
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			modifiable = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	vim.defer_fn(function()
		local target_hl_pre = vim.api.nvim_get_hl(0, { name = 'Green' })
		local source_hl_pre = vim.api.nvim_get_hl(0, { name = 'Grey' })
		local target_hl = {}
		local source_hl = {}
		for key, val in pairs(target_hl_pre) do
			target_hl[key] = val
		end
		for key, val in pairs(source_hl_pre) do
			source_hl[key] = val
		end
		target_hl.reverse = true
		source_hl.reverse = true
		target_hl.bold = true
		source_hl.bold = true

		vim.api.nvim_set_hl(0, 'IDEifyTreeTarget', target_hl)
		vim.api.nvim_set_hl(0, 'IDEifyTreeSource', source_hl)
	end, 3000)

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
