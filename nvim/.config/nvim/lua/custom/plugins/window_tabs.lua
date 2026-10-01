-- Per-split tabs, like VS Code editor groups: every split has its own tab bar
-- (drawn in its winbar) listing the files opened in that split.
--   <S-h> / <S-l>   previous / next tab in this split
--   <leader>x       close this tab; closing a split's last tab closes the split
--   mouse           click a tab to switch to it, middle-click to close it
--
-- Only file windows get a bar; side panels, terminals, help, diffs and floats don't.
-- A buffer is deleted only when no split has it as a tab anymore.

local M = {}
local api = vim.api

---@type table<integer, integer[]> window id -> buffers shown as tabs in that window
local tabs = {}
---@type table<integer, integer> window id -> buffer it showed last (new tabs open to its right)
local last = {}

-- `%!` (not `%{}`) so g:statusline_winid is set and the current window is the real one
local WINBAR = "%!v:lua.require'custom.plugins.window_tabs'.render()"

local function index_of(list, value)
  for i, v in ipairs(list) do
    if v == value then return i end
  end
end

local function is_file_buf(buf)
  return api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buflisted
    and vim.bo[buf].buftype == ''
    and not api.nvim_buf_get_name(buf):find('://', 1, true) -- diffview://, fugitive://, …
end

local function is_tab_window(win)
  return api.nvim_win_is_valid(win)
    and api.nvim_win_get_config(win).relative == ''
    and not vim.wo[win].diff
    and is_file_buf(api.nvim_win_get_buf(win))
end

-- Other file windows in the same tabpage
local function other_tab_windows(win)
  local wins = {}
  for _, w in ipairs(api.nvim_tabpage_list_wins(api.nvim_win_get_tabpage(win))) do
    if w ~= win and is_tab_window(w) then table.insert(wins, w) end
  end
  return wins
end

