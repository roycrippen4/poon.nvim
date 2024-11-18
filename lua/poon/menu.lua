local autocmd = vim.api.nvim_create_autocmd
local Config = require('poon.config')
local Mark = require('poon.mark')
local Utils = require('poon.utils')

vim.api.nvim_set_hl(0, 'PoonBackdrop', { bg = '#000000', default = true })
vim.api.nvim_set_hl(0, 'PoonNormal', { link = 'NormalFloat', default = true })
vim.api.nvim_set_hl(0, 'PoonNormalNC', { link = 'NormalFloat', default = true })
vim.api.nvim_set_hl(0, 'PoonFloatBorder', { link = 'FloatBorder', default = true })
vim.api.nvim_set_hl(0, 'PoonWinBar', { link = 'Title', default = true })
vim.api.nvim_set_hl(0, 'PoonWinBarNC', { link = 'SnacksWinBar', default = true })
vim.api.nvim_set_hl(0, 'PoonOpenMark', { link = 'Conditional', default = true })

local width = 70
local height = 10

---@type poon.Config.menu
local default = {
  win = {
    border = 'solid',
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
    { mode = 'n', action = 'vsplit', key = '<c-v>' },
    { mode = 'n', action = 'hsplit', key = '<c-h>' },
  },
  backdrop = true,
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
  vim.api.nvim_set_option_value(
    'winhighlight',
    'Normal:PoonNormal,NormalNC:PoonNormalNC,WinBar:PoonWinBar,WinBarNC:PoonWinBarNC,FloatBorder:PoonFloatBorder',
    { win = winnr }
  )
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
---@param poon_bufnr integer
---@param current_bufnr integer
local function set_signs(poon_bufnr, current_bufnr)
  local lines = vim.api.nvim_buf_get_lines(poon_bufnr, 0, -1, true)
  vim.api.nvim_buf_clear_namespace(poon_bufnr, ns, 0, -1)

  local file = Utils.get_relative_path(current_bufnr)
  vim.iter(Utils.sanitize(lines)):enumerate():each(function(index, line)
    if line == file then
      vim.api.nvim_buf_set_extmark(poon_bufnr, ns, index - 1, 0, {
        line_hl_group = 'PoonOpenMark',
        virt_text_pos = 'eol',
        end_row = index - 1,
        end_col = #line,
        strict = false,
      })
    end
  end)

  if #lines == 1 and #lines[1] == 0 then
    return
  end

  for idx, _ in ipairs(lines) do
    local sign = get_sign(lines[idx])
    vim.fn.sign_place(0, '', sign, poon_bufnr, { lnum = idx })
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
      elseif map.action == 'vsplit' then
        require('poon.menu'):vsplit()
      elseif map.action == 'hsplit' then
        require('poon.menu'):hsplit()
      end
    end, { buffer = true })
  end)
end

---@param bufnr integer
local function set_contents(bufnr)
  local contents = vim
    .iter(Mark.get_marks())
    :map(function(mark)
      return mark.filename
    end)
    :totable()
  vim.api.nvim_buf_set_lines(bufnr, 0, #contents, false, contents)
end

---@class poon.UI
---@field current_bufnr? integer
---@field bufnr? integer
---@field winnr? integer
---@field is_open? boolean
local M = {
  current_bufnr = nil,
  bufnr = nil,
  winnr = nil,
  backdrop_bufnr = nil,
  backdrop_winnr = nil,
  is_open = false,
}

function M:open()
  self.current_bufnr = vim.api.nvim_get_current_buf()
  self.bufnr = vim.api.nvim_create_buf(false, true)
  self.is_open = true
  vim.bo[self.bufnr].ft = 'poon'

  self:set_autocmds()
  self.winnr = vim.api.nvim_open_win(M.bufnr, true, config.win or {})
  self:open_backdrop()
  set_keymaps(config.keys)
  set_signs(self.bufnr, self.current_bufnr)
  set_contents(self.bufnr)
  set_options(self.bufnr, self.winnr)
end

---@param lines string[]
function M:sync(lines)
  local files = Utils.sanitize(lines)
  local marks = Mark.get_marks()
  local new_marks = {} ---@type poon.project.mark[]

  local map = {} ---@type table<string, poon.project.mark>
  vim.iter(marks):each(function(mark)
    map[mark.filename] = mark
  end)

  vim.iter(files):each(function(filename)
    if map[filename] then
      table.insert(new_marks, {
        filename = map[filename].filename,
        row = map[filename].row,
        col = map[filename].col,
      })
    else
      table.insert(new_marks, {
        filename = filename,
        row = 1,
        col = 1,
      })
    end
  end)
  Mark.update(new_marks)
end

function M:close()
  if not self:valid() then
    return
  end

  if Config.mark.save.on_menu_close then
    self:sync(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false))
  end

  self:close_backdrop()
  vim.api.nvim_win_close(self.winnr, true)
  if self.bufnr then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
  self.winnr = nil
  self.bufnr = nil
  self.is_open = false
  self.current_bufnr = nil
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

