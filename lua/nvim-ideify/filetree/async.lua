local M = {}

function M.new_error_log()
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

function M.new_process_counter(co, err_log)
	local count = 0
	return {
		increment = function()
			count = count + 1
		end,
		decrement = function()
			count = count - 1
			if count == 0 then
				vim.schedule(function() coroutine.resume(co, err_log.get_data()) end)
			end
		end,
		get = function()
			return count
		end,
	}
end

function M.await_get_items_recursive(start_path, start_target)
	local co = coroutine.running()
	local err_log = M.new_error_log()
	local count = M.new_process_counter(co, err_log)

	local dirs = {}
	local files = {}

	local function scan_dir(path, target)
		local basename = vim.fs.basename(path)
		local new_path = vim.fs.joinpath(target, basename)

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
				scan_dir(dir[1], new_path)
			end

			count.decrement()
		end)

	end

	scan_dir(start_path, start_target)

	if count.get() > 0 then
		coroutine.yield()
	end

	return dirs, files
end

function M.await_mkdir_multi(dirs)
	local co = coroutine.running()
	local err_log = M.new_error_log()
	local count = M.new_process_counter(co, err_log)
	for _, dir in ipairs(dirs) do
		count.increment()
		vim.uv.fs_mkdir(dir[2], tonumber('755', 8), function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = dir[2] })
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then return {} end
	return coroutine.yield()
end

function M.await_copy_multi(files)
	local co = coroutine.running()
	local err_log = M.new_error_log()
	local count = M.new_process_counter(co, err_log)
	for _, file in ipairs(files) do
		count.increment()
		vim.uv.fs_copyfile(file[1], file[2], {}, function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = file[1] })
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then return {} end
	return coroutine.yield()
end

function M.await_copy_recursive(path, target)
	local stat, err = vim.uv.fs_stat(path)
	if err or not stat then return end

	local err_logs = {}
	local basename = vim.fs.basename(path)
	local new_path = vim.fs.joinpath(target, basename)
	if stat.type == 'file' or stat.type == 'link' then
		table.insert(err_logs, M.await_copy_multi({ { path, new_path, }, }))
		return err_logs
	end

	table.insert(err_logs, M.await_mkdir_multi({ { path, new_path } }))

	local dirs, files = M.await_get_items_recursive(path, target)
	for _, dir_table in ipairs(dirs) do
		table.insert(err_logs, M.await_mkdir_multi(dir_table))
	end
	table.insert(err_logs, M.await_copy_multi(files))

	return err_logs
end

function M.await_create_file(path)
	local co = coroutine.running()
	vim.uv.fs_open(path, 'wx', tonumber('666', 8), function(open_err, fd)
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
	vim.uv.fs_mkdir(path, tonumber('755', 8), function(err, success)
		vim.schedule(function() coroutine.resume(co, err, success) end)
	end)

	return coroutine.yield()
end

function M.await_move_multi(items)
	local co = coroutine.running()
	local err_log = M.new_error_log()
	local count = M.new_process_counter(co, err_log)
	for _, item in ipairs(items) do
		count.increment()
		vim.uv.fs_rename(item[1], item[2], function(err, success)
			if err or not success then
				err_log.add_data({ err = err, success = success, path = item[1] })
			end
			count.decrement()
		end)
	end

	if count.get() == 0 then return {} end
	return coroutine.yield()
end

return M
