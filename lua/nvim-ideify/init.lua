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
M.toggle = function()
	if state.active then
		ui.hide()
	else
		ui.show()
	end
end
M.reset = function()
	if not state.active then return end
	ui.show()
end
M.hard_reset = function()
	if not state.opened then return end
	if state.active then
		ui.open()
	else
		ui.close()
	end
end

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

	panel_confs[position1].module = tmp_module2
	panel_confs[position2].module = tmp_module1

	local active = state.active

	if active then ui.show() end
end

function M.panel_resize(position, size)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	if panel_confs[position].width then
		panel_confs[position].width = size
	elseif panel_confs[position].height then
		panel_confs[position].height = size
	end

	local active = state.active

	if active then ui.show() end
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
	callback = function(args)
		local utils = require('nvim-ideify.utils')
		local buf = args.buf
		if utils.is_plugin_buf(buf) and vim.bo[buf].filetype == 'netrw' then
			local buf_to_pos = utils.get_buf_to_position()
			ui.module_buf_reload(buf_to_pos[args.buf])
		end
	end
})

vim.api.nvim_create_autocmd('WinResized', {
	group = 'IDEify',
	callback = function(args)
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
