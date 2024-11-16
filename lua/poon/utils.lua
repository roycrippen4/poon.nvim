local M = {}

--- Helper object for JSON operations
--- vim.encode/decode does some weird escaping
_G.JSON = {
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

    str = M.trim(str)
    return vim.json.decode(str)
  end,
}

function M.trim(str)
  str = str:gsub('^%s+', ''):gsub('%s+$', '')
  return str
end

---@param cwd string
---@param data_path string
local function create_data_file(cwd, data_path)
  local json = JSON.stringify({ [cwd] = {} })
  vim.fn.writefile({ json }, data_path)
end

---@param cwd string
---@param data_path string
---@return poon.project.mark[]
local function read_data_file(cwd, data_path)
  ---@type poon.projects
  local projects = JSON.parse(vim.fn.readfile(data_path))

  if vim.tbl_contains(vim.tbl_keys(projects), cwd) then
    return projects[cwd]
  end

  projects[cwd] = {}
  vim.tbl_deep_extend('force', projects, { [cwd] = {} })

  local json = JSON.stringify(projects)
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
---@return string[]
function M.sanitize(files)
  if not files then
    return {}
  end

  files = vim.iter(files):map(M.trim):totable()

  local result = {}
  local hash = {}
  for _, file in ipairs(files) do
    if file ~= '' and not hash[file] then
      hash[file] = true
      result[#result + 1] = file
    end
  end

  return result
end

---@param file_or_bufnr? string | integer
---@return string
function M.get_relative_path(file_or_bufnr)
  if not file_or_bufnr then
    return vim.fn.fnamemodify(vim.fn.expand('%p'), ':.')
  end

  if type(file_or_bufnr) == 'number' then
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(file_or_bufnr), ':.')
  end

  return vim.fn.fnamemodify(file_or_bufnr --[[@as string]], ':.')
end

---@param hl_name string
---@return vim.api.keyset.highlight
function M.translate_hl(hl_name)
  local res = {} ---@type vim.api.keyset.highlight
  local hl = vim.api.nvim_get_hl(0, { name = hl_name })
  vim.iter(hl):each(function(k, v)
    if k == 'bg' then
      res.bg = ('#%06x'):format(v)
    end
    if k == 'fg' then
      res.fg = ('#%06x'):format(v)
    end
    res.cterm = hl.cterm
  end)
  return res
end

return M
