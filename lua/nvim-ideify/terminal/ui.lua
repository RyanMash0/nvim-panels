local M = {}
local state = require('nvim-ideify.terminal.state')
local config = require('nvim-ideify.terminal.config')
local g_utils = require('nvim-ideify.utils')
local g_ui = require('nvim-ideify.ui')

function M.set_statusline()
end

function M.render()
	-- vim.api.nvim_open_term(term_buf, {})
	local buf = state:get_buffer()
	local win = state.window

	if not g_utils.buf_valid(buf) then
		g_ui.open()
		state.extra_buffers = {}
		state.extra_buffers_r = {}
		return M.render()
	end

	if vim.bo[buf].buftype ~= 'terminal' then
		vim.api.nvim_buf_call(buf, function() vim.cmd.terminal() end)
	end

	local extra_buffers = state.extra_buffers
	local extra_buffers_r = state.extra_buffers_r

	for key, val in pairs(extra_buffers_r) do
		if val == 1 then
			extra_buffers_r[key] = nil
		end
	end

	extra_buffers[1] = buf
	extra_buffers_r[buf] = 1

	local extra_buf_str = ' %#StatusLine#|'
	local cur_buf = vim.api.nvim_win_get_buf(win)
	local sel_idx = state.extra_buffers_r[cur_buf]
	local sel_hl_str = '%#TabLineSel#'
	local nosel_hl_str = '%#StatusLine#'
	local check_idx
	local hl_str

	for i, extra_buf in ipairs(extra_buffers) do
		if vim.bo[extra_buf].buftype ~= 'terminal' then
			vim.api.nvim_buf_call(extra_buf, function() vim.cmd.terminal() end)
		end
		vim.bo[extra_buf].buflisted = false
		check_idx = i == sel_idx
		hl_str = check_idx and sel_hl_str or nosel_hl_str
		extra_buf_str = extra_buf_str .. hl_str .. ' ' .. tostring(i - 1) .. ' %#StatusLine#|'
	end

	local win_opts = config.options.window.opts
	win_opts.statusline = config.options.base_statusline .. extra_buf_str
	for key, val in pairs(win_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', win = win })
	end

	local keymaps = require('nvim-ideify.terminal.keymaps')
	keymaps.setup()
end

return M
