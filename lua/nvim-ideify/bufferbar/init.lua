local M = {}

function M:get_ui()
	return require('nvim-ideify.bufferbar.ui')
end

function M:get_config()
	return require('nvim-ideify.bufferbar.config')
end

function M:get_state()
	return require('nvim-ideify.bufferbar.state')
end

function M:get_keymaps()
	return require('nvim-ideify.bufferbar.keymaps')
end

vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'IDEifyBufferBar',
	callback = function()
		vim.defer_fn(M:get_ui().render, 10)
	end
})

vim.api.nvim_create_autocmd('BufModifiedSet', {
	group = 'IDEifyBufferBar',
	callback = function()
		vim.defer_fn(M:get_ui().render, 10)
	end
})

vim.api.nvim_create_autocmd({'BufAdd', 'BufNew'}, {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local buf = args.buf
		local position = #state.buffer_order + 1
		if not state.buffer_info[buf] and vim.bo[buf].buflisted then
			state.buffer_info[buf] = { position = position }
			state.buffer_order[position] =  buf
		end
	end,
})

vim.api.nvim_create_autocmd({'BufDelete'}, {
	group = 'IDEifyBufferBar',
	callback = function(args)
		local state = require('nvim-ideify.bufferbar.state')
		local buf = args.buf
		local buf_info = state.buffer_info[buf]
		local position
		if buf_info then
			position = buf_info.position
			state.buffer_info[buf] = nil
			table.remove(state.buffer_order, position)
		end
	end,
})

return M
