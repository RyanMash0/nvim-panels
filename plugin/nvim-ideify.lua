if vim.g.loader_nvim_ideify then
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
	'IDEifyResetSize',
	require('nvim-ideify').reset,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyHardReset',
	require('nvim-ideify').hard_reset,
	{ nargs = 1 }
)

vim.api.nvim_create_user_command(
	'IDEifyTogglePanel',
	function(args)
		require('nvim-ideify').toggle_panel(args.args)
	end,
	{ nargs = 1 }
)

vim.api.nvim_create_user_command(
	'IDEifyRefreshFileTree',
	require('nvim-ideify').refresh_tree,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyRefreshBufferBar',
	require('nvim-ideify').refresh_bufferbar,
	{ nargs = 0 }
)
