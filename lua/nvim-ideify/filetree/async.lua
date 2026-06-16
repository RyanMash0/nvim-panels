local M = {}

local g_config = require('nvim-ideify.config')

function M.new_log()
	local data = {}
	return {
		add_data = function(new_data)
			table.insert(data, new_data)
		end,
		get_data = function()
			return data
		end,
	}
end

function M.new_verifier()
	local data = {}
	return {
		add_data = function(item)
			data[item] = true
		end,
		verify = function(item)
			return data[item]
		end,
	}
end

function M.new_process_counter(co, log, extra_log)
	local count = 0
	return {
		increment = function()
			count = count + 1
		end,
		decrement = function()
			count = count - 1
			if count == 0 then
				vim.schedule(function()
					coroutine.resume(
						co,
						log.get_data(),
						extra_log and extra_log.get_data()
					)
				end)
			end
		end,
		get = function()
			return count
		end,
	}
end

function M.await_stat(path)
	local co = coroutine.running()
	vim.uv.fs_stat(path, function(err, stat)
		if err or not stat then
			vim.schedule(function() coroutine.resume(co, false) end)
			return
		end

		vim.schedule(function() coroutine.resume(co, true) end)
	end)
	return coroutine.yield()
end

function M.await_unique_path(path, path_verifier)
	local new_path = path
	local base_name = vim.fs.basename(path)
	local dir_name = vim.fs.dirname(path)
	local item_name = base_name:match('^%.*[^%.]*')
	local prefix = vim.fs.joinpath(dir_name, item_name)
	local suffix = base_name:gsub('^%.*[^%.]*', '')
	local identifier
	local count = 1
	while M.await_stat(new_path) or
		path_verifier and path_verifier.verify(new_path) do
		count = count + 1
		identifier = ' (' .. tostring(count) .. ')'
		new_path = prefix .. identifier .. suffix
	end

	if path_verifier then
		path_verifier.add_data(new_path)
	end

	return new_path
end

function M.await_get_items_recursive(start_path, start_new_path, err_log)
	local co = coroutine.running()
	local count = M.new_process_counter(co, err_log)

	local dirs = {}
	local files = {}

	local function scan_dir(path, new_path)
		table.insert(dirs, {})
		local cur = #dirs
		local new_subpath
		local subpath
		local dir_iterator

		count.increment()
		vim.uv.fs_scandir(path, function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = false, path = path })
				count.decrement()
				return
			end

			dir_iterator = function()
				return vim.uv.fs_scandir_next(success)
			end

			for name, type in dir_iterator do
				subpath = vim.fs.joinpath(path, name)
				new_subpath = vim.fs.joinpath(new_path, name)
				if type == 'directory' then
					table.insert(dirs[cur], { subpath, new_subpath })
				elseif type == 'file' or type == 'link' then
					table.insert(files, { subpath, new_subpath })
				end
			end

			for _, dir in ipairs(dirs[cur]) do
				scan_dir(dir[1], dir[2])
			end

			count.decrement()
		end)
	end

	scan_dir(start_path, start_new_path)

	if count.get() > 0 then
		coroutine.yield()
	end

	return dirs, files
end

function M.await_mkdir_multi(dirs, err_log, path_log, log_new_paths)
	local co = coroutine.running()
	local count = M.new_process_counter(co, err_log, path_log)
	local permissions = g_config.options.permissions
	for _, dir in ipairs(dirs) do
		count.increment()
		vim.uv.fs_mkdir(dir[2], permissions.directory, function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = dir[2] })
			elseif log_new_paths then
				path_log.add_data(dir)
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then
		return err_log.get_data(), path_log.get_data()
	end
	return coroutine.yield()
end

function M.await_copy_multi(files, err_log, path_log, log_new_paths)
	local co = coroutine.running()
	local count = M.new_process_counter(co, err_log, path_log)
	for _, file in ipairs(files) do
		count.increment()
		vim.uv.fs_copyfile(file[1], file[2], {}, function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = file[1] })
			elseif log_new_paths then
				path_log.add_data(file)
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then
		return err_log.get_data(), path_log.get_data()
	end
	return coroutine.yield()
end

function M.await_copy_recursive(path, target)
	local stat, err = vim.uv.fs_stat(path)
	if err or not stat then return { { err = err, success = false } }, {} end

	local err_log = M.new_log()
	local path_log = M.new_log()
	local basename = vim.fs.basename(path)
	local new_path = vim.fs.joinpath(target, basename)
	new_path = M.await_unique_path(new_path)
	if stat.type == 'file' or stat.type == 'link' then
		return M.await_copy_multi({ { path, new_path, } }, err_log, path_log, true)
	end

	local tmp_err_log, tmp_path_log = M.await_mkdir_multi(
		{ { path, new_path } }, err_log, path_log, true
	)

	if #tmp_err_log > 0 then return tmp_err_log, tmp_path_log end

	local dirs, files = M.await_get_items_recursive(path, new_path, err_log)
	for _, dir_table in ipairs(dirs) do
		M.await_mkdir_multi(dir_table, err_log, path_log, false)
	end

	return M.await_copy_multi(files, err_log, path_log, false)
end

function M.await_create_file(path)
	local co = coroutine.running()
	local permissions = g_config.options.permissions
	vim.uv.fs_open(path, 'wx', permissions.file, function(open_err, fd)
		if open_err or not fd then
			vim.schedule(function() coroutine.resume(co, open_err, false) end)
			return
		end

		vim.uv.fs_close(fd, function(close_err, success)
			vim.schedule(function() coroutine.resume(co, close_err, success) end)
		end)
	end)

	return coroutine.yield()
end

function M.await_mkdir(path)
	local co = coroutine.running()
	local permissions = g_config.options.permissions
	vim.uv.fs_mkdir(path, permissions.directory, function(err, success)
		vim.schedule(function() coroutine.resume(co, err, success) end)
	end)

	return coroutine.yield()
end

function M.await_move_multi(items)
	local co = coroutine.running()
	local err_log = M.new_log()
	local path_log = M.new_log()
	local path_verifier = M.new_verifier()
	local count = M.new_process_counter(co, err_log, path_log)

	for _, item in ipairs(items) do
		item[2] = M.await_unique_path(item[2], path_verifier)
		count.increment()
		vim.uv.fs_rename(item[1], item[2], function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = item[1] })
			else
				path_log.add_data(item)
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then return {}, {} end
	return coroutine.yield()
end

return M
