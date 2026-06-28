---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-ideify.filetree.do_tree_iterator fun(_: nil, i: integer): integer?, nvim-ideify.filetree.entry?
---@alias nvim-ideify.filtree.path_log_entry string
---@alias nvim-ideify.filetree.path_obj [string, string]

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-ideify.filetree: nvim-ideify.module
---@field get_config fun(): nvim-ideify.filetree.config
---@field get_constants fun(): nvim-ideify.module.constants
---@field get_keymaps fun(): nvim-ideify.module.keymaps
---@field get_state fun(): nvim-ideify.module.state
---@field get_ui fun(): nvim-ideify.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-ideify.filetree.keymaps
---@field move string
---@field rename string
---@field copy string
---@field delete string
---@field new_file string
---@field new_dir string
---@field mark_target string
---@field mark_source string
---@field clear_marked string
---@field go_to_dir string
---@field refresh string
---@field expand_target string
---@field close_target string
---@field close_all string
---@field toggle_keymaps string
---@field ascend string
---@field action string
---@field action_alt string
---@field descend string
---@field descend_alt string

---@class nvim-ideify.filetree.config.options: nvim-ideify.module.config.options
---@field window nvim-ideify.win_opts
---@field buffer nvim-ideify.buf_opts
---@field show_keymaps boolean
---@field header fun(): string[]?
---@field keymaps_info string[]
---@field keymaps nvim-ideify.filetree.keymaps

---@class nvim-ideify.filetree.config: nvim-ideify.module.config
---@field options nvim-ideify.filetree.config.options
---@field setup fun(opts?: nvim-ideify.filetree.config.options)
---@field add_highlights fun()

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------

---@class nvim-ideify.filetree.entry
---@field depth integer
---@field path string
---@field type nvim-ideify.enum.fs_type

-------------------------------------------------------------------------------
-- Async                                                                     --
-------------------------------------------------------------------------------

---@generic T
---@class nvim-ideify.filetree.log
---@field add_data fun(new_data: T)
---@field get_data fun(): T[]

---@generic T
---@class nvim-ideify.filetree.verifier
---@field add_data fun(item: T)
---@field verify fun(item: T): boolean

---@class nvim-ideify.filetree.process_counter
---@field increment fun()
---@field decrement fun()
---@field get fun(): integer

---@class nvim-ideify.filetree.err_log_entry
---@field err string
---@field success boolean
---@field path? string
