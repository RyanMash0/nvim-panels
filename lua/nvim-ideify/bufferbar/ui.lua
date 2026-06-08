local M = {}
local config = require('nvim-ideify.bufferbar.config')
local state = require('nvim-ideify.bufferbar.state')
local utils = require('nvim-ideify.bufferbar.utils')
local g_utils = require('nvim-ideify.utils')

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

local function buffer_delete(buf)
		local cur_buf = g_utils.get_last_win_buf()
		local buf_info = state.buffer_info
		local buf_order = state.buffer_order
		local del_info = buf_info[buf]
		local del_pos = del_info.position
		local new_pos = del_pos == #buf_order and del_pos - 1 or del_pos + 1
		local new_buf = buf_order[new_pos]
		if not g_utils.buf_valid(new_buf) then new_buf = 0 end
		vim.api.nvim_buf_delete(buf, {})
		M.render()
		local col = state.buttons_r[new_buf]
		vim.api.nvim_win_set_cursor(state:get_window(), col and { 1, col } or { 2, 1 })

		if buf ~= cur_buf then return cur_buf end

		return new_buf
end

local function buffer_switch()
	local switch_buf = utils.get_sel_buffer()

	return switch_buf
end

function M.action()
	local win_id = state:get_window()
	local pos = vim.api.nvim_win_get_cursor(win_id)
	local cur_col = pos[2]
	local button = pos[1] == 1 and state.buttons[cur_col]
	local check_button = button and not vim.bo[button].modified
	local buf = check_button and buffer_delete(button) or buffer_switch()

	g_utils.set_last_win_buf(buf)
end

function M.highlight()
	g_utils.check_or_make_main_win()
	local buf_id = state:get_buffer()
	local ns = state:get_namespace()
	vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
	local cur_buf = g_utils.get_last_win_buf()
	local yanked = state.yanked
	local hl_region = state:get_buffer_info()[cur_buf]
	local yank_hl_region = state:get_buffer_info()[yanked]
	local hl_group = vim.api.nvim_get_hl_id_by_name('TabLineSel')
	local yank_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarYank')
	local close_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarClose')
	local modified_hl_group = vim.api.nvim_get_hl_id_by_name('IDEifyBufferBarModified')
	-- local hl_group_bold = vim.api.nvim_get_hl_id_by_name('markdownBold')
	if not hl_region or hl_region == vim.NIL then return end
	local button_len = #config.options.close

	for tab_buf, info in pairs(state.buffer_info) do
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, info.last - button_len, {
			end_col = info.last,
			hl_group = vim.bo[tab_buf].modified and modified_hl_group or close_hl_group,
		})
	end

	if cur_buf ~= yanked then
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, hl_region.first, {
			-- end_col = hl_region.last - button_len,
			end_col = hl_region.last,
			hl_group = hl_group,
		})

		vim.api.nvim_buf_set_extmark(buf_id, ns, 1, hl_region.first, {
			end_col = hl_region.last,
			hl_group = hl_group,
		})
	end

	if yank_hl_region then
		vim.api.nvim_buf_set_extmark(buf_id, ns, 0, yank_hl_region.first, {
			end_col = yank_hl_region.last,
			hl_group = yank_hl_group,
		})

		vim.api.nvim_buf_set_extmark(buf_id, ns, 1, yank_hl_region.first, {
			end_col = yank_hl_region.last,
			hl_group = yank_hl_group,
		})
	end
end

function M.render()
	local buf_id = state:get_buffer()
	if not g_utils.buf_valid(buf_id) then return end
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
	local minimal = config.options.minimal
	local normal_pad_pre = config.options.pad_pre
	local min_pad_pre = config.options.min_pad_pre
	local pad_pre = minimal and min_pad_pre or normal_pad_pre
	local normal_pad_post = config.options.pad_post
	local min_pad_post = config.options.min_pad_post
	local pad_post = minimal and min_pad_post or normal_pad_post
	local sep = config.options.separator
	local close = config.options.close
	local modified = config.options.modified
	local button_bot = config.options.below_button
	local button_pos = config.options.button_pos
	local extra_len = string.len(pad_pre .. pad_post .. close)

	for i, buf in ipairs(bufs_filtered) do
		buf_name = vim.api.nvim_buf_get_name(buf)

		abs_path = vim.fs.abspath('.'):gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%0')
		dir_name = buf_name:gsub(abs_path .. '/', '')
		dir_name = './' .. dir_name:gsub('[^/]+$', '')
		dir_name = truncate_middle(dir_name, pref_len)

		truncate_len = math.max(pref_len, #dir_name)
		file_name = buf_name:match('[^/]+$') or ''

		if minimal then
			dir_name = file_name:match('^[^%.]+') or ''
			file_name = file_name:match('%..*') or ''
		else
			file_name = truncate_end(file_name, truncate_len)
		end

		max_len = math.max(#dir_name, #file_name)

		file_name = extend_length(file_name, max_len)
		dir_name = extend_length(dir_name, max_len)

		tab_start = #file_str
		tab_end = tab_start + max_len + extra_len

		buffer_info[buf] = { first = tab_start, last = tab_end, position = i }

		if vim.bo[buf].modified then interact = modified
		else interact = close end

		dir_str = dir_str .. pad_pre .. dir_name .. pad_post .. interact .. sep
		file_str = file_str .. pad_pre .. file_name .. pad_post .. button_bot .. sep
		state.buttons[tab_end - button_pos] = buf
		state.buttons_r[buf] = tab_end - button_pos
	end

	-- vim.print(buffer_info)
	state:set_buffer_info(buffer_info)
	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {dir_str, file_str})
	vim.bo[buf_id].modifiable = false
	M.highlight()
end

return M
