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

function M.add_highlights(bg)
	local normal = vim.api.nvim_get_hl(
		0, { name = 'Normal', link = false }
	)
	local current_pre = vim.api.nvim_get_hl(
		0, { name = 'PmenuSel', link = false }
	)
	local current = {}
	current.fg = normal.bg or bg
	current.ctermfg = normal.ctermbg or bg
	current.bg = current_pre.bg or normal.fg
	current.ctermbg = current_pre.ctermbg or normal.ctermfg

	vim.api.nvim_set_hl(0, 'IDEifyTerminalCurrent', current)
end

return M

