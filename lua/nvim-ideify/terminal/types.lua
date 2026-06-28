---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-ideify.terminal.do_buf_iterator fun(_: nil, i: integer): integer?, nvim-ideify.buf_id?

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-ideify.terminal: nvim-ideify.module
---@field get_config fun(): nvim-ideify.terminal.config
---@field get_constants fun(): nvim-ideify.module.constants
---@field get_keymaps fun(): nvim-ideify.module.keymaps
---@field get_state fun(): nvim-ideify.module.state
---@field get_ui fun(): nvim-ideify.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-ideify.terminal.keymaps
---@field esc string
---@field add string
---@field delete string

---@class nvim-ideify.terminal.config.options: nvim-ideify.module.config.options
---@field window nvim-ideify.win_opts
---@field buffer nvim-ideify.buf_opts
---@field base_statusline string
---@field keymaps nvim-ideify.terminal.keymaps

---@class nvim-ideify.terminal.config: nvim-ideify.module.config
---@field options nvim-ideify.terminal.config.options
---@field setup fun(opts?: nvim-ideify.terminal.config.options)

-------------------------------------------------------------------------------
-- Constants                                                                 --
-------------------------------------------------------------------------------

---@class nvim-ideify.terminal.statusline.hl
---@field selected string
---@field normal string

---@class nvim-ideify.terminal.statusline
---@field sep string
---@field hl nvim-ideify.terminal.statusline.hl
