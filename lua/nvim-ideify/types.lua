---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@generic K, V
---@alias nvim-ideify.do_generic_iterator fun(table: table<K, V>, index?: K): K?, V?

---@alias nvim-ideify.buf_id integer
---@alias nvim-ideify.win_id integer
---@alias nvim-ideify.ns_id integer
---@alias nvim-ideify.win_config vim.api.keyset.win_config
---@alias nvim-ideify.win_opts table<string, any>
---@alias nvim-ideify.buf_opts table<string, any>
---@alias nvim-ideify.invalid_id -1
---@alias nvim-ideify.position 'left' | 'right' | 'top' | 'bottom'
---@alias nvim-ideify.split 'left' | 'right' | 'above' | 'below'

---@alias nvim-ideify.winlayout.depth integer
---@alias nvim-ideify.winlayout.index integer
---@alias nvim-ideify.winlayout.branch vim.fn.winlayout.branch
---@alias nvim-ideify.winlayout.leaf vim.fn.winlayout.leaf
---@alias nvim-ideify.winlayout.empty vim.fn.winlayout.empty

-------------------------------------------------------------------------------
-- Winlayout
-------------------------------------------------------------------------------

---@class nvim-ideify.winlayout.parent
---@field [1] nvim-ideify.winlayout.depth
---@field [2] nvim-ideify.winlayout.index
---@field [3] nvim-ideify.winlayout.leaf

-------------------------------------------------------------------------------
-- Module Interfaces                                                         --
-------------------------------------------------------------------------------

---@class nvim-ideify.buf_config
---@field listed boolean
---@field scratch boolean

---@class nvim-ideify.module.constants.config
---@field buffer nvim-ideify.buf_config
---@field window nvim-ideify.win_config

---@class nvim-ideify.module.constants
---@field config nvim-ideify.module.constants.config

---@class nvim-ideify.module.config.options
---@field buffer nvim-ideify.buf_opts
---@field window nvim-ideify.win_opts

---@class nvim-ideify.module.config
---@field options nvim-ideify.module.config.options
---@field setup fun(opts?: nvim-ideify.module.config.options)

---@class nvim-ideify.module.keymaps
---@field setup fun()

---@class nvim-ideify.module.state
---@field get_buffer fun(): nvim-ideify.buf_id
---@field set_buffer fun(buf_id: nvim-ideify.buf_id)
---@field get_window fun(): nvim-ideify.win_id
---@field set_window fun(win_id: nvim-ideify.win_id)
---@field get_on_click fun(): fun()?

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
---@field module fun(): nvim-ideify.module?
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
---@field bufferbar? nvim-ideify.bufferbar.config.options
---@field filetree? nvim-ideify.filetree.config.options
---@field terminal? nvim-ideify.terminal.config.options
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
---@field parent? nvim-ideify.parent_win_entry
---@field config? nvim-ideify.win_config
---@field buffer? nvim-ideify.buf_id
---@field id nvim-ideify.win_id

---@class nvim-ideify.state
---@field active boolean
---@field opened boolean
---@field equalalways boolean
---@field wins nvim-ideify.state.wins
---@field editor_wins nvim-ideify.editor_win[][]
---@field width_ratio number
---@field height_ratio number
