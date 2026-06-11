local M = {}

M.defaults = {
	name_pref_length = 20,
	minimal = false,
	styling = {
		separator = '│',
		button = {
			close = ' 󰖭 ',
			modified = ' \u{00A0}',
			below = '\u{00A0}\u{00A0}\u{00A0}',
			pos = 5,
		},
		padding = {
			normal = {
				before = ' ',
				after = '',
			},
			minimal = {
				before = '',
				after = '',
			}
		},
	},
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
	local utils = require('nvim-ideify.bufferbar.utils')
	vim.schedule(function()
		local yank_hl_pre = vim.api.nvim_get_hl(0, { name = 'Blue' })
		local yank_hl = {}
		for key, val in pairs(yank_hl_pre) do
			yank_hl[key] = val
		end
		yank_hl.reverse = true

		local close_hl_pre = vim.api.nvim_get_hl(0, { name = 'Red' })
		local close_hl = {}
		for key, val in pairs(close_hl_pre) do
			close_hl[key] = val
		end
		-- close_hl.reverse = true
		close_hl.dim = true

		local modified_hl_pre = vim.api.nvim_get_hl(0, { name = 'Green' })
		local modified_hl = {}
		for key, val in pairs(modified_hl_pre) do
			modified_hl[key] = val
		end
		-- modified_hl.reverse = true
		modified_hl.dim = true

		vim.api.nvim_set_hl(0, 'IDEifyBufferBarYank', yank_hl)
		vim.api.nvim_set_hl(0, 'IDEifyBufferBarClose', close_hl)
		vim.api.nvim_set_hl(0, 'IDEifyBufferBarModified', modified_hl)
	end)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})

	M.options.regex = {}

	M.options.regex.close = utils.string_to_reg(M.options.styling.button.close)
	M.options.regex.modified = utils.string_to_reg(M.options.styling.button.modified)
	M.options.regex.pad_pre = utils.string_to_reg(M.options.styling.padding.normal.before)
	M.options.regex.min_pad_pre = utils.string_to_reg(M.options.styling.padding.minimal.before)
	M.options.regex.separator = utils.string_to_reg(M.options.styling.separator)
end

return M
