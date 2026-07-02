---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-panels.bufferbar.do_buf_iterator fun(_: nil, i: integer): integer?, nvim-panels.buf_id?

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-panels.bufferbar: nvim-panels.module
---@field get_config fun(): nvim-panels.bufferbar.config
---@field get_constants fun(): nvim-panels.module.constants
---@field get_keymaps fun(): nvim-panels.module.keymaps
---@field get_state fun(): nvim-panels.module.state
---@field get_ui fun(): nvim-panels.module.ui
---@field buffer_next fun()
---@field buffer_previous fun()

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-panels.bufferbar.styling.button
---@field close string
---@field modified string
---@field below string
---@field pos integer

---@class nvim-panels.bufferbar.styling.padding.obj
---@field before number
---@field after number
---@field before_str? string
---@field after_str? string

---@class nvim-panels.bufferbar.styling.padding
---@field normal nvim-panels.bufferbar.styling.padding.obj
---@field minimal nvim-panels.bufferbar.styling.padding.obj

---@class nvim-panels.bufferbar.styling
---@field separator string
---@field button nvim-panels.bufferbar.styling.button
---@field padding nvim-panels.bufferbar.styling.padding

---@class nvim-panels.bufferbar.keymaps
---@field action string
---@field action_alt string
---@field clear_yanked string
---@field yank string
---@field put_after string
---@field put_before string
---@field toggle_minimal string
---@field scroll_right string
---@field scroll_left string
---@field mouse_scroll_right string
---@field mouse_scroll_left string

---@class nvim-panels.bufferbar.regex
---@field close string
---@field modified string
---@field pad_pre string
---@field min_pad_pre string
---@field separator string

---@class nvim-panels.bufferbar.config.options: nvim-panels.module.config.options
---@field window nvim-panels.win_opts
---@field buffer nvim-panels.buf_opts
---@field name_pref_length integer
---@field minimal boolean
---@field styling nvim-panels.bufferbar.styling
---@field keymaps nvim-panels.bufferbar.keymaps
---@field regex? nvim-panels.bufferbar.regex

---@class nvim-panels.bufferbar.config: nvim-panels.module.config
---@field options nvim-panels.bufferbar.config.options
---@field setup fun(opts?: nvim-panels.bufferbar.config.options)

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------

---@class nvim-panels.bufferbar.entry
---@field first integer
---@field last integer
---@field position integer
