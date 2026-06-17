local M = {}

local config = require('nvim-ideify.config')
local constants = require('nvim-ideify.constants')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')

M.windows = {}
M.height_ratio = 1
M.width_ratio = 1

local function get_on_click()
	return function()
		local win = vim.fn.getmousepos().winid

		local left = config.options.layout.left.module()
		local right = config.options.layout.right.module()
		local top = config.options.layout.top.module()
		local bottom = config.options.layout.bottom.module()
		local l_state = left and left.get_state()
		local r_state = right and right.get_state()
		local t_state = top and top.get_state()
		local b_state = bottom and bottom.get_state()
		local win_left = l_state and win == l_state.get_window()
		local win_right = r_state and win == r_state.get_window()
		local win_top = t_state and win == t_state.get_window()
		local win_bottom = b_state and win == b_state.get_window()
		local click_left = l_state and l_state.get_on_click()
		local click_right = r_state and r_state.get_on_click()
		local click_top = t_state and t_state.get_on_click()
		local click_bottom = b_state and b_state.get_on_click()

		if win_left and click_left then
			click_left()
		elseif win_right and click_right then
			click_right()
		elseif win_top and click_top then
			click_top()
		elseif win_bottom and click_bottom then
			click_bottom()
		end
		return '<LeftMouse>'
	end
end

local function leftmost_leaf(tree)
	local leaf = tree
	while leaf[1] ~= 'leaf' do
		leaf = leaf[2][1]
	end
	return leaf
end

local function add_windows(forest, parents, depth)
	local new_forest = {}
	local new_parents = {}
	local tree
	local subtree
	local leaf
	local win_config
	local win_buf

	for i = 1, #forest do
		tree = forest[i]
		subtree = tree[2][1]
		leaf = parents[i][3]
		if subtree ~= leaf then
			table.insert(new_forest, subtree)
			table.insert(new_parents, parents[i])
		end

		for j = 2, #tree[2] do
			subtree = tree[2][j]
			leaf = leftmost_leaf(subtree)
			win_config = vim.api.nvim_win_get_config(leaf[2])

			if tree[1] == 'row' then
				win_config.split = 'right'
			else
				win_config.split = 'below'
			end

			if win_config.height then
				win_config.height = math.floor(win_config.height * M.height_ratio)
			end
			if win_config.width then
				win_config.width = math.floor(win_config.width * M.width_ratio)
			end

			win_buf = vim.api.nvim_win_get_buf(leaf[2])

			if win_config.focusable then
				table.insert(M.windows[depth], {
					parent = parents[i],
					config = win_config,
					buffer = win_buf,
					id = constants.NOID,
				})

				if subtree ~= leaf then
					table.insert(new_forest, subtree)
					table.insert(new_parents, { depth, j, leaf })
				end
			end
		end
	end

	if #new_forest > 0 then
		M.windows[depth + 1] = {}
		add_windows(new_forest, new_parents, depth + 1)
	end
end

local function parse_layout()
	local win_tree = vim.fn.winlayout()
	local root_leaf = leftmost_leaf(win_tree)
	state.wins.main = root_leaf[2]
	M.windows = {}

	if win_tree == root_leaf then return end
	local left = config.options.layout.left
	local right = config.options.layout.right
	local top = config.options.layout.top
	local bottom = config.options.layout.bottom
	local l_vis = left.module() and not left.hidden
	local r_vis = right.module() and not right.hidden
	local t_vis = top.module() and not top.hidden
	local b_vis = bottom.module() and not bottom.hidden

	local l_width = l_vis and left.width or 0
	local r_width = r_vis and right.width or 0
	local t_height = t_vis and top.height or 0
	local b_height = b_vis and bottom.height or 0

	local width_reduction = l_width + r_width
	local height_reduction = t_height + b_height
	M.width_ratio = (vim.o.columns - width_reduction) / vim.o.columns
	M.height_ratio = (vim.o.lines - height_reduction) / vim.o.lines

	local initial_entry = {
		parent = nil,
		config = nil,
		buffer = nil,
		id = state.wins.main,
	}
	M.windows = { { initial_entry } }
	add_windows({ win_tree }, { { 1, 1, root_leaf } }, 1)
end

