local M = {}
local config = require('nvim-ideify.config')
local ui = require('nvim-ideify.ui')
local filetree = require('nvim-ideify.filetree')
local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.open
M.close = ui.close
M.hide = ui.hide
M.show = ui.show
M.toggle = function()
	local state = require('nvim-ideify.state')
	if state.active then
		ui.hide()
	elseif not state.active and state.opened then
		ui.show()
	elseif not state.active and not state.opened then
		ui.open()
	end
end
M.reset = ui.reset
M.hard_reset = function()
	ui.close()
	ui.open()
end

M.tree_refresh = filetree:get_ui().render
M.bufferbar_refresh = bufferbar:get_ui().render
M.bufferbar_next = bufferbar.buffer_next
M.bufferbar_previous = bufferbar.buffer_previous

function M.panel_toggle(direction)
	local state = require('nvim-ideify.state')
	local panel_confs = config.options.layout
	if not panel_confs[direction] then return end

	panel_confs[direction].hidden = not panel_confs[direction].hidden
	if state.active then ui.open() end
end

function M.panel_swap(direction1, direction2)
	local state = require('nvim-ideify.state')
	local panel_confs = config.options.layout
	if not panel_confs[direction1] or not panel_confs[direction2] then return end

	local tmp_direction1 = panel_confs[direction1]
	local tmp_direction2 = panel_confs[direction2]

	local function swap_size_params(width_direction, height_direction)
		local tmp_width = width_direction.width
		local tmp_height = height_direction.height

		width_direction.width = nil
		width_direction.height = tmp_width

		height_direction.height = nil
		height_direction.width = tmp_height
	end

	if tmp_direction1.width and not tmp_direction2.width then
		swap_size_params(tmp_direction1, tmp_direction2)
	elseif tmp_direction2.width and not tmp_direction1.width then
		swap_size_params(tmp_direction2, tmp_direction1)
	end

	panel_confs[direction1] = tmp_direction2
	panel_confs[direction2] = tmp_direction1

	local active = state.active

	ui.close()
	if active then ui.open() end
end

function M.panel_resize(direction, size)
	local panel_confs = config.options.layout
	if not panel_confs[direction] then return end

	if panel_confs[direction].width then panel_confs[direction].width = size
	elseif panel_confs[direction].height then panel_confs[direction].height = size end

	ui.reset()
end

function M.setup(opts)
	config.setup(opts)
	require('nvim-ideify.state').wins.main = vim.api.nvim_get_current_win()
end

vim.api.nvim_create_augroup('IDEify', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
	group = 'IDEify',
	callback = function()
		local state = require('nvim-ideify.state')
		local utils = require('nvim-ideify.utils')

		local win = vim.api.nvim_get_current_win()

		if not utils.is_plugin_win(win) then
			state.wins.last = win
		end
	end,
})

vim.api.nvim_create_autocmd('TextChanged', {
	group = 'IDEify',
	callback = function()
		local utils = require('nvim-ideify.utils')
		local win = vim.api.nvim_get_current_win()
		local modules = utils.get_modules()
		local mod_win
		local buf
		for _, module in pairs(modules) do
			mod_win = module:get_state():get_window()
			mod_win = mod_win > -1 and mod_win or 0
			buf = vim.api.nvim_win_get_buf(mod_win)
			if win == mod_win and vim.bo[buf].filetype == 'netrw' then
				ui.module_buf_reload(module)
			end
		end
	end
})

vim.api.nvim_create_autocmd('WinResized', {
	group = 'IDEify',
	callback = function(args)
		local utils = require('nvim-ideify.utils')
		local win = tonumber(args.match)
		local modules = utils.get_modules()
		local mod_win
		for _, module in pairs(modules) do
			mod_win = module:get_state():get_window()
			if win == mod_win then
				module:get_ui().render()
			end
		end
	end
})

-- local events = vim.fn.getcompletion('', 'event')
-- local forbidden_events = {
-- 	["BufReadCmd"] = true,
-- 	["BufWriteCmd"] = true,
-- 	["CmdlineChanged"] = true,
-- 	["CmdlineEnter"] = true,
-- 	["ColorScheme"] = true,
-- 	["ColorSchemePre"] = true,
-- 	["CursorMoved"] = true,
-- 	["CursorMovedI"] = true,
-- 	["CursorMovedC"] = true,
-- 	["CursorHold"] = true,
-- 	["CursorHoldI"] = true,
-- 	["DiagnosticChanged"] = true,
-- 	["ExitPre"] = true,
-- 	["FileReadCmd"] = true,
-- 	["FileWriteCmd"] = true,
-- 	["FocusGained"] = true,
-- 	["FocusLost"] = true,
-- 	["LspNotify"] = true,
-- 	["LspProgress"] = true,
-- 	["LspRequest"] = true,
-- 	["LspTokenUpdate"] = true,
-- 	["OptionSet"] = true,
-- 	["SafeState"] = true,
-- 	["SourceCmd"] = true,
-- 	["SourcePre"] = true,
-- 	["SourcePost"] = true,
-- 	["UIEnter"] = true,
-- 	["VimEnter"] = true,
-- 	["VimResized"] = true,
-- 	["VimResume"] = true,
-- 	["VimSuspend"] = true,
-- 	["VimLeave"] = true,
-- 	["VimLeavePre"] = true,
-- 	["WinScrolled"] = true,
-- }
--
-- for i, event in ipairs(events) do
-- 	if forbidden_events[event] then
-- 		events[i] = nil
-- 	end
-- end
--
-- local new_events = {}
-- for _, event in pairs(events) do
-- 	table.insert(new_events, event)
-- end
--
-- vim.api.nvim_create_autocmd(new_events, {
-- 	group = 'IDEify',
-- 	callback = function(args)
--     -- Print the exact event and the time it fired
--     local time = os.date("%H:%M:%S")
--     print(string.format("[%s] Event fired: %s (Buf: %d)", time, args.event, args.buf))
--   end,
-- })
return M
