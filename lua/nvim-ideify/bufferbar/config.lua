local M = {}

M.defaults = {
	name_pref_length = 20,
	minimal = false,
	close = ' 󰖭 ',
	modified = ' \u{00A0}',
	below_button = '\u{00A0}\u{00A0}\u{00A0}',
	pad_pre = ' ',
	pad_post = '',
	min_pad_pre = '',
	min_pad_post = '',
	separator = '│',
	button_pos = 5,
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
	vim.defer_fn(function()
		local yank_hl_pre = vim.api.nvim_get_hl(0, { name = 'Green' })
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

		local modified_hl_pre = vim.api.nvim_get_hl(0, { name = 'Blue' })
		local modified_hl = {}
		for key, val in pairs(modified_hl_pre) do
			modified_hl[key] = val
		end
		-- modified_hl.reverse = true
		modified_hl.dim = true

		vim.api.nvim_set_hl(0, 'IDEifyBufferBarYank', yank_hl)
		vim.api.nvim_set_hl(0, 'IDEifyBufferBarClose', close_hl)
		vim.api.nvim_set_hl(0, 'IDEifyBufferBarModified', modified_hl)
	end, 3000)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})

	M.options.close_reg = utils.string_to_reg(M.options.close)
	M.options.modified_reg = utils.string_to_reg(M.options.modified)
	M.options.pad_pre_reg = utils.string_to_reg(M.options.pad_pre)
	M.options.min_pad_pre_reg = utils.string_to_reg(M.options.min_pad_pre)
	M.options.separator_reg = utils.string_to_reg(M.options.separator)
end

return M
