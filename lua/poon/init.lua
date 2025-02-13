local autocmd = vim.api.nvim_create_autocmd
local Mark = require('poon.mark')
local Menu = require('poon.menu')

local M = {
  mark = {},
  menu = {},
}

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
function M.mark.set()
  Mark.set()
end

---Navigate to a file.
---The `idx` parameter is the index of the file in the menu
---@param idx number
function M.mark.jump(idx)
  Mark.jump(idx)
end

---Get the marks for the current project
---@return poon.project.mark[]
function M.mark.get_marks()
  return Mark.get_marks()
end

---Check if the current file is marked
---@param bufnr? integer The bufnr to check. Current buffer is used if not provided
---@return boolean
function M.mark.is_marked(bufnr)
  return Mark.is_marked(bufnr)
end

---Get the index for a given mark
---@param relative_path string
---@return integer?
function M.mark.get_index(relative_path)
  return Mark.idx(relative_path)
end

---Checks if the current project has marks
---@return boolean
function M.mark.has_marks()
  return Mark.has_marks()
end

---Removes the current file from the project's marks
function M.mark.remove()
  Mark.remove()
end

---Sets the current buffer as the first mark
function M.mark.set_first()
  Mark.set_as_first_mark()
end

function M.menu.open()
  Menu:open()
end

function M.menu.close()
  Menu:close()
end

function M.menu.toggle()
  Menu:toggle()
end

return M
