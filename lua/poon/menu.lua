local autocmd = vim.api.nvim_create_autocmd
local Config = require('poon.config')
local Mark = require('poon.mark')

local width = 70
local height = 10

---@type poon.Config.menu
local default = {
  win = {
    border = 'rounded',
    relative = 'editor',
    style = 'minimal',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    title = { { ' The Poon ', 'PoonTitle' } },
    title_pos = 'center',
  },
  close_on_select = true,
  keys = {
    { mode = 'n', action = 'select', key = '<cr>' },
    { mode = 'n', action = 'close', key = '<esc>' },
    { mode = 'n', action = 'close', key = 'q' },
  },
}
local config = vim.tbl_deep_extend('force', default, Config.menu or {})
local ns = vim.api.nvim_create_namespace('POON')

---@param bufnr integer
---@param winnr integer
local function set_options(bufnr, winnr)
  vim.cmd('setlocal statuscolumn=%l%=%s')
  vim.api.nvim_set_option_value('number', true, { win = winnr })
  vim.api.nvim_buf_set_name(bufnr, 'poon-menu')
  vim.api.nvim_set_option_value('filetype', 'poon', { buf = bufnr })
  vim.api.nvim_set_option_value('buftype', 'acwrite', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'delete', { buf = bufnr })
  vim.api.nvim_set_option_value('statuscolumn', '%l%=%s', { scope = 'local' })
end

---@param file_name string
---@return string
local function get_sign(file_name)
  if vim.fn.isdirectory(file_name) == 1 then
    local sign_name = 'PoonDirectory'
    vim.fn.sign_define(sign_name, { text = '', texthl = 'Normal' })
    return sign_name
  end

  local devicons = require('nvim-web-devicons')
  local extension = vim.fn.fnamemodify(file_name, ':e')
  local icon, hl_group = devicons.get_icon(file_name, extension, { default = true })
  local sign_name = 'Poon' .. extension:upper()
  vim.fn.sign_define(sign_name, { text = icon, texthl = hl_group })

  return sign_name
end

--- Sets the icon and it's highlight group
local function set_signs(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  if #lines == 1 and #lines[1] == 0 then
    return
  end

  for idx, _ in pairs(lines) do
    local marks = Mark.get_marks()
    if not marks[idx] then
      return
    end

    local mark = marks[idx]
    local sign_name = get_sign(mark.filename)
    vim.fn.sign_place(0, '', sign_name, bufnr, { lnum = idx })
  end
end

---@param keys poon.Config.menu.keys[]?
local function set_keymaps(keys)
  if not keys then
    return
  end

  vim.iter(config.keys):each(function(map) ---@param map poon.Config.menu.keys
    vim.keymap.set(map.mode, map.key, function()
      if map.action == 'close' then
        require('poon.menu'):close()
      elseif map.action == 'select' then
        require('poon.menu'):select()
      end
    end, { buffer = true })
  end)
end

---@param bufnr integer
local function set_contents(bufnr)
  -- stylua: ignore
  local contents = vim
    .iter(Mark.get_marks())
    :map(function(mark) return mark.filename end)
    :totable()
  vim.api.nvim_buf_set_lines(bufnr, 0, #contents, false, contents)
end

local function set_autocmds(bufnr)
  autocmd('BufWriteCmd', {
    buffer = bufnr,
    callback = function()
      -- require('harpoon.ui').on_menu_save()
    end,
  })

  autocmd('BufModifiedSet', {
    buffer = bufnr,
    callback = function()
      vim.cmd('set nomodified')
    end,
  })

  if Config.mark.save.on_change then
    autocmd({ 'TextChanged', 'TextChangedI' }, {
      buffer = bufnr,
      callback = function()
        set_signs(bufnr)
      end,
    })
  end

  autocmd('BufLeave', {
    once = true,
    callback = function()
      require('poon.menu'):close()
    end,
  })
end

---@class poon.UI
---@field bufnr? integer
---@field winnr? integer
---@field is_open? boolean
local M = {
  bufnr = nil,
  winnr = nil,
  is_open = false,
}

function M:open()
  self:close()
  self.bufnr = vim.api.nvim_create_buf(false, true)
  self.is_open = true
  vim.bo[self.bufnr].ft = 'poon'
  self.winnr = vim.api.nvim_open_win(M.bufnr, true, config.win or {})
  set_contents(self.bufnr)
  set_options(self.bufnr, self.winnr)
  set_keymaps(config.keys)
  set_signs(self.bufnr)
  set_autocmds(self.bufnr)
end

function M:close()
  if not self:valid() then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
  log(lines)

  vim.api.nvim_win_close(self.winnr, true)
  if self.bufnr then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
  self.winnr = nil
  self.bufnr = nil
  self.is_open = false
end

function M:valid()
  return self.is_open and self.winnr and vim.api.nvim_win_is_valid(self.winnr)
end

function M:toggle()
  if self:valid() then
    self:close()
  else
    self:open()
  end
end

function M:select()
  Snacks.debug.inspect('TODO: implement menu.select()')
  self:close()
end

return M
