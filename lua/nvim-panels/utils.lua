local M = {}

local config = require('nvim-panels.config')
local constants = require('nvim-panels.constants')
local state = require('nvim-panels.state')

---
---@param callback fun(bg: integer)
function M.get_term_bg(callback)
	local autocmd
	local co = coroutine.create(function()
		io.write('\027]11;?\027\\')

		local bg_str = coroutine.yield()
		local r, g, b = bg_str:match('(%w%w)%w*/(%w%w)%w*/(%w%w)%w*$')

		if not r or not g or not b then
			vim.api.nvim_del_autocmd(autocmd)
			return callback(0)
		end

		bg_str = r .. g .. b

		vim.api.nvim_del_autocmd(autocmd)
		return callback(tonumber(bg_str, 16))
	end)

	autocmd = vim.api.nvim_create_autocmd('TermResponse', {
		callback = function(args)
			local bg_str = args.data.sequence
			if bg_str:match('rgb') then
				coroutine.resume(co, bg_str)
			end
		end
	})

	local timer = vim.uv.new_timer()
	if not timer then
		vim.api.nvim_del_autocmd(autocmd)
		return
	end

	coroutine.resume(co)

	timer:start(1000, 0, function()
		vim.api.nvim_del_autocmd(autocmd)
		coroutine.close(co)
		callback(0)
	end)
end

---
---@param pos nvim-panels.position
---@return nvim-panels.split | nil
function M.position_to_split(pos)
	local position = constants.position
	local split = constants.split
	if pos == position.LEFT then
		return split.LEFT
	elseif pos == position.RIGHT then
		return split.RIGHT
	elseif pos == position.TOP then
		return split.ABOVE
	elseif pos == position.BOTTOM then
		return split.BELOW
	end
end

---
---@param sp nvim-panels.split
---@return nvim-panels.position | nil
function M.split_to_position(sp)
	local position = constants.position
	local split = constants.split
	if sp == split.LEFT then
		return position.LEFT
	elseif sp == split.RIGHT then
		return position.RIGHT
	elseif sp == split.ABOVE then
		return position.TOP
	elseif sp == split.BELOW then
		return position.BOTTOM
	end
end

---
---@param err uv.error_name
---@return nvim-panels.enum.fs_err
function M.check_err(err)
	if not err then
		return constants.fs_err.NONE
	elseif err:match('^EEXIST') then
		return constants.fs_err.EXISTS
	elseif err:match('^ENOENT') then
		return constants.fs_err.NOENTRY
	elseif err:match('^ENOTEMPTY') then
		return constants.fs_err.NOTEMPTY
	end

	return constants.fs_err.OTHER
end

---
---@param path string
---@return ...
local function await_stat(path)
	local co = coroutine.running()
	vim.uv.fs_stat(path, function(err, stat)
		vim.schedule(function()
			coroutine.resume(co, err, stat and stat.type)
		end)
	end)
	return coroutine.yield()
end

---
---@param path string
---@param mode integer
---@return ...
local function await_mkdir(path, mode)
	local co = coroutine.running()
	vim.uv.fs_mkdir(path, mode, function(err, success)
		vim.schedule(function()
			coroutine.resume(co, err, success)
		end)
	end)
	return coroutine.yield()
end

---
---@param check nvim-panels.enum.fs_err
---@param type nvim-panels.enum.fs_type
---@return boolean
local function get_dir_exists(check, type)
	return check == constants.fs_err.NONE and type == constants.fs_type.DIRECTORY
end