local function close_wins()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	local win_config

	vim.api.nvim_set_current_win(state.wins.main)
	utils.check_or_make_main_win()

	for _, win in ipairs(wins) do
		win_config = vim.api.nvim_win_get_config(win)
		if win ~= state.wins.main and win_config.focusable then
			vim.api.nvim_win_hide(win)
		end
	end
end

local function get_parent(win)
	return M.windows[win.parent[1]][win.parent[2]]
end

local function open_wins()
	local win
	local win_id
	local parent
	local prev_win
	local prev_parent
	utils.check_or_make_main_win()
	vim.api.nvim_set_current_win(state.wins.main)
	if #M.windows == 0 then return end

	for j = 2, #M.windows[1] do
		win = M.windows[1][j]
		win_id = vim.api.nvim_open_win(win.buffer, true, win.config)
		win.id = win_id
	end

	for i = 2, #M.windows do
		win = M.windows[i][1]
		parent = get_parent(win)
		vim.api.nvim_set_current_win(parent.id)
		win_id = vim.api.nvim_open_win(win.buffer, true, win.config)
		win.id = win_id
		for j = 2, #M.windows[i] do
			prev_win = M.windows[i][j - 1]
			prev_parent = get_parent(prev_win)
			win = M.windows[i][j]
			parent = get_parent(win)
			if parent.id ~= prev_parent.id then
				vim.api.nvim_set_current_win(parent.id)
			end

			win_id = vim.api.nvim_open_win(win.buffer, true, win.config)
			win.id = win_id
			vim.api.nvim_win_set_config(prev_win.id, prev_win.config)
		end
		vim.api.nvim_set_current_win(state.wins.main)
	end
end

local function get_panel_from_position(position)
	local split = constants.position

	if position == split.LEFT then
		return config.options.layout.left
	elseif position == split.RIGHT then
		return config.options.layout.right
	elseif position == split.TOP then
		return config.options.layout.top
	elseif position == split.BOTTOM then
		return config.options.layout.bottom end
end

local function close_panel(position)
	local panel = get_panel_from_position(position)
	if not panel.module() then
		return
	end

	local panel_state = panel.module().get_state()
	utils.close_win(panel_state.get_window())
	utils.delete_buf(panel_state.get_buffer())
	panel_state.set_window(constants.NOID)
	panel_state.set_buffer(constants.NOID)
end

local function hide_panel(position)
	local panel = get_panel_from_position(position)
	if not panel.module() then
		return
	end

	local panel_state = panel.module().get_state()
	utils.close_win(panel_state.get_window())
	panel_state.set_window(constants.NOID)
end

local function get_module_buf_config(mod_constants)
	return vim.deepcopy(mod_constants.config.buffer)
end

local function get_module_win_config(mod_constants, position, panel)
	local pos = constants.position
	local win_conf = vim.deepcopy(mod_constants.config.window)
	win_conf.split = utils.position_to_split(position)
	if position == pos.LEFT or position == pos.RIGHT then
		win_conf.vertical = true
		win_conf.width = panel.width
	else
		win_conf.height = panel.height
	end
	return win_conf
end

local function open_panel(position)
	local panel = get_panel_from_position(position)
	local panel_g_conf = config.options.layout[position]
	local module = panel.module()
	if not module or panel_g_conf and panel_g_conf.hidden then
		return
	end

	local mod_conf = module.get_config()
	local mod_constants = module.get_constants()
	local mod_keys = module.get_keymaps()
	local mod_state = module.get_state()
	local mod_ui = module.get_ui()

	local buf_conf = get_module_buf_config(mod_constants)
	local win_conf = get_module_win_config(mod_constants, position, panel)

	local buf = vim.api.nvim_create_buf(buf_conf.listed, buf_conf.scratch)
	mod_state.set_buffer(buf)

	local win = vim.api.nvim_open_win(buf, false, win_conf)
	mod_state.set_window(win)

	local buf_opts = mod_conf.options.buffer
	utils.set_opts(constants.type.BUF, buf, buf_opts)

	local win_opts = mod_conf.options.window
	utils.set_opts(constants.type.WIN, win, win_opts)

	mod_ui.render()
	mod_keys.setup()
end

