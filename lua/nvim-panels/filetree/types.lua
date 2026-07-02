---@meta

-------------------------------------------------------------------------------
-- Aliases                                                                   --
-------------------------------------------------------------------------------

---@alias nvim-panels.filetree.do_tree_iterator fun(_: nil, i: integer): integer?, nvim-panels.filetree.entry?
---@alias nvim-panels.filetree.path_obj [string, string]
---@alias nvim-panels.filetree.path_log_entry nvim-panels.filetree.path_obj

-------------------------------------------------------------------------------
-- Init                                                                      --
-------------------------------------------------------------------------------

---@class nvim-panels.filetree: nvim-panels.module
---@field get_config fun(): nvim-panels.filetree.config
---@field get_constants fun(): nvim-panels.module.constants
---@field get_keymaps fun(): nvim-panels.module.keymaps
---@field get_state fun(): nvim-panels.module.state
---@field get_ui fun(): nvim-panels.module.ui

-------------------------------------------------------------------------------
-- Config                                                                    --
-------------------------------------------------------------------------------

---@class nvim-panels.filetree.keymaps
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

---@class nvim-panels.filetree.config.options: nvim-panels.module.config.options
---@field window nvim-panels.win_opts
---@field buffer nvim-panels.buf_opts
---@field do_cursorline boolean
---@field show_keymaps boolean
---@field header fun(): string[]?
---@field keymaps_info string[]
---@field keymaps nvim-panels.filetree.keymaps

---@class nvim-panels.filetree.config: nvim-panels.module.config
---@field options nvim-panels.filetree.config.options
---@field setup fun(opts?: nvim-panels.filetree.config.options)
---@field add_highlights fun()

-------------------------------------------------------------------------------
-- State                                                                     --
-------------------------------------------------------------------------------

---@class nvim-panels.filetree.entry
---@field depth integer
---@field path string
---@field type nvim-panels.enum.fs_type

-------------------------------------------------------------------------------
-- Async/FS Operations                                                       --
-------------------------------------------------------------------------------

---@generic T
---@class nvim-panels.filetree.log<T>
---@field add_data fun(new_data: T)
---@field get_data fun(): T[]

---@generic T
---@class nvim-panels.filetree.verifier<T>
---@field add_data fun(item: T)
---@field verify fun(item: T): boolean

---@class nvim-panels.filetree.process_counter
---@field increment fun()
---@field decrement fun()
---@field get fun(): integer

---@class nvim-panels.filetree.err_log_entry
---@field err? string
---@field success? boolean
---@field path? string

---@class nvim-panels.filetree.path_list
---@field add_path fun(path: string)
---@field get_paths fun(): nvim-panels.filetree.path_obj[]

---@class nvim-panels.filetree.copy_log
---@field copy_path fun(path: string)
---@field get_logs fun(): nvim-panels.filetree.err_log_entry[][], nvim-panels.filetree.path_log_entry[][]
