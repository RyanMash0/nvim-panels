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

M.refresh_tree = filetree:get_ui().render
M.refresh_bufferbar = bufferbar:get_ui().render

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
