---@class nvim-panels.filetree.config
local M = {}

M.defaults = {
	window = {
		wrap = false,
		number = false,
		winfixbuf = true,
		statusline = '[Files]',
		winhighlight = 'CursorLine:PanelsTreeCursorLine',
	},
	buffer = {
		modifiable = false,
		buflisted = false,
	},
	do_cursorline = true,
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
	local target_pre = vim.api.nvim_get_hl(
		0, { name = 'Directory', link = false }
	)
	local target = {}
	for key, val in pairs(target_pre) do
		target[key] = val
	end
	target.bold = true
	target.reverse = true

	local source_pre = vim.api.nvim_get_hl(
		0, { name = 'netrwComment', link = false }
	)
	local source = {}
	for key, val in pairs(source_pre) do
		source[key] = val
	end
	source.bold = true
	source.reverse = true

	vim.api.nvim_set_hl(0, 'PanelsTreeDir', { link = 'Directory' })
	vim.api.nvim_set_hl(0, 'PanelsTreeBar', { link = 'Special' })
	vim.api.nvim_set_hl(0, 'PanelsTreePlain', { link = 'netrwPlain' })
	vim.api.nvim_set_hl(0, 'PanelsTreeHeader', { link = 'netrwComment' })
	vim.api.nvim_set_hl(0, 'PanelsTreeTarget', target)
	vim.api.nvim_set_hl(0, 'PanelsTreeSource', source)
	vim.api.nvim_set_hl(0, 'PanelsTreeCursorLine', { link = 'CursorLine' })
	vim.api.nvim_set_hl(
		0, 'PanelsTreeNoCursor', { blend = 100, nocombine = true }
	)
end

return M
