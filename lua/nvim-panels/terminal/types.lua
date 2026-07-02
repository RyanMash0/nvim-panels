---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-panels.terminal.do_buf_iterator fun(_: nil, i: integer): integer?, nvim-panels.buf_id?

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-panels.terminal: nvim-panels.module
---@field get_config fun(): nvim-panels.terminal.config
---@field get_constants fun(): nvim-panels.module.constants
---@field get_keymaps fun(): nvim-panels.module.keymaps
---@field get_state fun(): nvim-panels.module.state
---@field get_ui fun(): nvim-panels.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-panels.terminal.keymaps
---@field esc string
---@field add string
---@field delete string

---@class nvim-panels.terminal.config.options: nvim-panels.module.config.options
---@field window nvim-panels.win_opts
---@field buffer nvim-panels.buf_opts
---@field base_statusline string
---@field keymaps nvim-panels.terminal.keymaps

---@class nvim-panels.terminal.config: nvim-panels.module.config
---@field options nvim-panels.terminal.config.options
---@field setup fun(opts?: nvim-panels.terminal.config.options)

-------------------------------------------------------------------------------
-- Constants                                                                 --
-------------------------------------------------------------------------------

---@class nvim-panels.terminal.statusline.hl
---@field selected string
---@field normal string

---@class nvim-panels.terminal.statusline
---@field sep string
---@field hl nvim-panels.terminal.statusline.hl
