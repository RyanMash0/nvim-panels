local M = {}

local config = require('nvim-ideify.config')
local constants = require('nvim-ideify.constants')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')

---
---@return fun(): string
local function get_on_click()
	return function()
		local win = vim.fn.getmousepos().winid
		local mod_state
		local on_click
		local check_win
		for _, position in ipairs(config.options.split_order) do
			mod_state = utils.get_state_by_position(position)
			on_click = mod_state and mod_state.get_on_click()
			check_win = mod_state and mod_state.get_window() == win
			if check_win and on_click then
				on_click()
				break
			elseif check_win and not on_click then
				break
			end
		end

		return '<LeftMouse>'
	end
end

---
---@param tree nvim-ideify.winlayout.branch | nvim-ideify.winlayout.leaf
---@return nvim-ideify.winlayout.leaf
local function leftmost_leaf(tree)
	local leaf = tree
	while leaf[1] ~= constants.winlayout_type.LEAF do
		leaf = leaf[2][1]
	end
	---@cast leaf nvim-ideify.winlayout.leaf
	return leaf
end

---
---@param forest (nvim-ideify.winlayout.branch | nvim-ideify.winlayout.leaf)[]
---@param parents nvim-ideify.winlayout.parent[]
---@param depth integer
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

			if tree[1] == constants.winlayout_type.ROW then
				win_config.split = constants.split.RIGHT
			else
				win_config.split = constants.split.BELOW
			end

			if win_config.height then
				win_config.height = math.floor(win_config.height * state.height_ratio)
			end
			if win_config.width then
				win_config.width = math.floor(win_config.width * state.width_ratio)
			end

			win_buf = vim.api.nvim_win_get_buf(leaf[2])

			if win_config.focusable then
				table.insert(state.editor_wins[depth], {
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
		state.editor_wins[depth + 1] = {}
		add_windows(new_forest, new_parents, depth + 1)
	end
end

---
local function parse_layout()
	local win_tree = vim.fn.winlayout()
	if not win_tree[1] then
		vim.notify('No windows', vim.log.levels.ERROR)
		return
	end
	---@cast win_tree nvim-ideify.winlayout.branch | nvim-ideify.winlayout.leaf
	local root_leaf = leftmost_leaf(win_tree)
	state.wins.main = root_leaf[2]
	state.editor_wins = {}

	if win_tree == root_leaf then return end
	local pos = constants.position
	local sizes = {}
	local panel
	local module
	for _, position in ipairs(config.options.split_order) do
		panel = utils.get_panel_by_position(position)
		module = panel.module()
		sizes[position] = module and not panel.hidden and panel.width or 0
	end

	local layout_width = sizes[pos.LEFT] + sizes[pos.RIGHT]
	local layout_height = sizes[pos.TOP] + sizes[pos.BOTTOM]
	state.width_ratio = (vim.o.columns - layout_width) / vim.o.columns
	state.height_ratio = (vim.o.lines - layout_height) / vim.o.lines

	local initial_entry = {
		parent = nil,
		config = nil,
		buffer = nil,
		id = state.wins.main,
	}
	state.editor_wins = { { initial_entry } }
	add_windows({ win_tree }, { { 1, 1, root_leaf } }, 1)
end

---
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

---
---@param win nvim-ideify.editor_win
---@return nvim-ideify.editor_win
local function get_parent(win)
	return state.editor_wins[win.parent[1]][win.parent[2]]
end

---
local function open_wins()
	local win
	local win_id
	local parent
	local prev_win
	local prev_parent
	utils.check_or_make_main_win()
	vim.api.nvim_set_current_win(state.wins.main)
	if #state.editor_wins == 0 then return end

	for j = 2, #state.editor_wins[1] do
		win = state.editor_wins[1][j]
		win_id = vim.api.nvim_open_win(win.buffer, true, win.config)
		win.id = win_id
	end

	for i = 2, #state.editor_wins do
		win = state.editor_wins[i][1]
		parent = get_parent(win)
		vim.api.nvim_set_current_win(parent.id)
		win_id = vim.api.nvim_open_win(win.buffer, true, win.config)
		win.id = win_id
		for j = 2, #state.editor_wins[i] do
			prev_win = state.editor_wins[i][j - 1]
			prev_parent = get_parent(prev_win)
			win = state.editor_wins[i][j]
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

---
---@param mod_constants nvim-ideify.module.constants
---@return nvim-ideify.buf_config
local function get_module_buf_config(mod_constants)
	return vim.deepcopy(mod_constants.config.buffer)
end

---
---@param mod_constants nvim-ideify.module.constants
---@param position nvim-ideify.position
---@param panel nvim-ideify.panel
---@return nvim-ideify.win_config
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

---
---@param position nvim-ideify.position
local function open_panel(position)
	local panel = utils.get_panel_by_position(position)
	local module = panel.module()
	if panel.hidden or not module then
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

---
---@param position nvim-ideify.position
local function close_panel(position)
	local panel = utils.get_panel_by_position(position)
	if not panel.module() then
		return
	end

	local panel_state = panel.module().get_state()
	utils.close_win(panel_state.get_window())
	utils.delete_buf(panel_state.get_buffer())
	panel_state.set_window(constants.NOID)
	panel_state.set_buffer(constants.NOID)
end

---
---@param position nvim-ideify.position
local function show_panel(position)
	local panel = utils.get_panel_by_position(position)
	local module = panel.module()
	if panel.hidden or not module then
		return
	end

	local mod_conf = module.get_config()
	local mod_constants = module.get_constants()
	local mod_state = module.get_state()
	local mod_ui = module.get_ui()

	local win_conf = get_module_win_config(mod_constants, position, panel)

	local buf = mod_state.get_buffer()
	if not utils.buf_valid(buf) then return end

	local win = vim.api.nvim_open_win(buf, false, win_conf)
	mod_state.set_window(win)

	local win_opts = mod_conf.options.window
	utils.set_opts(constants.type.WIN, win, win_opts)

	mod_ui.render()
end

---
---@param position nvim-ideify.position
local function hide_panel(position)
	local panel = utils.get_panel_by_position(position)
	if not panel.module() then
		return
	end

	local panel_state = panel.module().get_state()
	utils.close_win(panel_state.get_window())
	panel_state.set_window(constants.NOID)
end

---
function M.open()
	M.close()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()
	close_wins()

	for _, position in ipairs(config.options.split_order) do
		open_panel(position)
	end

	local key_opts = { expr = true, remap = false }
	vim.keymap.set('n', '<LeftMouse>', get_on_click(), key_opts)

	open_wins()
	state.active = true
	state.opened = true
end

---
function M.close()
	utils.check_or_make_main_win()

	state.active = false
	state.opened = false

	for _, position in ipairs(config.options.split_order) do
		close_panel(position)
	end

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

---
function M.show()
	if not state.opened then
		return M.open()
	end

	M.hide()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()
	close_wins()

	for _, position in ipairs(config.options.split_order) do
		show_panel(position)
	end

	local key_opts = { expr = true, remap = false }
	vim.keymap.set('n', '<LeftMouse>', get_on_click(), key_opts)

	open_wins()
	state.active = true
end

---
function M.hide()
	utils.check_or_make_main_win()

	state.active = false

	for _, position in ipairs(config.options.split_order) do
		hide_panel(position)
	end

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

---
function M.toggle()
	if state.active then M.hide()
	else M.show() end
end

---
function M.reset()
	if state.active then M.show() end
end

---
function M.hard_reset()
	if not state.opened then return end
	if state.active then M.open()
	else M.close() end
end

---
---@param position nvim-ideify.position
function M.module_buf_reload(position)
	local module = utils.get_module_by_position(position)
	if not module then return end

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

return M
