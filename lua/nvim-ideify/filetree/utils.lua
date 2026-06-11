local M = {}

local state = require('nvim-ideify.filetree.state')
local config = require('nvim-ideify.filetree.config')

function M.go_to_dir()
	local ui = require('nvim-ideify.filetree.ui')
	vim.ui.input({
		prompt = "Path: ",
		completion = 'file',
	}, function(input)
		if vim.fn.isdirectory(input) ~= 1 then
			vim.notify('Invalid Directory', vim.log.levels.ERROR)
			return
		end
		local path = vim.fs.abspath(input)
		ui.change_dir(path)
	end)
end

function M.unmark_subdirectories(path)
	local sources = state.fs_sources
	local target, _ = next(state.fs_target)
	local relpath = vim.fs.relpath(path, target or '')
	if relpath and relpath ~= '.' then
		state.fs_target = {}
	end

	for source, _ in pairs(sources) do
		relpath = vim.fs.relpath(path, source)
		if relpath and relpath ~= '.' then
			state.fs_sources[source] = nil
		end
	end
end

function M.get_dir_array(text, path)
	local win_id = state:get_window()
	local win_conf = vim.api.nvim_win_get_config(win_id)
	local size = win_conf.width or win_conf.height
	local spaces = ''
	for _ = 1, #text do
		spaces = spaces .. ' '
	end

	local dir_item_array = {}
	for item in string.gmatch(path, '[^/]+/') do
		table.insert(dir_item_array, item)
	end
	local dir_array = { text, }
	local i = 1
	for _, item in ipairs(dir_item_array) do
		if #dir_array[i] + #item < size then
			dir_array[i] = dir_array[i] .. item
		else
			dir_array[i + 1] = spaces .. item
			i = i + 1
		end
	end

	return dir_array
end

function M.get_target_array()
	local win_id = state:get_window()
	local target, _ = next(state.fs_target)
	local curdir = vim.fn.getcwd(win_id)
	if not target then target = './'
	else target = './' .. vim.fs.relpath(curdir, target) .. '/' end

	return M.get_dir_array(' Target: ', target)
end

function M.get_path_array()
	local path = vim.fs.abspath('.')
	local home_dir = tostring(os.getenv('HOME') or os.getenv('USERPROFILE'))
	path = path:gsub(home_dir, '~')
	if path ~= '/' then path = path .. '/' end

	return M.get_dir_array(' Path: ', path)
end

function M.get_default_header()
	local win_id = state:get_window()
	local win_conf = vim.api.nvim_win_get_config(win_id)
	local size = win_conf.width or win_conf.height
	local border = ''
	local border_char = '='
	for _ = 1, size do
		border = border .. border_char
	end
	local title_line = ' File Tree'
	local path_array = M.get_path_array()
	local target_array = M.get_target_array()
	local header = {}

	table.insert(header, border)
	table.insert(header, title_line)

	for _, item in ipairs(path_array) do
		table.insert(header, item)
	end

	for _, item in ipairs(target_array) do
		table.insert(header, item)
	end

	table.insert(header, border)

	return header
end

