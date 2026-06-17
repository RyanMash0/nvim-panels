local M = {}

local config = require('nvim-ideify.config')
local constants = require('nvim-ideify.constants')
local state = require('nvim-ideify.state')
local ui = require('nvim-ideify.ui')

local filetree = require('nvim-ideify.filetree')
local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.open
M.close = ui.close
M.hide = ui.hide
M.show = ui.show
M.toggle = function()
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

M.tree_refresh = filetree.get_ui().render
M.bufferbar_refresh = bufferbar.get_ui().render
M.bufferbar_next = bufferbar.buffer_next
M.bufferbar_previous = bufferbar.buffer_previous

function M.panel_toggle(direction)
	local panel_confs = config.options.layout
	if not panel_confs[direction] then return end

	panel_confs[direction].hidden = not panel_confs[direction].hidden
	if state.active then ui.show() end
end

function M.panel_swap(position1, position2)
	local panel_confs = config.options.layout
	if not panel_confs[position1] or not panel_confs[position2] then return end

	local tmp_module1 = panel_confs[position1].module
	local tmp_module2 = panel_confs[position2].module

	local base_config
	if tmp_module1() then
		base_config = tmp_module1().get_constants().config.window
		tmp_module1().get_state().set_win_config(base_config)
	end
	if tmp_module2() then
		base_config = tmp_module2().get_constants().config.window
		tmp_module2().get_state().set_win_config(base_config)
	end

	panel_confs[position1].module = tmp_module2
	panel_confs[position2].module = tmp_module1

	local active = state.active

	ui.hide()
	if active then ui.show() end
end

function M.panel_resize(position, size)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	if panel_confs[position].width then panel_confs[position].width = size
	elseif panel_confs[position].height then panel_confs[position].height = size end

	ui.reset()
end

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

-- vim.api.nvim_create_autocmd('BufWinEnter', {
-- 	group = 'IDEify',
-- 	pattern = 'quickfix',
-- 	callback = function(args)
-- 		vim.print(args)
-- 		-- vim.schedule(ui.reset)
-- 	end,
-- })

vim.api.nvim_create_autocmd('TextChanged', {
	group = 'IDEify',
	callback = function()
		local utils = require('nvim-ideify.utils')
		local win = vim.api.nvim_get_current_win()
		local modules = utils.get_modules()
		local mod_win
		local buf
		for _, module in pairs(modules) do
			mod_win = module.get_state().get_window()
			mod_win = utils.win_valid(mod_win) and mod_win or 0
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
		local win = tonumber(args.match) or constants.NOID
		local modules = utils.get_modules()
		local mod_win
		for _, module in pairs(modules) do
			mod_win = module.get_state().get_window()
			if win == mod_win then
				module.get_ui().render()
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
