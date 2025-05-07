local autocmd = vim.api.nvim_create_autocmd
local Mark = require('poon.mark')
local Menu = require('poon.menu')

local M = {}

local function update_mark(args)
  if Mark.is_marked(args.buf) then
    Mark.set()
  end
end

---@param opts poon.Config
local function setup_autocmds(opts)
  if opts.mark.save.on_insert_leave then
    autocmd('InsertLeave', { callback = update_mark })
  end

  if opts.mark.save.on_move then
    autocmd('CursorMoved', { callback = update_mark })
  end

  if opts.mark.save.on_leave then
    autocmd('BufLeave', { callback = update_mark })
  end
end

---@param opts? poon.Config Configuration options
function M.setup(opts)
  local options = require('poon.config').setup(opts)
  setup_autocmds(options)
end

---Add the current file to this project's marks
function M.mark_add()
  Mark.set()
end

---Sets the current buffer as the first mark
function M.mark_as_first()
  Mark.set_as_first_mark()
end

---Removes the current file from the project's marks
function M.mark_remove()
  Mark.remove()
end

---Navigate to a file.
---The `idx` parameter is the index of the file in the menu
---@param idx number
function M.jump(idx)
  Mark.jump(idx)
end

---Get the index for a given mark
---@param relative_path string
---@return integer?
function M.mark_get_index(relative_path)
  return Mark.idx(relative_path)
end

---Get the marks for the current project
---@return poon.project.mark[]
function M.get_marks()
  return Mark.get_marks()
end

---Check if the current file is marked
---@param bufnr? integer The bufnr to check. Current buffer is used if not provided
---@return boolean
function M.is_marked(bufnr)
  return Mark.is_marked(bufnr)
end

---Checks if the current project has marks
---@return boolean
function M.has_marks()
  return Mark.has_marks()
end

---Open the Poon menu
function M.menu_open()
  Menu:open()
end

---Close the Poon menu
function M.menu_close()
  Menu:close()
end

---Toggle the Poon menu
function M.menu_toggle()
  Menu:toggle()
end

vim.api.nvim_create_user_command('PoonJump', function(opts)
  local mark_number = tonumber(opts.args)
  if not mark_number or mark_number < 0 or math.floor(mark_number) ~= mark_number then
    M.jump(1)
    return
  end

  M.jump(mark_number)
end, {
  desc = 'Jump to a mark number. Jumps to the first mark if number is not provided',
  nargs = '?',
  complete = function()
    return vim.tbl_map(tostring, vim.tbl_keys(M.get_marks()))
  end,
})

vim.api.nvim_create_user_command('PoonAddMark', function(opts)
  (opts.bang and M.mark_as_first or M.mark_add)()
end, { desc = 'Add file to marks. Use `!` to set as first mark', bang = true })

vim.api.nvim_create_user_command('PoonRemoveMark', M.mark_remove, { desc = 'Remove the current file from the marks list' })
vim.api.nvim_create_user_command('PoonToggle', M.menu_toggle, { desc = 'Toggle the Poon Menu' })
vim.api.nvim_create_user_command('PoonOpen', M.menu_open, { desc = 'Open the Poon Menu' })
vim.api.nvim_create_user_command('PoonClose', M.menu_close, { desc = 'Open the Poon Menu' })

return M