function M:vsplit()
  local file = vim.fn.getcwd() .. '/' .. vim.api.nvim_get_current_line()
  self:close()
  vim.cmd('vs')
  vim.cmd.edit(file)
end

function M:hsplit()
  local file = vim.fn.getcwd() .. '/' .. vim.api.nvim_get_current_line()
  self:close()
  vim.cmd('sp')
  vim.cmd.edit(file)
end

function M:select()
  local i = vim.fn.line('.')
  local files = Utils.sanitize(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false))
  self:close() -- this should sync the menu lines with the project marks and the data file

  if #files < i then -- This shouldnt happen, but it's a wild world out there
    return
  end

  Mark.jump(i)
end

function M:set_autocmds()
  autocmd('BufWriteCmd', {
    buffer = self.bufnr,
    callback = function()
      M:sync(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false))
    end,
  })

  autocmd('BufModifiedSet', {
    buffer = self.bufnr,
    callback = function()
      vim.cmd('set nomodified')
    end,
  })

  if Config.mark.save.on_change then
    autocmd({ 'TextChanged', 'TextChangedI' }, {
      buffer = self.bufnr,
      callback = function()
        M:sync(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false))
        set_signs(self.bufnr, self.current_bufnr)
      end,
    })
  end

  autocmd('BufLeave', {
    buffer = self.bufnr,
    callback = function()
      M:close()
    end,
  })
end

local original_highlight = Utils.translate_hl('MsgArea')
function M:open_backdrop()
  if not config.backdrop then
    self.backdrop_bufnr = nil
    self.backdrop_winnr = nil
    return
  end

  self.backdrop_bufnr = vim.api.nvim_create_buf(false, true)
  self.backdrop_winnr = vim.api.nvim_open_win(self.backdrop_bufnr, false, {
    relative = 'editor',
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.columns,
    focusable = false,
    style = 'minimal',
    zindex = 10,
  })

  vim.api.nvim_set_hl(0, 'Backdrop', { bg = '#000000', default = true })
  vim.api.nvim_set_hl(0, 'MsgArea', { bg = '#101215' })
  vim.wo[self.backdrop_winnr].winhighlight = 'Normal:Backdrop'
  vim.wo[self.backdrop_winnr].winblend = 50
  vim.bo[self.backdrop_bufnr].buftype = 'nofile'
end

function M:close_backdrop()
  if not config.backdrop or not self.backdrop_bufnr or not self.backdrop_winnr then
    return
  end

  vim.api.nvim_set_hl(0, 'MsgArea', original_highlight)
  if vim.api.nvim_win_is_valid(self.backdrop_winnr) then
    vim.api.nvim_win_close(self.backdrop_winnr, true)
  end
  if vim.api.nvim_buf_is_valid(self.backdrop_bufnr) then
    vim.api.nvim_buf_delete(self.backdrop_bufnr, { force = true })
  end
end

return M