-- Make sure the window's current buffer is one of its tabs
local function track(win)
  if not is_tab_window(win) then return end
  local buf = api.nvim_win_get_buf(win)
  local list = tabs[win] or {}
  tabs[win] = list
  if not index_of(list, buf) then
    local after = last[win] and index_of(list, last[win])
    table.insert(list, after and after + 1 or #list + 1, buf)
  end
  last[win] = buf
end

-- Show our bar in file windows, and remove it from windows that stopped being one
-- (e.g. a split that inherited it and now shows neo-tree). Other plugins' winbars are left alone.
local function update_winbars()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local current = api.nvim_get_option_value('winbar', { scope = 'local', win = win })
    if is_tab_window(win) then
      if current ~= WINBAR then api.nvim_set_option_value('winbar', WINBAR, { scope = 'local', win = win }) end
    elseif current == WINBAR then
      api.nvim_set_option_value('winbar', '', { scope = 'local', win = win })
    end
  end
end

local function label(buf, list)
  local path = api.nvim_buf_get_name(buf)
  if path == '' then return '[No Name]' end
  local name = vim.fn.fnamemodify(path, ':t')
  -- Two tabs with the same file name: add the parent directory to tell them apart
  for _, other in ipairs(list) do
    if other ~= buf and vim.fn.fnamemodify(api.nvim_buf_get_name(other), ':t') == name then
      return vim.fn.fnamemodify(path, ':h:t') .. '/' .. name
    end
  end
  return name
end

function M.render()
  local win = vim.g.statusline_winid
  track(win)
  local list = tabs[win] or {}
  local current = api.nvim_win_get_buf(win)
  local focused = win == api.nvim_get_current_win()

  local parts = {}
  for _, buf in ipairs(list) do
    local hl = buf ~= current and 'WindowTabsInactive' or focused and 'WindowTabsActive' or 'WindowTabsCurrent'
    local path = api.nvim_buf_get_name(buf)
    local icon = (_G.MiniIcons and path ~= '') and (MiniIcons.get('file', path) .. ' ') or ''
    local modified = vim.bo[buf].modified and ' ●' or ''
    local text = (' %s%s%s '):format(icon, label(buf, list), modified):gsub('%%', '%%%%')
    table.insert(parts, ('%%#%s#%%%d@v:lua.WindowTabsClick@%s%%X'):format(hl, buf, text))
  end
  return table.concat(parts) .. (focused and '%#WinBar#' or '%#WinBarNC#')
end

---@param win integer
---@param buf integer
function M.close(win, buf)
  track(win)
  local list = tabs[win] or {}
  local idx = index_of(list, buf)
  if not idx then return end

  -- Is the buffer still needed: a tab in another split, or shown in some other window?
  local needed = false
  for w, l in pairs(tabs) do
    if w ~= win and api.nvim_win_is_valid(w) and index_of(l, buf) then needed = true end
  end
  for _, w in ipairs(vim.fn.win_findbuf(buf)) do
    if w ~= win and not is_tab_window(w) then needed = true end
  end

  if not needed and vim.bo[buf].modified then
    local choice = vim.fn.confirm(('Save changes to "%s"?'):format(label(buf, list)), '&Yes\n&No\n&Cancel', 3)
    if choice == 1 then
      local ok, err = pcall(api.nvim_buf_call, buf, vim.cmd.write)
      if not ok then return vim.notify(tostring(err), vim.log.levels.ERROR) end
    elseif choice ~= 2 then
      return
    end
  end

  table.remove(list, idx)
  if api.nvim_win_get_buf(win) == buf then
    if #list > 0 then
      -- Like VS Code: move to the tab on the right, or the last one
      api.nvim_win_set_buf(win, list[math.min(idx, #list)])
    elseif #other_tab_windows(win) > 0 then
      api.nvim_win_close(win, true)
    else
      -- The only split: keep it, with an empty buffer
      api.nvim_win_call(win, vim.cmd.enew)
    end
  end
  if not needed then pcall(api.nvim_buf_delete, buf, { force = true }) end
  vim.cmd 'redrawstatus!'
end

---@param delta integer
function M.cycle(delta)
  local win = api.nvim_get_current_win()
  if not is_tab_window(win) then return end
  track(win)
  local list = tabs[win]
  if #list < 2 then return end
  local i = index_of(list, api.nvim_win_get_buf(win)) or 1
  api.nvim_win_set_buf(win, list[(i - 1 + delta) % #list + 1])
end

-- Mouse handler for the tabs (see `:help 'statusline'`, the `@` item)
function _G.WindowTabsClick(buf, _, button)
  local win = vim.fn.getmousepos().winid
  if not api.nvim_win_is_valid(win) or not api.nvim_buf_is_valid(buf) then return end
  if button == 'm' then
    M.close(win, buf)
  elseif button == 'l' then
    api.nvim_set_current_win(win)
    api.nvim_win_set_buf(win, buf)
  end
end

-- [[ Highlights ]] (re-applied after a colorscheme change clears them)
local function set_highlights()
  api.nvim_set_hl(0, 'WindowTabsActive', { link = 'TabLineSel', default = true }) -- current tab, focused split
  api.nvim_set_hl(0, 'WindowTabsCurrent', { link = 'WinBar', default = true }) -- current tab, other splits
  api.nvim_set_hl(0, 'WindowTabsInactive', { link = 'TabLine', default = true }) -- other tabs
end
set_highlights()

-- [[ Autocommands ]]
local group = api.nvim_create_augroup('window-tabs', { clear = true })

api.nvim_create_autocmd('ColorScheme', { group = group, callback = set_highlights })

api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function()
    track(api.nvim_get_current_win())
    update_winbars()
  end,
})

api.nvim_create_autocmd({ 'WinEnter', 'TabEnter', 'TermOpen' }, { group = group, callback = update_winbars })
api.nvim_create_autocmd('OptionSet', { group = group, pattern = { 'diff', 'buftype', 'buflisted' }, callback = update_winbars })

api.nvim_create_autocmd('WinClosed', {
  group = group,
  callback = function(ev)
    local win = tonumber(ev.match)
    if win then tabs[win], last[win] = nil, nil end
  end,
})

-- A buffer deleted some other way (`:bd`, a plugin): drop it from every split
api.nvim_create_autocmd('BufDelete', {
  group = group,
  callback = function(ev)
    for win, list in pairs(tabs) do
      local i = index_of(list, ev.buf)
      if i then table.remove(list, i) end
      if last[win] == ev.buf then last[win] = nil end
    end
  end,
})

-- Keep the ● modified markers current in every split
api.nvim_create_autocmd('BufModifiedSet', { group = group, command = 'redrawstatus!' })

-- [[ Keymaps ]]
vim.keymap.set('n', '<S-h>', function() M.cycle(-1) end, { desc = 'Previous tab in this split' })
vim.keymap.set('n', '<S-l>', function() M.cycle(1) end, { desc = 'Next tab in this split' })
vim.keymap.set('n', '<leader>x', function()
  local win = api.nvim_get_current_win()
  if is_tab_window(win) then
    M.close(win, api.nvim_get_current_buf())
  else
    require('snacks').bufdelete()
  end
end, { desc = 'Close tab' })

return M
