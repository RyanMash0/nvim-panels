local M = {}
local config = require('nvim-ideify.config')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')
local pos = require('nvim-ideify.position')

local modules = utils.get_modules()
local left = modules.left
local right = modules.right
local top = modules.top
local bottom = modules.bottom

M.windows = {}
M.height_ratio = 1
M.width_ratio = 1

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
					id = -1,
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
	local l_width = config.options.layout.left.width
	local r_width = config.options.layout.right.width
	local t_height = config.options.layout.top.height
	local b_height = config.options.layout.bottom.height

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

local function get_panel_from_direction(direction)
	if direction == pos.left then return config.options.layout.left
	elseif direction == pos.right then return config.options.layout.right
	elseif direction == pos.top then return config.options.layout.top
	elseif direction == pos.bottom then return config.options.layout.bottom end
end

local function close_panel(module)
	if not module then return end

	utils.close_win(module:get_state():get_window())
	utils.delete_buf(module:get_state():get_buffer())
	module:get_state():set_window(-1)
	module:get_state():set_buffer(-1)
end

local function hide_panel(module)
	if not module then return end

	-- if utils.win_valid(module:get_state():get_window()) then
	-- 	module:get_state():set_win_config(
	-- 		vim.api.nvim_win_get_config(module:get_state():get_window())
	-- 	)
	-- end

	utils.close_win(module:get_state():get_window())
	module:get_state():set_window(-1)
end

local function open_panel(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module() then return end

	local listed = panel.module():get_config().options.buffer.listed
	local scratch = panel.module():get_config().options.buffer.scratch
	local buf = vim.api.nvim_create_buf(listed, scratch)

	panel.module():get_state():set_buffer(buf)

	local opts = panel.module():get_config().options.window.start_opts
	opts.split = direction
	if direction == pos.left or direction == pos.right then
		opts.vertical = true
		opts.width = panel.width
	else
		opts.height = panel.height
	end

	panel.module():get_state():set_win_config(opts)

	local win = vim.api.nvim_open_win(buf, false, opts)
	panel.module():get_state():set_window(win)

	panel.module():get_ui().render()

	panel.module():get_keymaps().setup()

	local buf_opts = panel.module():get_config().options.buffer.opts
	for key, val in pairs(buf_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', buf = buf })
	end

	local win_opts = panel.module():get_config().options.window.opts
	for key, val in pairs(win_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', win = win })
	end
end

local function unhide_panel(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module() then return end

	local opts = panel.module():get_state():get_win_config()
	local win = vim.api.nvim_open_win(panel.module():get_state():get_buffer(), false, opts)
	panel.module():get_state():set_window(win)

	local win_opts = panel.module():get_config().options.window.opts
	for key, val in pairs(win_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', win = win })
	end
end

function M.close()
	utils.check_or_make_main_win()

	state.active = false
	state.opened = false

	close_panel(left)
	close_panel(right)
	close_panel(top)
	close_panel(bottom)

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

	-- I have to do this to get it to reload for some reason
	left = config.options.layout.left.module()
	right = config.options.layout.right.module()
	top = config.options.layout.top.module()
	bottom = config.options.layout.bottom.module()

	vim.keymap.set('n', '<LeftMouse>', function()
		local win = vim.fn.getmousepos().winid
		if left and win == left:get_state():get_window() and left:get_state():get_on_click() then
			left:get_state():get_on_click()()
		elseif right and win == right:get_state():get_window() and right:get_state():get_on_click() then
			right:get_state():get_on_click()()
		elseif top and win == top:get_state():get_window() and top:get_state():get_on_click() then
			top:get_state():get_on_click()()
		elseif bottom and win == bottom:get_state():get_window() and bottom:get_state():get_on_click() then
			bottom:get_state():get_on_click()()
		end
		return '<LeftMouse>'
	end, { expr = true, remap = false })

	open_wins()
	state.active = true
	state.opened = true
end

function M.hide()
	utils.check_or_make_main_win()

	state.active = false

	hide_panel(left)
	hide_panel(right)
	hide_panel(top)
	hide_panel(bottom)

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

	-- I have to do this to get it to reload for some reason
	left = config.options.layout.left.module()
	right = config.options.layout.right.module()
	top = config.options.layout.top.module()
	bottom = config.options.layout.bottom.module()

	vim.keymap.set('n', '<LeftMouse>', function()
		local win = vim.fn.getmousepos().winid
		if left and win == left:get_state():get_window() and left:get_state():get_on_click() then
			left:get_state():get_on_click()()
		elseif right and win == right:get_state():get_window() and right:get_state():get_on_click() then
			right:get_state():get_on_click()()
		elseif top and win == top:get_state():get_window() and top:get_state():get_on_click() then
			top:get_state():get_on_click()()
		elseif bottom and win == bottom:get_state():get_window() and bottom:get_state():get_on_click() then
			bottom:get_state():get_on_click()()
		end
		return '<LeftMouse>'
	end, { expr = true, remap = false })

	open_wins()
	state.active = true
end

local function panel_size_reset(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module() then return end

	local opts
	if direction == pos.left or direction == pos.right then
		opts = { width = panel.width }
	else
		opts = { height = panel.height }
	end
	opts.split = direction

	vim.api.nvim_set_current_win(state.wins.main)
	vim.api.nvim_win_set_config(panel.module():get_state():get_window(), opts)

	panel.module():get_state():set_win_config(
		vim.api.nvim_win_get_config(panel.module():get_state():get_window())
	)
end

function M.reset()
	M.show()
	-- parse_layout()

	panel_size_reset(config.options.split_order.first)
	panel_size_reset(config.options.split_order.second)
	panel_size_reset(config.options.split_order.third)
	panel_size_reset(config.options.split_order.fourth)

	-- open_wins()
end

return M