---
---@param path string
---@param mode integer
---@return string | nil, boolean
local function do_mkdir_p(path, mode)
	local dirs = {}
	local parent = path
	local fs_err = constants.fs_err
	local err, type = await_stat(parent)
	local check = M.check_err(err)
	local dir_exists = get_dir_exists(check, type)

	if not dir_exists and check ~= fs_err.NOENTRY then
		return err, false
	end

	while not dir_exists do
		table.insert(dirs, 1, parent)
		path = parent
		parent = vim.fs.dirname(parent)

		if parent == path or not parent then return err, false end

		err, type = await_stat(parent)
		check = M.check_err(err)
		dir_exists = get_dir_exists(check, type)

		if not dir_exists and check ~= fs_err.NOENTRY then
			return err, false
		end
	end

	local success
	for _, dir in ipairs(dirs) do
		err, success = await_mkdir(dir, mode)
		if not success and M.check_err(err) ~= fs_err.EXISTS then
			return err, success
		end
	end

	return nil, true
end

---
---@param path string
---@param mode integer
---@param callback fun(err: string | nil, success: boolean)
function M.mkdir_p_async(path, mode, callback)
	coroutine.wrap(function()
		local err, success = do_mkdir_p(path, mode)

		if callback then
			return callback(err, success)
		end
	end)()
end

