if vim.g.loaded_nvim_ideify then
	return
end
vim.g.loaded_nvim_ideify = 1

local constants = require('nvim-ideify.constants')

--- Get completion for the constants.position enum on every argument
---
---@param arg_lead string (string) Leading part of current argument
---@return string[] # List of completion candidates
local function position_complete(arg_lead)
	return vim.tbl_filter(function(item)
		return vim.startswith(item, arg_lead)
	end, constants.position)
end

--- Get completion for the constants.position enum on only the first argument
---
---@param arg_lead string (string) Leading part of current argument
---@param cmd_line string (string) Entire command line
---@return string[] # List of completion candidates
local function position_complete_single(arg_lead, cmd_line, _)
	local _, num = cmd_line:gsub(' ', ' ')
	if num < 2 then
		return position_complete(arg_lead)
	end
	return {}
end

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
	'IDEifyReset',
	require('nvim-ideify').reset,
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
	{ nargs = 1, complete = position_complete }
)

vim.api.nvim_create_user_command(
	'IDEifyPanelSwap',
	function(args)
		if #args.fargs ~= 2 then
			local err_str = 'You must provide exactly two panels as arguments'
			vim.notify(err_str, vim.log.levels.ERROR)
			return
		end

		require('nvim-ideify').panel_swap(args.fargs[1], args.fargs[2])
	end,
	{ nargs = '+', complete = position_complete }
)

vim.api.nvim_create_user_command(
	'IDEifyPanelResize',
	function(args)
		if #args.fargs ~= 2 then
			local err_str = 'You must provide a panel and a size arguments'
			vim.notify(err_str, vim.log.levels.ERROR)
			return
		end

		local direction = args.fargs[1]
		local size = tonumber(args.fargs[2])
		if not size then
			local err_str = 'Second argument must be a number'
			vim.notify(err_str, vim.log.levels.ERROR)
			return end

		require('nvim-ideify').panel_resize(direction, size)
	end,
	{ nargs = '+', complete = position_complete_single }
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
