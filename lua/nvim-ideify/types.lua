---@meta

---@alias nvim-ideify.win_id integer
---@alias nvim-ideify.buf_id integer
---@alias nvim-ideify.ns_id integer
---@alias nvim-ideify.win_config vim.api.keyset.win_config
---@alias nvim-ideify.win_opts table<string, any>
---@alias nvim-ideify.buf_opts table<string, any>
---@alias nvim-ideify.invalid_id -1

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
---@field setup fun(opts: nvim-ideify.module.config.options)

---@class nvim-ideify.module.keymaps
---@field setup fun()

---@class nvim-ideify.module.state
---@field get_window fun(): nvim-ideify.win_id
---@field set_window fun(winid: nvim-ideify.win_id)
---@field get_buffer fun(): nvim-ideify.buf_id
---@field set_buffer fun(bufnr: nvim-ideify.buf_id)
---@field get_win_config fun(): nvim-ideify.win_config
---@field set_win_config fun(config: nvim-ideify.win_config)
---@field get_on_click fun(): fun()

---@class nvim-ideify.module.ui
---@field render fun()

---@class nvim-ideify.module
---@field get_config fun(): nvim-ideify.module.config, unknown | nil
---@field get_constants fun(): nvim-ideify.module.constants, unknown | nil
---@field get_keymaps fun(): nvim-ideify.module.keymaps, unknown | nil
---@field get_state fun(): nvim-ideify.module.state, unknown | nil
---@field get_ui fun(): nvim-ideify.module.ui, unknown | nil

---@class nvim-ideify.state.wins
---@field main nvim-ideify.win_id
---@field last nvim-ideify.win_id

---@class nvim-ideify.state
---@field active boolean
---@field opened boolean
---@field equalalways boolean
---@field wins nvim-ideify.state.wins

---@class nvim-ideify.panel
---@field module fun(): nvim-ideify.module | nil, unknown | nil
---@field width? integer
---@field height? integer
---@field hidden boolean

---@class nvim-ideify.config.layout
---@field left nvim-ideify.panel
---@field right nvim-ideify.panel
---@field top nvim-ideify.panel
---@field bottom nvim-ideify.panel

---@class nvim-ideify.config.split_order
---@field first nvim-ideify.position
---@field second nvim-ideify.position
---@field third nvim-ideify.position
---@field fourth nvim-ideify.position

---@class nvim-ideify.config.permissions
---@field directory integer
---@field file integer

---@class nvim-ideify.config
---@field layout nvim-ideify.config.layout
---@field split_order nvim-ideify.config.split_order
---@field permissions nvim-ideify.config.permissions
---@field trash_path string
