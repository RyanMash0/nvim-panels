---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------
---@alias nvim-ideify.win_id integer
---@alias nvim-ideify.buf_id integer
---@alias nvim-ideify.ns_id integer
---@alias nvim-ideify.win_config vim.api.keyset.win_config
---@alias nvim-ideify.win_opts table<string, any>
---@alias nvim-ideify.buf_opts table<string, any>
---@alias nvim-ideify.invalid_id -1

-------------------------------------------------------------------------------
-- Module Interfaces                                                         --
-------------------------------------------------------------------------------
---@class nvim-ideify.buf_config
---@field listed boolean
---@field scratch boolean

---@class nvim-ideify.module.constants.config
---@field window nvim-ideify.win_config
---@field buffer nvim-ideify.buf_config

---@class nvim-ideify.module.constants
---@field config nvim-ideify.module.constants.config

---@class nvim-ideify.module.config.options
---@field window nvim-ideify.win_opts
---@field buffer nvim-ideify.buf_opts

---@class nvim-ideify.module.config
---@field options nvim-ideify.module.config.options
---@field setup fun(opts?: nvim-ideify.module.config.options)

---@class nvim-ideify.module.keymaps
---@field setup fun()

---@class nvim-ideify.module.state
---@field get_window fun(): nvim-ideify.win_id
---@field set_window fun(winid: nvim-ideify.win_id)
---@field get_buffer fun(): nvim-ideify.buf_id
---@field set_buffer fun(bufnr: nvim-ideify.buf_id)
---@field get_on_click fun(): fun() | nil

---@class nvim-ideify.module.ui
---@field render fun()

---@class nvim-ideify.module
---@field get_config fun(): nvim-ideify.module.config
---@field get_constants fun(): nvim-ideify.module.constants
---@field get_keymaps fun(): nvim-ideify.module.keymaps
---@field get_state fun(): nvim-ideify.module.state
---@field get_ui fun(): nvim-ideify.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------
---@class nvim-ideify.panel
---@field module fun(): nvim-ideify.module | nil
---@field width? integer
---@field height? integer
---@field hidden boolean

---@class nvim-ideify.options.layout
---@field left nvim-ideify.panel
---@field right nvim-ideify.panel
---@field top nvim-ideify.panel
---@field bottom nvim-ideify.panel

---@class nvim-ideify.options.split_order
---@field [1] nvim-ideify.position
---@field [2] nvim-ideify.position
---@field [3] nvim-ideify.position
---@field [4] nvim-ideify.position

---@class nvim-ideify.options.permissions
---@field directory integer
---@field file integer

---@class nvim-ideify.options
---@field layout nvim-ideify.options.layout
---@field split_order nvim-ideify.options.split_order
---@field permissions nvim-ideify.options.permissions
---@field bufferbar? nvim-ideify.module.config.options
---@field filetree? nvim-ideify.module.config.options
---@field terminal? nvim-ideify.module.config.options
---@field trash_path string

---@class nvim-ideify.config
---@field defaults nvim-ideify.options
---@field options nvim-ideify.options
---@field setup fun(opts?: nvim-ideify.options)

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------
---@class nvim-ideify.state.wins
---@field main nvim-ideify.win_id
---@field last nvim-ideify.win_id

---@class nvim-ideify.parent_win_entry
---@field [1] integer
---@field [2] integer
---@field [3] nvim-ideify.win_id

---@class nvim-ideify.editor_win
---@field parent nvim-ideify.parent_win_entry
---@field config nvim-ideify.win_config
---@field buffer nvim-ideify.buf_id
---@field id nvim-ideify.win_id

---@class nvim-ideify.state
---@field active boolean
---@field opened boolean
---@field equalalways boolean
---@field wins nvim-ideify.state.wins
---@field editor_wins nvim-ideify.editor_win[][]
---@field width_ratio number
---@field height_ratio number
