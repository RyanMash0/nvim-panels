---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@generic K, V
---@alias nvim-panels.do_generic_iterator fun(table: table<K, V>, index?: K): K?, V?

---@alias nvim-panels.buf_id integer
---@alias nvim-panels.win_id integer
---@alias nvim-panels.ns_id integer
---@alias nvim-panels.win_config vim.api.keyset.win_config
---@alias nvim-panels.win_opts table<string, any>
---@alias nvim-panels.buf_opts table<string, any>
---@alias nvim-panels.invalid_id -1
---@alias nvim-panels.position 'left' | 'right' | 'top' | 'bottom'
---@alias nvim-panels.split 'left' | 'right' | 'above' | 'below'

---@alias nvim-panels.winlayout.depth integer
---@alias nvim-panels.winlayout.index integer
---@alias nvim-panels.winlayout.branch vim.fn.winlayout.branch
---@alias nvim-panels.winlayout.leaf vim.fn.winlayout.leaf
---@alias nvim-panels.winlayout.empty vim.fn.winlayout.empty

-------------------------------------------------------------------------------
-- Winlayout
-------------------------------------------------------------------------------

---@class nvim-panels.winlayout.parent
---@field [1] nvim-panels.winlayout.depth
---@field [2] nvim-panels.winlayout.index
---@field [3] nvim-panels.winlayout.leaf

-------------------------------------------------------------------------------
-- Module Interfaces                                                         --
-------------------------------------------------------------------------------

---@class nvim-panels.buf_config
---@field listed boolean
---@field scratch boolean

---@class nvim-panels.module.constants.config
---@field buffer nvim-panels.buf_config
---@field window nvim-panels.win_config

---@class nvim-panels.module.constants
---@field config nvim-panels.module.constants.config

---@class nvim-panels.module.config.options
---@field buffer nvim-panels.buf_opts
---@field window nvim-panels.win_opts

---@class nvim-panels.module.config
---@field options nvim-panels.module.config.options
---@field setup fun(opts?: nvim-panels.module.config.options)

---@class nvim-panels.module.keymaps
---@field setup fun()

---@class nvim-panels.module.state
---@field get_buffer fun(): nvim-panels.buf_id
---@field set_buffer fun(buf_id: nvim-panels.buf_id)
---@field get_window fun(): nvim-panels.win_id
---@field set_window fun(win_id: nvim-panels.win_id)
---@field get_on_click fun(): fun()?

---@class nvim-panels.module.ui
---@field render fun()

---@class nvim-panels.module
---@field get_config fun(): nvim-panels.module.config
---@field get_constants fun(): nvim-panels.module.constants
---@field get_keymaps fun(): nvim-panels.module.keymaps
---@field get_state fun(): nvim-panels.module.state
---@field get_ui fun(): nvim-panels.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-panels.panel
---@field module fun(): nvim-panels.module?
---@field width? integer
---@field height? integer
---@field hidden boolean

---@class nvim-panels.options.layout
---@field left nvim-panels.panel
---@field right nvim-panels.panel
---@field top nvim-panels.panel
---@field bottom nvim-panels.panel

---@class nvim-panels.options.split_order
---@field [1] nvim-panels.position
---@field [2] nvim-panels.position
---@field [3] nvim-panels.position
---@field [4] nvim-panels.position

---@class nvim-panels.options.permissions
---@field directory integer
---@field file integer

---@class nvim-panels.options
---@field layout nvim-panels.options.layout
---@field split_order nvim-panels.options.split_order
---@field permissions nvim-panels.options.permissions
---@field bufferbar? nvim-panels.bufferbar.config.options
---@field filetree? nvim-panels.filetree.config.options
---@field terminal? nvim-panels.terminal.config.options
---@field trash_path string

---@class nvim-panels.config
---@field defaults nvim-panels.options
---@field options nvim-panels.options
---@field setup fun(opts?: nvim-panels.options)

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------

---@class nvim-panels.state.wins
---@field main nvim-panels.win_id
---@field last nvim-panels.win_id

---@class nvim-panels.parent_win_entry
---@field [1] integer
---@field [2] integer
---@field [3] nvim-panels.win_id

---@class nvim-panels.editor_win
---@field parent? nvim-panels.parent_win_entry
---@field config? nvim-panels.win_config
---@field buffer? nvim-panels.buf_id
---@field id nvim-panels.win_id

---@class nvim-panels.state
---@field active boolean
---@field opened boolean
---@field equalalways boolean
---@field wins nvim-panels.state.wins
---@field editor_wins nvim-panels.editor_win[][]
---@field width_ratio number
---@field height_ratio number
---@field guicursor string
