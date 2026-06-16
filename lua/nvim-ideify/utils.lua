local M = {}

local constants = require('nvim-ideify.constants')
local state = require('nvim-ideify.state')

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

local function await_stat(path)
	local co = coroutine.running()
	vim.uv.fs_stat(path, function(err, stat)
		vim.schedule(function()
			coroutine.resume(co, err, stat and stat.type)
		end)
	end)
	return coroutine.yield()
end

local function await_mkdir(path, mode)
	local co = coroutine.running()
	vim.uv.fs_mkdir(path, mode, function(err, success)
		vim.schedule(function()
			coroutine.resume(co, err, success)
		end)
	end)
	return coroutine.yield()
end

local function get_dir_exists(check, type)
	return check == constants.fs_err.NONE and type == 'directory'
end

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

function M.mkdir_p_async(path, mode, callback)
	coroutine.wrap(function()
		local err, success = do_mkdir_p(path, mode)

		if callback then
			return callback(err, success)
		end
	end)()
end

function M.repeat_str(str, num)
	local str_array = {}
	for _ = 1, num do
		table.insert(str_array, str)
	end
	return table.concat(str_array)
end

function M.create_win_with_opts(buf, enter, config, opts)
	local win = vim.api.nvim_open_win(buf, enter, config)

	M.set_opts(constants.type.WIN, win, opts)

	return win
end

function M.create_buf_with_opts(config, opts)
	local buf = vim.api.nvim_create_buf(config.listed, config.scratch)

	M.set_opts(constants.type.BUF, buf, opts)

	return buf
end

function M.set_opts(type, id, opts)
	for key, val in pairs(opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', [type] = id })
	end
end

local function get_split_opts(pos_to_win_valid)
	local position = constants.position

	if pos_to_win_valid[position.LEFT] then
		return { split = M.position_to_split(position.LEFT) }
	elseif pos_to_win_valid[position.RIGHT] then
		return { split = M.position_to_split(position.RIGHT) }
	elseif pos_to_win_valid[position.TOP] then
		return { split = M.position_to_split(position.TOP) }
	elseif pos_to_win_valid[position.BOTTOM] then
		return { split = M.position_to_split(position.BOTTOM) }
	end
end

local function check_or_make_main_buf()
	local bufs = vim.api.nvim_list_bufs()
	local check_bufs = {}
	for i, buf in ipairs(bufs) do
		check_bufs[buf] = i
	end

	local mods = M.get_modules()
	local mod_buf
	local mod_buf_valid
	for _, module in pairs(mods) do
		mod_buf = module and module.get_state().get_buffer() or constants.NOID
		mod_buf_valid = M.buf_valid(mod_buf)
		if mod_buf_valid then
			check_bufs[mod_buf] = nil
		end
	end

	for id, _ in pairs(constants.ui2_buffers) do
		check_bufs[id] = nil
	end

	if next(check_bufs) == nil then
		return vim.api.nvim_create_buf(true, false)
	end

	return next(check_bufs)
end

function M.win_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_win_is_valid(id) then
		return false
	end
	return true
end

function M.get_last_win_buf()
	local last_win = M.win_valid(state.wins.last) and state.wins.last
	return vim.api.nvim_win_get_buf(last_win or state.wins.main)
end

function M.set_last_win_buf(buf)
	local g_utils = require('nvim-ideify.utils')
	local g_state = require('nvim-ideify.state')

	g_utils.check_or_make_main_win()
	local last_win = g_utils.win_valid(g_state.wins.last) and g_state.wins.last

	vim.api.nvim_win_set_buf(last_win or g_state.wins.main, buf)
end

function M.buf_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_buf_is_valid(id) then
		return false
	end
	return true
end

function M.get_modules()
	local config = require('nvim-ideify.config')
	return {
		left = config.options.layout.left.module(),
		right = config.options.layout.right.module(),
		top = config.options.layout.top.module(),
		bottom = config.options.layout.bottom.module(),
	}
end

function M.get_plugin_wins()
	local modules = M.get_modules()
	local left = modules.left
	local right = modules.right
	local top = modules.top
	local bottom = modules.bottom
	return {
		left = left and left.get_state().get_window() or constants.NOID,
		right = right and right.get_state().get_window() or constants.NOID,
		top = top and top.get_state().get_window() or constants.NOID,
		bottom = bottom and bottom.get_state().get_window() or constants.NOID,
	}
end

function M.is_plugin_win(win)
	if not M.win_valid(win) then return false end
	local wins = M.get_plugin_wins()
	local l_win = wins.left
	local r_win = wins.right
	local t_win = wins.top
	local b_win = wins.bottom
	if win == l_win or win == r_win or win == t_win or win == b_win then
		return true
	end
	return false
end

function M.check_or_make_main_win()
	if vim.api.nvim_win_is_valid(state.wins.main) then return end

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local check_wins = {}
	for i, win in ipairs(wins) do
		check_wins[win] = i
	end

	local mods = M.get_modules()
	local mod_win
	local mod_win_valid
	local pos_to_win_valid = {}
	for position, module in pairs(mods) do
		mod_win = module and module.get_state().get_window() or constants.NOID
		mod_win_valid = M.win_valid(mod_win)
		if mod_win_valid then
			check_wins[mod_win] = nil
			pos_to_win_valid[position] = true
		end
	end

	local win_config
	local win_buf

	for win, _ in pairs(check_wins) do
		win_config = vim.api.nvim_win_get_config(win)
		win_buf = vim.api.nvim_win_get_buf(win)
		if not win_config.focusable or win_config.relative ~= '' then
			check_wins[win] = nil
		elseif constants.ui2_buffers[win_buf] then
			check_wins[win] = nil
		end
	end

	local min = next(check_wins)

	if min == nil then
		local buf_id = check_or_make_main_buf()
		local win_opts = get_split_opts(pos_to_win_valid)
		state.wins.main = vim.api.nvim_open_win(buf_id, true, win_opts)
		require('nvim-ideify.ui').reset()
		return
	end

	for win, i in pairs(check_wins) do
		if i < check_wins[min] then
			min = win
		end
	end
	state.wins.main = min
end

function M.delete_buf(id)
	if M.buf_valid(id) then
		vim.api.nvim_buf_delete(id, { force = true, })
	end
end

function M.close_win(id)
	if M.win_valid(id) then
		vim.api.nvim_win_close(id, true)
	end
end

return M
