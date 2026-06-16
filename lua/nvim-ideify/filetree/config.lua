local M = {}

M.defaults = {
	window = {
		wrap = false,
		number = false,
		winfixbuf = true,
		statusline = '[Files]',
	},
	buffer = {
		modifiable = false,
		buflisted = false,
	},
	show_keymaps = true,
	header = function() return nil end,
	keymaps_info = {
		' ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐',
		' ╎ Keymaps:                  ╎',
		' ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤',
		' ╎ [M]ove, [R]ename,         ╎',
		' ╎ [C]opy, [D]elete,         ╎',
		' ╎                           ╎',
		' ╎ [N]ew [f]ile (Nf),        ╎',
		' ╎ [N]ew [d]irectory (Nd),   ╎',
		' ╎                           ╎',
		' ╎ [m]ark [t]arget (mt),     ╎',
		' ╎ [m]ark [s]ource (ms),     ╎',
		' ╎ [<Esc>] to cancel mark,   ╎',
		' ╎                           ╎',
		' ╎ [G]o to directory,        ╎',
		' ╎                           ╎',
		' ╎ [r]efresh,                ╎',
		' ╎ [e]xpand [t]arget (et),   ╎',
		' ╎ [c]ollapse [t]arget (ct), ╎',
		' ╎ [c]ollpase [a]ll (ca),    ╎',
		' ╎                           ╎',
		' ╎ [t]oggle this menu        ╎',
		' └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘',
	},
	keymaps = {
		move = 'M',
		rename = 'R',
		copy = 'C',
		delete = 'D',
		new_file = 'Nf',
		new_dir = 'Nd',
		mark_target = 'mt',
		mark_source = 'ms',
		clear_marked = '<Esc>',
		go_to_dir = 'G',
		refresh = 'r',
		expand_target = 'et',
		close_target = 'ct',
		close_all = 'ca',
		toggle_keymaps = 't',
		ascend = '-',
		action = '<CR>',
		action_alt= '<C-M>',
		descend = '<S-CR>',
		descend_alt = '<S-C-M>',
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.add_highlights()
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
end

return M
