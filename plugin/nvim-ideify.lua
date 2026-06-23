if vim.g.loaded_nvim_ideify then
	return
end
vim.g.loaded_nvim_ideify = 1

vim.api.nvim_create_user_command(
	'IDEifyOpen',
	require('nvim-ideify').open,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyClose',
	require('nvim-ideify').close,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyHide',
	require('nvim-ideify').hide,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyShow',
	require('nvim-ideify').show,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyToggle',
	require('nvim-ideify').toggle,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyHardReset',
	require('nvim-ideify').hard_reset,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyPanelToggle',
	function(args)
		require('nvim-ideify').panel_toggle(args.args)
	end,
	{ nargs = 1 }
)

vim.api.nvim_create_user_command(
	'IDEifyPanelSwap',
	function(args)
		if #args.fargs ~= 2 then
			vim.print('You must provide exactly two panels as arguments.')
			return
		end

		require('nvim-ideify').panel_swap(args.fargs[1], args.fargs[2])
	end,
	{ nargs = '+' }
)

vim.api.nvim_create_user_command(
	'IDEifyPanelResize',
	function(args)
		if #args.fargs ~= 2 then
			vim.print('You must provide a panel and a size arguments.')
			return
		end
		local direction = args.fargs[1]
		local size = tonumber(args.fargs[2])

		require('nvim-ideify').panel_resize(direction, size)
	end,
	{ nargs = '+' }
)

vim.api.nvim_create_user_command(
	'IDEifyBufferBarNext',
	require('nvim-ideify').bufferbar_next,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyBufferBarPrevious',
	require('nvim-ideify').bufferbar_previous,
	{ nargs = 0 }
)
