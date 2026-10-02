-- Neogit: Magit-style git interface
-- https://github.com/NeogitOrg/neogit
-- Diffview: side-by-side diffs and file history
-- https://github.com/sindrets/diffview.nvim

vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/NeogitOrg/neogit',
}

require('diffview').setup {}
-- Neogit detects diffview and telescope automatically
require('neogit').setup {}

require('which-key').add { { '<leader>g', group = '[G]it' } }

vim.keymap.set('n', '<leader>gg', '<Cmd>Neogit<CR>', { desc = 'Neo[g]it status' })
-- Diff of the current file against the index, as a split inside the center column so the
-- side panels stay put. (Diffview always opens a full-screen tab page of its own.)
-- The left side is the index: editing and writing it stages those changes.
vim.keymap.set('n', '<leader>gd', function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    -- Already open: close the index side, gitsigns then turns 'diff' off in the file window
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):find('^gitsigns://') then return vim.api.nvim_win_close(win, false) end
  end
  require('gitsigns').diffthis(nil, { vertical = true })
end, { desc = 'Toggle [d]iff of current file' })
vim.keymap.set('n', '<leader>gD', '<Cmd>DiffviewOpen<CR>', { desc = '[D]iff working tree (full screen)' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Current file [h]istory' })
vim.keymap.set('n', '<leader>gH', '<Cmd>DiffviewFileHistory<CR>', { desc = 'Repo [H]istory' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = '[Q]uit diff view' })

-- [[ Git info in the statusline ]]
-- Replaces mini.statusline's git section with repo-wide info for the working directory:
--    main (● 3 ↑ 2 ↓ 1)   branch, 3 files with uncommitted changes, 2 unpushed commits, 1 commit to pull
-- (↑/↓ only appear when the branch has an upstream; ↓ is as of the last fetch)
-- Refreshed asynchronously with one `git status` call, so the editor never waits on git.

---@type { branch: string, changes: integer, ahead: integer, behind: integer }?
local repo
local running, pending = false, false

local function refresh_repo()
  if running then
    pending = true
    return
  end
  running = true
  vim.system({ 'git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch' }, { text = true, cwd = vim.fn.getcwd() }, function(res)
    local info
    if res.code == 0 then
      info = { changes = 0, ahead = 0, behind = 0 }
      local oid
      for line in res.stdout:gmatch '[^\n]+' do
        local ahead, behind = line:match '^# branch%.ab %+(%d+) %-(%d+)$'
        if ahead then
          info.ahead, info.behind = tonumber(ahead), tonumber(behind)
        elseif line:match '^# branch%.head ' then
          info.branch = line:sub(#'# branch.head ' + 1)
        elseif line:match '^# branch%.oid ' then
          oid = line:sub(#'# branch.oid ' + 1)
        elseif line:sub(1, 1) ~= '#' then
          info.changes = info.changes + 1
        end
      end
      if info.branch == '(detached)' then info.branch = (oid or ''):sub(1, 7) end
    end
    vim.schedule(function()
      repo, running = info, false
      vim.cmd.redrawstatus()
      if pending then
        pending = false
        refresh_repo()
      end
    end)
  end)
end

-- Colors: branch green, uncommitted yellow, unpushed a second green, behind blue.
-- Taken from the tokyonight palette, on the statusline section's own background.
local function set_git_highlights()
  local ok, c = pcall(function()
    local style = vim.g.colors_name:match '^tokyonight%-(%a+)$' -- night, storm, moon, day
    return style and require('tokyonight.colors').setup { style = style }
  end)
  if not ok or not c then c = { green = '#9ece6a', green1 = '#73daca', yellow = '#e0af68', blue = '#7aa2f7' } end
  local bg = vim.api.nvim_get_hl(0, { name = 'MiniStatuslineDevinfo', link = false }).bg
  vim.api.nvim_set_hl(0, 'StatuslineGitBranch', { fg = c.green, bg = bg })
  vim.api.nvim_set_hl(0, 'StatuslineGitChanges', { fg = c.yellow, bg = bg })
  vim.api.nvim_set_hl(0, 'StatuslineGitAhead', { fg = c.green1, bg = bg })
  vim.api.nvim_set_hl(0, 'StatuslineGitBehind', { fg = c.blue, bg = bg })
end
set_git_highlights()

---@diagnostic disable-next-line: duplicate-set-field
require('mini.statusline').section_git = function(args)
  if repo == nil or MiniStatusline.is_truncated(args.trunc_width) then return '' end
  local counts = {}
  if repo.changes > 0 then table.insert(counts, '%#StatuslineGitChanges#● ' .. repo.changes) end
  if repo.ahead > 0 then table.insert(counts, '%#StatuslineGitAhead#↑ ' .. repo.ahead) end
  if repo.behind > 0 then table.insert(counts, '%#StatuslineGitBehind#↓ ' .. repo.behind) end

  local branch = (vim.g.have_nerd_font and ' ' or '') .. repo.branch:gsub('%%', '%%%%')
  local s = '%#StatuslineGitBranch#' .. branch
  if #counts > 0 then s = s .. ' %#MiniStatuslineDevinfo#(' .. table.concat(counts, ' ') .. '%#MiniStatuslineDevinfo#)' end
  -- Back to the section's highlight for the sections that follow (diff, diagnostics, …)
  return s .. '%#MiniStatuslineDevinfo#'
end

local git_group = vim.api.nvim_create_augroup('statusline-git', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', { group = git_group, callback = set_git_highlights })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'FocusGained', 'DirChanged', 'TermClose', 'TermLeave' }, {
  group = git_group,
  callback = refresh_repo,
})
-- Commits, pushes, pulls etc. made from Neogit
vim.api.nvim_create_autocmd('User', { group = git_group, pattern = 'Neogit*', callback = refresh_repo })
refresh_repo()
