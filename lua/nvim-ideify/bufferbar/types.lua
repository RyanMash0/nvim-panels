---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-ideify.bufferbar.do_buf_iterator fun(_: nil, i: integer): integer?, nvim-ideify.buf_id?

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-ideify.bufferbar: nvim-ideify.module
---@field get_config fun(): nvim-ideify.bufferbar.config
---@field get_constants fun(): nvim-ideify.module.constants
---@field get_keymaps fun(): nvim-ideify.module.keymaps
---@field get_state fun(): nvim-ideify.module.state
---@field get_ui fun(): nvim-ideify.module.ui
---@field buffer_next fun()
---@field buffer_previous fun()

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-ideify.bufferbar.styling.button
---@field close string
---@field modified string
---@field below string
---@field pos integer

---@class nvim-ideify.bufferbar.styling.padding.obj
---@field before number
---@field after number
---@field before_str? string
---@field after_str? string

---@class nvim-ideify.bufferbar.styling.padding
---@field normal nvim-ideify.bufferbar.styling.padding.obj
---@field minimal nvim-ideify.bufferbar.styling.padding.obj

---@class nvim-ideify.bufferbar.styling
---@field separator string
---@field button nvim-ideify.bufferbar.styling.button
---@field padding nvim-ideify.bufferbar.styling.padding

---@class nvim-ideify.bufferbar.keymaps
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

---@class nvim-ideify.bufferbar.regex
---@field close string
---@field modified string
---@field pad_pre string
---@field min_pad_pre string
---@field separator string

---@class nvim-ideify.bufferbar.config.options: nvim-ideify.module.config.options
---@field window nvim-ideify.win_opts
---@field buffer nvim-ideify.buf_opts
---@field name_pref_length integer
---@field minimal boolean
---@field styling nvim-ideify.bufferbar.styling
---@field keymaps nvim-ideify.bufferbar.keymaps
---@field regex? nvim-ideify.bufferbar.regex

---@class nvim-ideify.bufferbar.config: nvim-ideify.module.config
---@field options nvim-ideify.bufferbar.config.options
---@field setup fun(opts?: nvim-ideify.bufferbar.config.options)

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------

---@class nvim-ideify.bufferbar.entry
---@field first integer
---@field last integer
---@field position integer
