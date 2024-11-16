local autocmd = vim.api.nvim_create_autocmd
local mark = require('poon.mark')
local menu = require('poon.menu')

local M = {
  mark = {},
  menu = {},
}

local function update_mark(args)
  if mark.is_marked(args.buf) then
    mark.set()
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

  if not opts.restore.on_startup then
    return
  end

  if opts.restore.integrations.nvim_tree then
    autocmd('FileType', {
      once = true,
      pattern = 'NvimTree',
      callback = function()
        vim.defer_fn(function()
          vim.cmd(':NvimTreeClose')
          M.restore_marks()
          vim.cmd(':NvimTreeOpen')
          vim.cmd('wincmd l')
        end, 0)
      end,
    })
  end
end

---@param opts? poon.Config Configuration options
function M.setup(opts)
  local options = require('poon.config').setup(opts)
  setup_autocmds(options)
end

--- Restores all marked files
function M.restore_marks()
  local marks = mark.get_marks()
  vim.iter(marks):each(function(m)
    vim.cmd.edit(m.filename)
    vim.api.nvim_win_set_cursor(0, { m.row, m.col })
  end)
  mark.jump(1)
end

---Add the current file to this project's marks
function M.mark.set()
  mark.set()
end

---Navigate to a file.
---The `idx` parameter is the index of the file in the menu
---@param idx number
function M.mark.jump(idx)
  mark.jump(idx)
end

---Get the marks for the current project
---@return poon.project.mark[]
function M.mark.get_marks()
  return mark.get_marks()
end

---Check if the current file is marked
---@param bufnr? integer The bufnr to check. Current buffer is used if not provided
---@return boolean
function M.mark.is_marked(bufnr)
  return mark.is_marked(bufnr)
end

---Get the index for a given mark
---@param relative_path string
---@return integer?
function M.mark.get_index(relative_path)
  return mark.idx(relative_path)
end

---Checks if the current project has marks
---@return boolean
function M.mark.has_marks()
  return mark.has_marks()
end

---Removes the current file from the project's marks
function M.mark.remove()
  mark.remove()
end

---Sets the current buffer as the first mark
function M.mark.set_first()
  mark.set_as_first_mark()
end

function M.menu.open()
  menu:open()
end

function M.menu.close()
  menu:close()
end

function M.menu.toggle()
  menu:toggle()
end

return M