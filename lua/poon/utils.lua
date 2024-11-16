local M = {}

--- Helper object for JSON operations
--- vim.encode/decode does some weird escaping
M.JSON = {
  ---@param tbl table
  ---@return string
  stringify = function(tbl)
    local str = vim.json.encode(tbl):gsub('\\/', '/')
    return str
  end,

  ---@param str string|string[]
  ---@return poon.projects
  parse = function(str)
    if type(str) == 'table' then
      str = table.concat(str, '') -- join lines
    end

    str = str:gsub('%s+', '') -- trim whitespace
    str = str:gsub('/', '\\/') -- escape slashes
    return vim.json.decode(str)
  end,
}

function M.trim(str)
  str = str:gsub('^%s+', '')
  str = str:gsub('%s+$', '')
  return str
end

---@param cwd string
---@param data_path string
local function create_data_file(cwd, data_path)
  local json = M.JSON.stringify({ [cwd] = {} })
  vim.fn.writefile({ json }, data_path)
end

---@param cwd string
---@param data_path string
---@return poon.project.mark[]
local function read_data_file(cwd, data_path)
  ---@type poon.projects
  local projects = M.JSON.parse(vim.fn.readfile(data_path))

  if vim.tbl_contains(vim.tbl_keys(projects), cwd) then
    return projects[cwd]
  end

  projects[cwd] = {}
  vim.tbl_deep_extend('force', projects, { [cwd] = {} })

  local json = M.JSON.stringify(projects)
  vim.fn.writefile({ json }, data_path)
  return projects[cwd]
end

---@param cwd string
---@param data_path string
---@return poon.project.mark[]
function M.get_project_marks(cwd, data_path)
  if vim.fn.filereadable(data_path) == 0 then
    create_data_file(cwd, data_path)
    return {}
  end

  return read_data_file(cwd, data_path)
end

---@param files? string[]
function M.filter_files(files)
  if not files then
    return
  end

  local hash = {}
  for i, file in ipairs(files) do
    if file == nil or file == '' or M.trim(file) == '' then
      table.remove(files, i)
      break
    end

    if not hash[file] then
      hash[file] = true
    else
      table.remove(files, i)
    end
  end

  return files
end

return M