local function unhide_panel(position)
	local panel = get_panel_from_position(position)
	local panel_g_conf = config.options.layout[position]
	local module = panel.module()
	if not module or (panel_g_conf and panel_g_conf.hidden) then
		return
	end

	local mod_conf = module.get_config()
	local mod_constants = module.get_constants()
	local mod_state = module.get_state()

	local win_conf = get_module_win_config(mod_constants, position, panel)

	local buf = mod_state.get_buffer()
	if not utils.buf_valid(buf) then return end

	local win = vim.api.nvim_open_win(buf, false, win_conf)
	mod_state.set_window(win)

	local win_opts = mod_conf.options.window
	utils.set_opts(constants.type.WIN, win, win_opts)
end

function M.close()
	utils.check_or_make_main_win()

	state.active = false
	state.opened = false

	close_panel(config.options.split_order.first)
	close_panel(config.options.split_order.second)
	close_panel(config.options.split_order.third)
	close_panel(config.options.split_order.fourth)

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

function M.open()
	M.close()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()
	close_wins()

	open_panel(config.options.split_order.first)
	open_panel(config.options.split_order.second)
	open_panel(config.options.split_order.third)
	open_panel(config.options.split_order.fourth)

	local key_opts = { expr = true, remap = false }
	vim.keymap.set('n', '<LeftMouse>', get_on_click(), key_opts)

	open_wins()
	state.active = true
	state.opened = true
end

function M.hide()
	utils.check_or_make_main_win()

	state.active = false

	hide_panel(config.options.split_order.first)
	hide_panel(config.options.split_order.second)
	hide_panel(config.options.split_order.third)
	hide_panel(config.options.split_order.fourth)

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

function M.show()
	if not state.opened then
		M.open()
	end

	M.hide()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()
	close_wins()

	unhide_panel(config.options.split_order.first)
	unhide_panel(config.options.split_order.second)
	unhide_panel(config.options.split_order.third)
	unhide_panel(config.options.split_order.fourth)

	local key_opts = { expr = true, remap = false }
	vim.keymap.set('n', '<LeftMouse>', get_on_click(), key_opts)

	open_wins()
	state.active = true
end

function M.module_buf_reload(module)
	local mod_conf = module.get_config()
	local mod_constants = module.get_constants()
	local mod_keys = module.get_keymaps()
	local mod_state = module.get_state()
	local mod_ui = module.get_ui()

	local buf_conf = vim.deepcopy(mod_constants.config.buffer)
	local buf = vim.api.nvim_create_buf(buf_conf.listed, buf_conf.scratch)
	local win = mod_state.get_window()
	local buf_old = vim.api.nvim_win_get_buf(win)

	vim.wo[win].winfixbuf = false
	vim.api.nvim_win_set_buf(win, buf)
	vim.wo[win].winfixbuf = true

	mod_state.set_buffer(buf)
	if utils.buf_valid(buf_old) then
		vim.api.nvim_buf_delete(buf_old, { force = true })
	end

	local buf_opts = mod_conf.options.buffer
	utils.set_opts(constants.type.BUF, buf, buf_opts)

	local win_opts = mod_conf.options.window
	utils.set_opts(constants.type.WIN, win, win_opts)

	mod_ui.render()
	mod_keys.setup()
end

local function panel_size_reset(position)
	local panel = get_panel_from_position(position)
	local panel_g_conf = config.options.layout[position]
	local module = panel.module()
	if not module or panel_g_conf and panel_g_conf.hidden then
		return
	end

	local mod_constants = module.get_constants()
	local mod_state = module.get_state()
	local mod_win = mod_state.get_window()

	if not utils.win_valid(mod_win) then
		open_panel(position)
		return
	end

	local win_conf = get_module_win_config(mod_constants, position, panel)

	vim.api.nvim_win_set_config(mod_win, win_conf)
	utils.check_or_make_main_win()
	vim.api.nvim_set_current_win(state.wins.main)
end

function M.reset()
	if not state.active then return end
	M.show()

	panel_size_reset(config.options.split_order.first)
	panel_size_reset(config.options.split_order.second)
	panel_size_reset(config.options.split_order.third)
	panel_size_reset(config.options.split_order.fourth)
end

return M
