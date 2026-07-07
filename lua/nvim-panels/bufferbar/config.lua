---@class nvim-panels.bufferbar.config
local M = {}

M.defaults = {
	window = {
		wrap = false,
		winfixbuf = true,
		statusline = '[Buffers]',
	},
	buffer = {
		modifiable = false,
		buflisted = false,
	},
	name_pref_length = 20,
	minimal = false,
	styling = {
		separator = '│',
		button = {
			close = ' 󰖭 ',
			modified = ' \u{00A0}',
			below = ' \u{2800}\u{00A0}',
			pos = 5,
		},
		padding = {
			normal = {
				before = 1,
				after = 0,
			},
			minimal = {
				before = 0,
				after = 0,
			}
		},
	},
	keymaps = {
		action = '<CR>',
		action_alt = '<C-M>',
		clear_yanked = '<Esc>',
		yank = 'y',
		put_after = 'p',
		put_before = 'P',
		toggle_minimal = 'm',
		scroll_right = 'w',
		scroll_left = 'b',
		mouse_scroll_right = '<S-ScrollWheelUp>',
		mouse_scroll_left = '<S-ScrollWheelDown>',
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	local g_utils = require('nvim-panels.utils')
	local utils = require('nvim-panels.bufferbar.utils')

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})

	M.options.styling.padding.normal.before_str = string.rep(
		' ', M.options.styling.padding.normal.before
	)
	M.options.styling.padding.normal.after_str = string.rep(
		' ', M.options.styling.padding.normal.after
	)
	M.options.styling.padding.minimal.before_str = string.rep(
		' ', M.options.styling.padding.minimal.before
	)
	M.options.styling.padding.minimal.after_str = string.rep(
		' ', M.options.styling.padding.minimal.after
	)

	M.options.regex = {
		close = utils.string_to_reg(M.options.styling.button.close),
		modified = utils.string_to_reg(M.options.styling.button.modified),
		pad_pre = utils.string_to_reg(M.options.styling.padding.normal.before_str),
		min_pad_pre = utils.string_to_reg(M.options.styling.padding.minimal.before_str),
		separator = utils.string_to_reg(M.options.styling.separator),
	}

	g_utils.get_term_bg(M.add_highlights)
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

	local yank_pre = vim.api.nvim_get_hl(
		0, { name = 'DiagnosticOk', link = false }
	)
	local yank = {}
	for key, val in pairs(yank_pre) do
		yank[key] = val
	end
	yank.reverse = true

	local close_pre = vim.api.nvim_get_hl(
		0, { name = 'DiagnosticError', link = false }
	)
	local close = {}
	for key, val in pairs(close_pre) do
		close[key] = val
	end
	close.dim = true

	local modified_pre = vim.api.nvim_get_hl(
		0, { name = 'DiagnosticInfo', link = false }
	)
	local modified = {}
	for key, val in pairs(modified_pre) do
		modified[key] = val
	end
	modified.dim = true

	vim.api.nvim_set_hl(0, 'PanelsBufferBarCurrent', current)
	vim.api.nvim_set_hl(0, 'PanelsBufferBarYank', yank)
	vim.api.nvim_set_hl(0, 'PanelsBufferBarClose', close)
	vim.api.nvim_set_hl(0, 'PanelsBufferBarModified', modified)
end

return M