function M.get_full_header()
	local header = config.options.header() or M.get_default_header()

	if config.options.show_keymaps then
		for _, line in pairs(config.options.keymaps) do
			table.insert(header, line)
		end
	end

	state:set_header_height(#header)
	return header
end

function M.fs_rename()
	local ui = require('nvim-ideify.filetree.ui')
	local line = vim.fn.line('.')
	local entry = state.tree[line]
	local path = entry.path
	local dirname = vim.fs.dirname(path) .. '/'
	local basename = vim.fs.basename(path)
	vim.ui.input(
		{prompt = 'Rename ' .. basename .. ' to: ',},
		function(input)
			if input == nil then input = basename end

			local new_name = dirname .. input
			local mv_str = 'mv ' .. '"' .. path .. '" "' .. new_name .. '"'
			vim.fn.system(mv_str)
			if entry.type == 'directory' then
				local expanded = state.expanded
				local tmp
				for p, _ in pairs(expanded) do
					tmp = p
					expanded[p] = nil
					tmp = vim.fs.relpath(path, p or '')
					if tmp and tmp == '.' then
						p = new_name
					elseif tmp and tmp ~= '.' then
						p = new_name .. '/' .. tmp
					end
				end
			end
			ui.render()
		end
	)
end

function M.fs_delete()
	local ui = require('nvim-ideify.filetree.ui')
	local line = vim.fn.line('.')
	local parent = state.tree[line]
	local path = parent.path
	local curdir = vim.fn.getcwd()
	local relpath = vim.fs.relpath(curdir, path)
	local is_dir = parent.type == 'directory'
	local recur = is_dir and 'RECURSIVE ' or ''
	local trash_path = '~/.local/share/Trash/nvim-ideify'
	local mkdir = 'mkdir -p ' .. trash_path .. ' && '
	relpath = is_dir and relpath .. '/' or relpath
	local red = vim.api.nvim_get_hl_id_by_name('Red')
	vim.ui.input(
		{
			prompt = 'Confirm ' .. recur .. 'deletion of <' .. relpath .. '> ([Y]es, [n]o): ',
		},
		function(input)
			if input == nil then input = 'n'
			elseif input == '' then input = 'y'
			else input = input:sub(1, 1):lower() end

			if input ~= 'y' and input ~= 'n' then
				vim.notify('Invalid input', vim.log.levels.ERROR)
				return
			end

			local rm_str = mkdir .. 'mv ' .. '"' .. path .. '" ' .. trash_path
			if input == 'y' then
				vim.fn.system(rm_str)

				local esc = vim.keycode('<Esc>')
				vim.api.nvim_feedkeys(esc, 'n', false)
				ui.render()
				vim.notify('Item successfully moved to ~/.local/share/Trash/nvim-ideify', vim.log.levels.INFO)
			end
		end
	)
end

function M.fs_delete_visual()
	local ui = require('nvim-ideify.filetree.ui')
	local start_line = vim.fn.line('v')
	local end_line = vim.fn.line('.')
	if start_line == end_line then return M.fs_delete() end
	local parents = {}
	local curdir = vim.fn.getcwd()
	local relpaths = {}
	local relpath
	local is_dir = {}
	local trash_path = '~/.local/share/Trash/nvim-ideify'
	local mkdir = 'mkdir -p ' .. trash_path .. ' && '
	for i = start_line, end_line do
		table.insert(parents, i, state.tree[i])
		table.insert(is_dir, i, parents[i].type == 'directory')
		relpath = vim.fs.relpath(curdir, parents[i].path)
		relpath = is_dir[i] and relpath .. '/' or relpath
		table.insert(relpaths, i, relpath)
	end

	local function file_delete_multi(start_idx, end_idx)
		local rm_str
		for i = start_idx, end_idx do
			rm_str = mkdir .. 'mv ' .. '"' .. parents[i].path .. '" ' .. trash_path
			vim.fn.system(rm_str)
		end
	end

	local stop = false
	for i = start_line, end_line do
		if stop then break end
		vim.ui.input(
			{
				prompt = 'Confirm (RECURSIVE) deletion of <' .. relpaths[i] .. '> ([Y]es, [n]o, [a]ll): ',
			},
			function(input)
				if input == nil then input = 'n'
				elseif input == '' then input = 'y'
				else input = input:sub(1, 1):lower() end

				if input ~= 'y' and input ~= 'n' and input ~= 'a' then
					vim.notify('Invalid input', vim.log.levels.ERROR)
					return
				end

			local rm_str = mkdir .. 'mv ' .. '"' .. parents[i].path .. '" ' .. trash_path
				if input == 'y' then
					vim.fn.system(rm_str)
				elseif input == 'a' then
					file_delete_multi(i, end_line)
					stop = true
				end
			end
		)
	end

	local esc = vim.keycode('<Esc>')
	vim.api.nvim_feedkeys(esc, 'n', false)
	ui.render()
	vim.notify('Item successfully moved to ~/.local/share/Trash/nvim-ideify', vim.log.levels.INFO)
end

function M.mark_target()
	local ui = require('nvim-ideify.filetree.ui')
	local line = vim.fn.line('.')
	local parent = state.tree[line]
	local path = parent.path
	if parent.type ~= 'directory' then return end

	if state.fs_target[path] then
		state.fs_target[path] = nil
	else
		state.fs_target = {}
		state.fs_target[path] = true
	end

	if state.fs_sources[path] then state.fs_sources[path] = nil end

	ui.render()
end

function M.mark_source()
	local ui = require('nvim-ideify.filetree.ui')
	local line = vim.fn.line('.')
	local parent = state.tree[line]
	local path = parent.path

	if state.fs_sources[path] then state.fs_sources[path] = nil
	else state.fs_sources[path] = true end

	if state.fs_target[path] then state.fs_target[path] = nil end

	ui.render()
end

function M.fs_move()
	local ui = require('nvim-ideify.filetree.ui')
	local sources = state.fs_sources
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()
	local mv_str
	for source, _ in pairs(sources) do
			mv_str = 'mv ' .. '"' .. source .. '" "' .. target .. '"'
			vim.fn.system(mv_str)
	end
	state.fs_sources = {}
	state.fs_target = {}
	ui.render()
end

function M.fs_copy()
	local ui = require('nvim-ideify.filetree.ui')
	local sources = state.fs_sources
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()
	local cp_str
	for source, _ in pairs(sources) do
			cp_str = 'cp -r ' .. '"' .. source .. '" "' .. target .. '"'
			vim.fn.system(cp_str)
	end
	state.fs_sources = {}
	state.fs_target = {}
	ui.render()
end

function M.file_new()
	local ui = require('nvim-ideify.filetree.ui')
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()

	vim.ui.input(
		{prompt = 'File name: ',},
		function(input)
			if input == nil or input == '' then return end
			local new_file_str = 'touch ' .. '"' .. target .. '/' .. input .. '"'
			vim.fn.system(new_file_str)
			state.fs_target = {}
			ui.render()
		end
	)
end

function M.dir_new()
	local ui = require('nvim-ideify.filetree.ui')
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()

	vim.ui.input(
		{prompt = 'Directory name: ',},
		function(input)
			if input == nil or input == '' then return end
			local new_file_str = 'mkdir ' .. '"' .. target .. '/' .. input .. '"'
			vim.fn.system(new_file_str)
			state.fs_target = {}
			ui.render()
		end
	)
end

function M.open_subdirectories()
	local ui = require('nvim-ideify.filetree.ui')
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()
	local dir_iterator = vim.fs.dir(target, { type = 'directory' })
	local entry_path
	state.expanded[target] = true
	for path, type in dir_iterator do
		if type == 'directory' then
			entry_path = target .. '/' .. path
			state.expanded[entry_path] = true
		end
	end

	state.fs_target = {}
	ui.render()
end

function M.close_subdirectories()
	local ui = require('nvim-ideify.filetree.ui')
	local target, _ = next(state.fs_target)
	target = target or vim.fn.getcwd()
	local relpath

	for path, _ in pairs(state.expanded) do
		relpath = vim.fs.relpath(target, path)
		if relpath and relpath ~= '.' then
			state.expanded[path] = nil
		end
	end

	M.unmark_subdirectories(target)
	state.fs_target = {}
	ui.render()
end

return M
