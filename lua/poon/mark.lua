local Utils = require('poon.utils')

local config = require('poon.config')

local cwd = vim.fn.getcwd(0)
local data_path = config.mark.data_path
if not data_path then
  vim.notify_once('No data path set for marks. Using default', vim.log.levels.WARN, { title = 'Poon' })
end
data_path = data_path or vim.fn.stdpath('data') .. '/poon/marks.json'
local project_marks = Utils.get_project_marks(cwd, data_path) ---@type poon.project.mark[]

---Save the marks for the current project
local function save()
  local projects = JSON.parse(vim.fn.readfile(data_path)) ---@type poon.projects

  if not vim.tbl_contains(vim.tbl_keys(projects), cwd) then
    vim.notify('Project error: Project not found in marks', vim.log.levels.ERROR, { title = 'Poon' })
  end

  projects[cwd] = project_marks

  project_marks = vim
    .iter(project_marks)
    :filter(function(mark)
      return mark.filename ~= nil and mark.filename ~= ''
    end)
    :totable()

  local json = JSON.stringify(projects)
  vim.fn.writefile({ json }, data_path)
  vim.cmd.redrawtabline()
end

local M = {}

---@param marks poon.project.mark[]
function M.update(marks)
  project_marks = marks
  save()
end

---Add the current file to this project's marks
function M.set()
  local relative_path = Utils.get_relative_path()
  if M.is_marked() then
    local idx = M.idx(relative_path)
    project_marks[idx].row = vim.fn.line('.')
    project_marks[idx].col = vim.fn.col('.')
  else
    local new_mark = { filename = relative_path, row = vim.fn.line('.'), col = vim.fn.col('.') }
    table.insert(project_marks, #project_marks + 1, new_mark)
  end

  save()
end

---Gets the index of a file in the project marks
---@param rel_path string
---@return integer?
function M.idx(rel_path)
  for idx, mark in ipairs(project_marks) do
    if mark.filename == rel_path then
      return idx
    end
  end
end

local function valid_index(idx)
  if idx == nil or idx < 1 or idx > #project_marks then
    return false
  end
  local filename = project_marks[idx].filename
  return filename ~= nil and filename ~= ''
end

---@param filename string
---@return integer
local function get_or_create_buffer(filename)
  local buf_exists = vim.fn.bufexists(filename) ~= 0
  if buf_exists then
    return vim.fn.bufnr(filename)
  end

  return vim.fn.bufadd(filename)
end

---Navigate to a file.
---The `idx` parameter is the index of the file in the menu
---@param idx number
function M.jump(idx)
  if not valid_index(idx) then
    return
  end
  local mark = project_marks[idx]
  local filename = vim.fs.normalize(mark.filename)
  local buf_id = get_or_create_buffer(filename)
  local old_bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_set_current_buf(buf_id)
  vim.api.nvim_set_option_value('buflisted', true, { buf = buf_id })

  if vim.api.nvim_buf_is_loaded(buf_id) and mark.row and mark.col then
    vim.api.nvim_win_set_cursor(0, { mark.row, mark.col - 1 })
  end

  local old_bufinfo = vim.fn.getbufinfo(old_bufnr)
  if type(old_bufinfo) == 'table' and #old_bufinfo >= 1 then
    old_bufinfo = old_bufinfo[1]
    local no_name = old_bufinfo.name == ''
    local one_line = old_bufinfo.linecount == 1
    local unchanged = old_bufinfo.changed == 0
    if no_name and one_line and unchanged then
      vim.api.nvim_buf_delete(old_bufnr, {})
    end
  end

  local cur_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(cur_win)
  vim.cmd.redrawtabline()
end

---Get the marks for the current project
---@return poon.project.mark[]
function M.get_marks()
  return project_marks
end

---Check if the current file is marked
---@param bufnr? integer
---@return boolean
function M.is_marked(bufnr)
  local relative_path = Utils.get_relative_path(bufnr)
  return vim.iter(project_marks):any(function(mark)
    return mark.filename == relative_path
  end)
end

---Checks if the current project has marks
---@return boolean
function M.has_marks()
  return vim.tbl_isempty(project_marks)
end

--- Sets the currently opened file to the first entry in the marks list
function M.set_as_first_mark()
  local relative_path = Utils.get_relative_path()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')

  if M.is_marked() then
    local idx = M.idx(relative_path)

    if not idx then
      return
    end

    local mark = project_marks[idx]
    mark.row = row
    mark.col = col
    table.remove(project_marks, idx)
    table.insert(project_marks, 1, mark)
  else
    local new_mark = { filename = relative_path, row = row, col = col }
    table.insert(project_marks, 1, new_mark)
  end

  save()
end

---Removes the current file from the project's marks
---@param index? integer
function M.remove(index)
  if index and project_marks[index] then
    table.remove(project_marks, index)
    return
  end

  if not M.is_marked() then
    return
  end

  local relative_path = Utils.get_relative_path()
  local idx = M.idx(relative_path)

  if not idx then
    return
  end

  table.remove(project_marks, idx)

  save()
end

return M
