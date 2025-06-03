---@class poon.projects All project related data
---@field [string] poon.project.mark[] Project's marks

---@class poon.project.mark Mark data
---@field filename string file name for this mark
---@field row integer cursor row number
---@field col integer cursor col number

---@class poon.Config.menu.keys
---@field mode? "n"|"i" Mode to use the keymap
---@field action? "select"|"close"|"vsplit"|"hsplit" Action to perform. `'select'` selects the file, `'close'` closes the menu. `'vsplit'` and `'hsplit'` open the file in a vertical or horizontal split respectively
---@field key? string Key to use

---@class poon.Config.mark.save_opts Determines when marks are saved to disk
---@field on_move? boolean Save mark when the cursor moves. Warning! this will run every time the cursor moves!
---@field on_insert_leave? boolean Save mark when leaving insert mode
---@field on_leave? boolean Save mark upon leaving a marked file
---@field on_select? boolean Save mark when selecting a file from the menu
---@field on_menu_close? boolean Save mark when the menu closes
---@field on_change? boolean Update marks when the menu is edited

---@class poon.Config.mark Mark configuration options
---@field save? poon.Config.mark.save_opts When to update the marks file
---@field data_path? string Where to save the marks file. Default: vim.fn.stdpath('data') .. '/marks.json'
---@field exclude? poon.Config.mark.exclude Prevent poon from marking certain files

---@class poon.Config.menu
---@field close_on_select? boolean Closes the menu upon selecting a file
---@field keys? poon.Config.menu.keys[] Buffer local keymaps for the menu
---@field win? vim.api.keyset.win_config The window configuration. See |nvim_open_win|
---@field backdrop? boolean Similar to lazy.nvim's backdrop effect. Default = true

---@class poon.Config
---@field menu? poon.Config.menu Menu configuration
---@field mark? poon.Config.mark Mark configuration

---@class poon.Config.mark.exclude
---@field ft? string[]
---@field bufname? string[]

---@type poon.Config
local options

---@class poon.Config.mod: poon.Config
local M = {}

---@type poon.Config
local defaults = {
  menu = {},
  mark = {
    save = {
      on_leave = true,
      on_insert_leave = true,
      on_menu_close = true,
      on_select = true,
      on_move = false,
      on_change = true,
    },
    exclude = {
      --- List of filetypes that will not be marked
      --- Using this option replaces the original list, e.g. both lists will not be merged.
      --- ---
      ---Default:
      ---```
      ---{
      ---  'neo-tree'
      ---  'NvimTree',
      ---  'Trouble',
      ---  'poon',
      ---  'help',
      ---  'noice',
      ---  'prompt',
      ---  'terminal',
      ---  'toggleterm',
      ---  'fidget',
      ---  'notify',
      ---  'snacks_notif',
      ---  'neotest-summary',
      ---  'neotest-output-panel'
      ---}
      ---```
      ft = {
        'neo-tree',
        'NvimTree',
        'Trouble',
        'poon',
        'help',
        'noice',
        'prompt',
        'terminal',
        'toggleterm',
        'fidget',
        'notify',
        'snacks_notif',
        'neotest-summary',
        'neotest-output-panel',
      },
      --- Bufnames that will not be marked.
      --- ---
      --- Default:
      --- ```
      --- { "[No Name]" }
      --- ```
      bufname = { '[No Name]' },
    },
    data_path = vim.fn.stdpath('data') .. '/marks.json',
  },
}

---@param opts? poon.Config
function M.setup(opts)
  ---@type poon.Config
  options = vim.tbl_deep_extend('force', options or defaults, opts or {})
  return options
end

return setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      M.setup()
    end

    ---@diagnostic disable-next-line
    return options[key]
  end,
})