---
---@param type nvim-panels.enum.type
---@param id nvim-panels.buf_id | nvim-panels.win_id
---@param opts nvim-panels.buf_opts | nvim-panels.win_opts
function M.set_opts(type, id, opts)
	for key, val in pairs(opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', [type] = id })
	end
end

---
---@return nvim-panels.buf_id
function M.get_last_win_buf()
	local last_win = M.win_valid(state.wins.last) and state.wins.last
	return vim.api.nvim_win_get_buf(last_win or state.wins.main)
end

---
---@param buf? nvim-panels.buf_id
function M.set_last_win_buf(buf)
	if not buf then return end
	M.check_or_make_main_win()
	local last_win = M.win_valid(state.wins.last) and state.wins.last

	vim.api.nvim_win_set_buf(last_win or state.wins.main, buf)
end

---
---@param id nvim-panels.buf_id
---@return boolean
function M.check_buf_type(id)
	local buf_type = vim.bo[id].buftype
	if constants.fail_buftype[buf_type] then return false end

	return true
end

---
---@param id nvim-panels.buf_id
---@return boolean
function M.check_ui2_buf(id)
	local buf_name = vim.api.nvim_buf_get_name(id)
	if constants.ui2_buffers[buf_name] then return true end

	return false
end

---
---@param id any
---@return boolean
function M.buf_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_buf_is_valid(id) then
		return false
	end
	return true
end

---
---@param id any
---@return boolean
function M.win_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_win_is_valid(id) then
		return false
	end
	return true
end

---
---@param id nvim-panels.buf_id
function M.delete_buf(id)
	if M.buf_valid(id) then
		vim.api.nvim_buf_delete(id, { force = true, })
	end
end

---
---@param id nvim-panels.win_id
function M.close_win(id)
	if M.win_valid(id) then
		vim.api.nvim_win_close(id, true)
	end
end

---
---@param position nvim-panels.position
---@return nvim-panels.panel
function M.get_panel_by_position(position)
	return config.options.layout[position]
end

---
---@param position nvim-panels.position
---@return nvim-panels.module | nil
function M.get_module_by_position(position)
	return M.get_panel_by_position(position).module()
end

---
---@param position nvim-panels.position
---@return nvim-panels.module.state | nil
function M.get_state_by_position(position)
	local module = M.get_module_by_position(position)
	return module and module.get_state() or nil
end

---
---@param position nvim-panels.position
---@return nvim-panels.buf_id
local function get_buf_by_position(position)
	local module = M.get_module_by_position(position)
	return module and module.get_state().get_buffer() or constants.NOID
end

---
---@return table<nvim-panels.position, nvim-panels.buf_id>
function M.get_position_to_buf()
	local position_to_buf = {}
	local buf
	for _, pos in pairs(constants.position) do
		buf = get_buf_by_position(pos)
		position_to_buf[pos] = M.buf_valid(buf) and buf or nil
	end
	return position_to_buf
end

---
---@return table<nvim-panels.buf_id, nvim-panels.position>
function M.get_buf_to_position()
	local buf_to_position = {}
	for position, buf in pairs(M.get_position_to_buf()) do
		buf_to_position[buf] = position
	end
	return buf_to_position
end

---
---@param buf nvim-panels.buf_id
---@return boolean
function M.is_plugin_buf(buf)
	for _, id in pairs(M.get_position_to_buf()) do
		if buf == id then return true end
	end
	return false
end

---
---@param position nvim-panels.position
---@return nvim-panels.win_id
local function get_win_by_position(position)
	local module = M.get_module_by_position(position)
	return module and module.get_state().get_window() or constants.NOID
end

---
---@return table<nvim-panels.position, nvim-panels.win_id>
function M.get_position_to_win()
	local position_to_win = {}
	local win
	for _, pos in pairs(constants.position) do
		win = get_win_by_position(pos)
		position_to_win[pos] = M.win_valid(win) and win or nil
	end
	return position_to_win
end

---
---@return table<nvim-panels.win_id, nvim-panels.position>
function M.get_win_to_position()
	local win_to_position = {}
	for position, win in pairs(M.get_position_to_win()) do
		win_to_position[win] = position
	end
	return win_to_position
end

---
---@param win nvim-panels.win_id
---@return boolean
function M.is_plugin_win(win)
	for _, id in pairs(M.get_position_to_win()) do
		if win == id then return true end
	end
	return false
end

---
---@return nvim-panels.buf_id
local function check_or_make_main_buf()
	local bufs = vim.api.nvim_list_bufs()
	---@type table<nvim-panels.buf_id, integer>
	local check_bufs = {}
	local check_type
	local check_ui2
	for i, buf in ipairs(bufs) do
		check_type = M.check_buf_type(buf)
		check_ui2 = not M.check_ui2_buf(buf)
		if vim.bo[buf].buflisted and check_type and check_ui2 then
			check_bufs[buf] = i
		end
	end

	local mod_bufs = M.get_position_to_buf()
	for _, id in pairs(mod_bufs) do
			check_bufs[id] = nil
	end

	local next_buf = next(check_bufs)

	if next_buf == nil then
		return vim.api.nvim_create_buf(true, false)
	end

	return next_buf
end

---
---@return table<nvim-panels.position, nvim-panels.win_id>
local function get_split_order_to_win()
	local pos_to_win = M.get_position_to_win()
	local split_order_to_win = {}
	for i, position in ipairs(config.options.split_order) do
		split_order_to_win[i] = pos_to_win[position]
	end

	return split_order_to_win
end

---
---@return nvim-panels.win_config
local function get_split_conf()
	local splits = get_split_order_to_win()
	local conf = {}
	for i, position in ipairs(config.options.split_order) do
		conf.split = splits[i] and M.position_to_split(position)
		if conf.split then return conf end
	end

	return {}
end

---
function M.check_or_make_main_win()
	if vim.api.nvim_win_is_valid(state.wins.main) then return end

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local check_wins = {}
	for i, win in ipairs(wins) do
		check_wins[win] = i
	end

	local mod_wins = M.get_position_to_win()
	for _, id in pairs(mod_wins) do
			check_wins[id] = nil
	end

	local win_config
	local win_buf

	for win, _ in pairs(check_wins) do
		win_config = vim.api.nvim_win_get_config(win)
		win_buf = vim.api.nvim_win_get_buf(win)
		if not win_config.focusable or win_config.relative ~= '' then
			check_wins[win] = nil
		elseif not M.check_buf_type(win_buf) or M.check_ui2_buf(win_buf) then
			check_wins[win] = nil
		end
	end

	local min = next(check_wins)
	if min == nil then
		local buf_id = check_or_make_main_buf()
		local win_conf = get_split_conf()
		state.wins.main = vim.api.nvim_open_win(buf_id, true, win_conf)
		require('nvim-panels').reset()
		return
	end

	for win, i in pairs(check_wins) do
		if i < check_wins[min] then
			min = win
		end
	end
	state.wins.main = min
end

return M
