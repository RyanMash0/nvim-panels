local M = {}

local g_utils = require('nvim-ideify.utils')
local g_ui = require('nvim-ideify.ui')

local config = require('nvim-ideify.terminal.config')
local constants = require('nvim-ideify.terminal.constants')
local state = require('nvim-ideify.terminal.state')

local shell = vim.opt.shell:get()

---
function M.render()
	local buf_id = state.get_buffer()
	local win_id = state.get_window()

	if not g_utils.buf_valid(buf_id) then
		g_ui.open()
		state.clear_buf_list()
		return M.render()
	end

	if vim.bo[buf_id].buftype ~= 'terminal' then
		vim.wo[win_id].winfixbuf = false
		vim.api.nvim_buf_call(buf_id, function()
			vim.fn.jobstart({ shell }, { term = true })
		end)
		vim.wo[win_id].winfixbuf = true
	end

	state.register_main_buf()

	for _, buf in state.buf_iterator(2) do
		if vim.bo[buf].buftype ~= 'terminal' then
			vim.api.nvim_buf_call(buf, function()
				vim.fn.jobstart({ shell }, { term = true })
			end)
		end
		vim.bo[buf].buflisted = false
	end

	local sep = constants.statusline.sep
	local hl_selected = constants.statusline.hl.selected
	local hl_normal = constants.statusline.hl.normal
	local statusline = { config.options.base_statusline }
	local cur_buf = vim.api.nvim_win_get_buf(win_id)
	local sel_pos = state.get_pos_by_buf(cur_buf)
	local hl_str

	for i, _ in state.buf_iterator() do
		hl_str = (i == sel_pos and hl_selected) or hl_normal
		table.insert(statusline, sep)
		table.insert(statusline, hl_str)
		table.insert(statusline, tostring(i - 1))
	end
	table.insert(statusline, sep)

	config.options.window.statusline = table.concat(statusline)
	g_utils.set_opts('win', win_id, config.options.window)

	local keymaps = require('nvim-ideify.terminal.keymaps')
	keymaps.setup()
end

return M
