---@class nvim-panels.config
local M = {}

local constants = require('nvim-panels.constants')

---@type nvim-panels.options
M.defaults = {
	layout = {
		left = {
			module = function()
				return (require('nvim-panels.filetree'))
			end,
			width = 30,
			hidden = false,
		},
		right = {
			module = function()
				return nil
			end,
			width = 50,
			hidden = false,
		},
		top = {
			module = function()
				return (require('nvim-panels.bufferbar'))
			end,
			height = 2,
			hidden = false,
		},
		bottom = {
			module = function()
				return (require('nvim-panels.terminal'))
			end,
			height = 10,
			hidden = false,
		},
	},
	split_order = {
		[1] = constants.position.LEFT,
		[2] = constants.position.RIGHT,
		[3] = constants.position.TOP,
		[4] = constants.position.BOTTOM,
	},
	permissions = {
		directory = tonumber('755', 8),
		file = tonumber('644', 8),
	},
	trash_path = vim.fs.joinpath(
		vim.uv.os_homedir(), '.local/share/Trash/nvim-panels'
	),
}

---@type nvim-panels.options
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	local utils = require('nvim-panels.utils')
	opts = opts or {}
	require('nvim-panels.filetree').get_config().setup(opts.filetree)
	require('nvim-panels.bufferbar').get_config().setup(opts.bufferbar)
	require('nvim-panels.terminal').get_config().setup(opts.terminal)

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
	utils.mkdir_p_async(
		M.options.trash_path,
		M.options.permissions.directory,
		function(err, success)
			if not success then
				local err_str = 'Failed to create trash directory: "' .. err .. '"'
				vim.notify(err_str, vim.log.levels.ERROR)
			end
		end
	)
end

return M
