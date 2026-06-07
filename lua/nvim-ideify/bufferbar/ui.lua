local M = {}
local config = require('nvim-ideify.bufferbar.config')
local state = require('nvim-ideify.bufferbar.state')
local g_state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')

local function truncate_end(str, num)
	if #str <= num then return str end
	return str:sub(1, num - 3) .. '...'
end

local function truncate_middle(str, num)
	if #str <= num then return str end
	if str:match('^%.//?[^/]+/$') then return str:gsub('%.//', '/') end
	if str:match('^%.//?[^/]+/[^/]+/$') then return str:gsub('%.//', '/') end
	local prefix = str:match('^%./[^/]+/') or ''
	if str:match('^%.//[^/]') then prefix = '/' end
	local suffix = str:match('/[^/]+/$') or ''
	return prefix .. '...' .. suffix
end

local function extend_length(str, num)
	if #str == num then return str end
	for _ = 1, num - #str do
		str = str .. ' '
	end
	return str
end

function M.action()
	local win_id = state:get_window()
	local pos = vim.api.nvim_win_get_cursor(win_id)
	local cur_col = pos[2]
	local buffer_info = state:get_buffer_info()
	local switch_buf
	local button = pos[1] == 1 and state.buttons[cur_col]

	if button and not vim.bo[button].modified then
		-- vim.bo[button].buflisted = false
		-- if vim.api.nvim_buf_is_loaded(button) then
			-- vim.api.nvim_buf_delete(button, { unload = true })
		-- end
		vim.api.nvim_buf_delete(button, {})
		M.render()
	end

	for key, val in pairs(buffer_info) do
		if val ~= vim.NIL and cur_col >= val.first and cur_col <= val.last then
			switch_buf = key
			break
		end
	end

	if not switch_buf then return end
	utils.check_or_make_main_win()
	local last_win = utils.win_valid(g_state.wins.last) and g_state.wins.last

	vim.api.nvim_win_set_buf(last_win or g_state.wins.main, switch_buf)
end

function M.highlight()
	utils.check_or_make_main_win()
	local buf_id = state:get_buffer()
	local ns = state:get_namespace()
	vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
	local last_win = utils.win_valid(g_state.wins.last) and g_state.wins.last
	local cur_buf = vim.api.nvim_win_get_buf(last_win or g_state.wins.main)
	local hl_region = state:get_buffer_info()[cur_buf]
	local hl_group = vim.api.nvim_get_hl_id_by_name('TabLineSel')
	-- local hl_group_bold = vim.api.nvim_get_hl_id_by_name('markdownBold')
	if not hl_region or hl_region == vim.NIL then return end
	vim.api.nvim_buf_set_extmark(buf_id, ns, 0, hl_region.first, {
		end_col = hl_region.last,
		hl_group = hl_group
	})

	-- vim.api.nvim_buf_set_extmark(buf_id, ns, 0, hl_region.last - 4, {
	-- 	end_col = hl_region.last,
	-- 	hl_group = hl_group_bold - 2
	-- })
	--
	vim.api.nvim_buf_set_extmark(buf_id, ns, 1, hl_region.first, {
		end_col = hl_region.last,
		hl_group = hl_group
	})
end

function M.render()
	local buf_id = state:get_buffer()
	if not utils.buf_valid(buf_id) then return end
	if not state.buffer_order then state.buffer_order = vim.api.nvim_list_bufs() end
	local buffers = state.buffer_order
	local bufs_filtered = {}
	-- local term_buffers = {}
	state.buttons = {}
	for _, buf in ipairs(buffers) do
		if vim.bo[buf].buflisted then
			table.insert(bufs_filtered, buf)
		end
		--
		-- if vim.bo[buf].buftype == 'terminal' then
		-- 	table.insert(term_buffers, buf)
		-- end
	end

	local buffer_info = {}
	local buf_name
	local file_name
	local dir_name
	local file_str = ''
	local dir_str = ''
	local pref_len = config.options.name_pref_length
	local truncate_len
	local max_len
	local abs_path
	local interact
	local tab_start
	local tab_end
	for i, buf in ipairs(bufs_filtered) do
		buf_name = vim.api.nvim_buf_get_name(buf)

		abs_path = vim.fs.abspath('.'):gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%0')
		dir_name = buf_name:gsub(abs_path .. '/', '')
		dir_name = './' .. dir_name:gsub('[^/]+$', '')
		dir_name = truncate_middle(dir_name, pref_len)

		truncate_len = math.max(pref_len, #dir_name)
		file_name = buf_name:match('[^/]+$') or ''
		file_name = truncate_end(file_name, truncate_len)

		max_len = math.max(#dir_name, #file_name)

		file_name = extend_length(file_name, max_len)
		dir_name = extend_length(dir_name, max_len)

		tab_start = #file_str
		tab_end = tab_start + max_len + 7

		buffer_info[buf] = { first = tab_start, last = tab_end, position = i }
		-- vim.print(buffer_info[buf])
		-- if vim.bo[buf].modified then interact = '\u{25CF}'
		-- else interact = '\u{2A2F}' end
		-- circle: '\u{2981}'
		-- circle: '\u{25CF}'
		-- x: '\u{2A2F}' 

		if vim.bo[buf].modified then interact = '+'
		else interact = 'x' end

		dir_str = dir_str .. ' ' .. dir_name .. ' \u{23BF}' .. interact .. '\u{23CC}'
		file_str = file_str .. ' ' .. file_name .. '  \u{23BA}\u{23B9}'
		state.buttons[tab_end - 2] = buf
	end

	state:set_buffer_info(buffer_info)
	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {dir_str, file_str})
	vim.bo[buf_id].modifiable = false
	M.highlight()
end

return M
