local M = {}

local config = require('nvim-ideify.config')
local constants = require('nvim-ideify.constants')
local state = require('nvim-ideify.state')
local ui = require('nvim-ideify.ui')

local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.open
M.close = ui.close
M.hide = ui.hide
M.show = ui.show
M.toggle = ui.toggle
M.reset = ui.reset
M.hard_reset = ui.hard_reset

M.bufferbar_next = bufferbar.buffer_next
M.bufferbar_previous = bufferbar.buffer_previous

---
---@param position nvim-ideify.position
function M.panel_toggle(position)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	panel_confs[position].hidden = not panel_confs[position].hidden

	M.reset()
end

---
---@param position1 nvim-ideify.position
---@param position2 nvim-ideify.position
function M.panel_swap(position1, position2)
	local panel_confs = config.options.layout
	if not panel_confs[position1] or not panel_confs[position2] then return end

	local tmp_module1 = panel_confs[position1].module
	local tmp_module2 = panel_confs[position2].module

	panel_confs[position1].module = tmp_module2
	panel_confs[position2].module = tmp_module1

	M.reset()
end

---
---@param position nvim-ideify.position
---@param size integer
function M.panel_resize(position, size)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	if panel_confs[position].width then
		panel_confs[position].width = size
	elseif panel_confs[position].height then
		panel_confs[position].height = size
	end

	M.reset()
end

---
---@param opts nvim-ideify.options
function M.setup(opts)
	config.setup(opts)
	require('nvim-ideify.state').wins.main = vim.api.nvim_get_current_win()
end

vim.api.nvim_create_augroup('IDEify', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
	group = 'IDEify',
	callback = function(args)
		local utils = require('nvim-ideify.utils')
		local win = vim.api.nvim_get_current_win()
		local buf = args.buf
		local buf_type = vim.bo[buf].buftype
		local check_id = not constants.ui2_buffers[buf]
		local check_type = buf_type ~= 'terminal' and
			buf_type ~= 'help' and buf_type ~= 'quickfix' and
			buf_type ~= 'nofile' and buf_type ~= 'prompt'
		if not utils.is_plugin_win(win) and check_id and check_type then
			state.wins.last = win
		end
	end,
})

vim.api.nvim_create_autocmd('TextChanged', {
	group = 'IDEify',
	callback = function(args)
		if vim.bo[args.buf].filetype ~= 'netrw' or not state.active then
			return
		end
		local utils = require('nvim-ideify.utils')
		local win = vim.api.nvim_get_current_win()
		if utils.is_plugin_win(win) then
			local win_to_pos = utils.get_win_to_position()
			ui.module_buf_reload(win_to_pos[win])
		end
	end
})

vim.api.nvim_create_autocmd('WinResized', {
	group = 'IDEify',
	callback = function(args)
		if not state.active then return end
		local utils = require('nvim-ideify.utils')
		local win = tonumber(args.match) or constants.NOID
		if utils.is_plugin_win(win) then
			local win_to_pos = utils.get_win_to_position()
			local pos = win_to_pos[win]
			local module = config.options.layout[pos].module()
			module.get_ui().render()
		end
	end
})

return M
