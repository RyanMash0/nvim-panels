local M = {}
local constants = require('nvim-ideify.constants')

---@type nvim-ideify.config
M.defaults = {
	layout = {
		left = {
			module = function ()
				return require('nvim-ideify.filetree')
			end,
			width = 30,
			hidden = false,
		},
		right = {
			module = function ()
				return nil
			end,
			width = 50,
			hidden = false,
		},
		top = {
			module = function ()
				return require('nvim-ideify.bufferbar')
			end,
			height = 2,
			hidden = false
		},
		bottom = {
			module = function ()
				return require('nvim-ideify.terminal')
			end,
			height = 10,
			hidden = false
		},
	},
	split_order = {
		first = constants.position.LEFT,
		second = constants.position.RIGHT,
		third = constants.position.TOP,
		fourth = constants.position.BOTTOM,
	},
}

---@type nvim-ideify.config
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	local utils = require('nvim-ideify.utils')
	utils.mkdir_p_async(
		constants.trash_path,
		tonumber('755', 8),
		function(err, success)
			if not success then
				local err_str = 'Failed to create trash directory: "' .. err .. '"'
				vim.notify(err_str, vim.log.levels.ERROR)
			end
		end
	)
	require('nvim-ideify.filetree').get_config().setup(opts.filetree)
	require('nvim-ideify.bufferbar').get_config().setup(opts.bufferbar)
	require('nvim-ideify.terminal').get_config().setup(opts.terminal)

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
