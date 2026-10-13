-- IDE-style layout:
--   left:   neo-tree file tree (top) + neo-tree git status (bottom)
--   center: files (buffer tabline + winbar from heirline, see heirline.lua)
--   bottom: shell terminal (<C-/>)
--   right:  Claude Code (claudecode.nvim)
-- edgy.nvim keeps the side panels pinned in place.
--
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- https://github.com/folke/edgy.nvim
-- https://github.com/coder/claudecode.nvim
-- https://github.com/folke/snacks.nvim (terminal provider for claudecode)
--
-- Everything is in one file because the plugins depend on each other.

-- edgy works best with a single global statusline
vim.o.laststatus = 3
vim.o.splitkeep = 'screen'

vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '3' },
  'https://github.com/folke/edgy.nvim',
  'https://github.com/folke/snacks.nvim',
  'https://github.com/coder/claudecode.nvim',
}

-- Is this window the Claude Code terminal?
local function is_claude(buf, win)
  local term = vim.b[buf].snacks_terminal
  return term ~= nil and vim.api.nvim_win_get_config(win).relative == '' and vim.inspect(term.cmd):find 'claude' ~= nil
end

-- Is this window a plain shell terminal (split, not Claude)?
local function is_shell(buf, win)
  return vim.b[buf].snacks_terminal ~= nil and vim.api.nvim_win_get_config(win).relative == '' and not is_claude(buf, win)
end

-- [[ neo-tree ]]
require('neo-tree').setup {
  sources = { 'filesystem', 'git_status' },
  filesystem = {
    follow_current_file = { enabled = true },
    -- Collapse chains of single-child folders (src/main/java/com/…) into one line,
    -- so deeply nested files don't get pushed off the narrow sidebar
    group_empty_dirs = true,
    scan_mode = 'deep',
    use_libuv_file_watcher = true,
  },
}

-- [[ Claude Code ]]
require('claudecode').setup {
  terminal = {
    split_side = 'right',
    provider = 'snacks',
    snacks_win_opts = {
      keys = {
        -- Let Esc / Esc Esc reach Claude (interrupt / rewind) instead of leaving terminal mode.
        -- Disables snacks' double-Esc, and overrides kickstart's global <Esc><Esc> in this buffer.
        term_normal = false,
        -- (snacks only sends string mappings as keys when `expr = true`)
        claude_esc = { '<Esc>', '<Esc>', mode = 't', expr = true, desc = 'Send Esc to Claude' },
        -- Ctrl-h jumps out of Claude to the window on the left
        claude_left = { '<C-h>', '<C-\\><C-n><C-w>h', mode = 't', expr = true, desc = 'Move focus to the left window' },
      },
    },
  },
  diff_opts = {
    layout = 'vertical',
    open_in_new_tab = false,
  },
}

-- [[ edgy: pinned side panels ]]
require('edgy').setup {
  animate = { enabled = false },
  options = {
    left = { size = 40 },
  },
  left = {
    {
      title = 'Files',
      ft = 'neo-tree',
      filter = function(buf) return vim.b[buf].neo_tree_source == 'filesystem' end,
      pinned = true,
      open = 'Neotree action=show source=filesystem position=left',
      size = { height = 0.6 },
    },
    {
      title = 'Git',
      ft = 'neo-tree',
      filter = function(buf) return vim.b[buf].neo_tree_source == 'git_status' end,
      pinned = true,
      -- Opened at another position because neo-tree allows one window per position; edgy moves it left
      open = 'Neotree action=show source=git_status position=right',
      size = { height = 0.4 },
    },
  },
  right = {
    {
      title = 'Claude',
      ft = 'snacks_terminal',
      filter = is_claude,
      size = { width = 0.35 },
    },
  },
  bottom = {
    {
      title = 'Terminal',
      ft = 'snacks_terminal',
      filter = is_shell,
      size = { height = 0.3 },
    },
  },
}

-- `:q` in the last file window quits Neovim instead of leaving only the panels.
-- (Not edgy's `exit_when_last`: when unsaved changes block it, edgy leaves no file window.)
-- Close the panels first so `:q` sees a single window and applies its normal checks,
-- including `:q!`. If Neovim refuses to quit, put the panels back.
vim.api.nvim_create_autocmd('QuitPre', {
  callback = function()
    local wins = require('edgy.editor').list_wins()
    local cur = vim.api.nvim_get_current_win()
    if not wins.main[cur] or vim.tbl_count(wins.main) > 1 or vim.tbl_isempty(wins.edgy) then return end

    local sidebar_was_open, claude_was_open = false, false
    for _, win in pairs(wins.edgy) do
      local buf = vim.api.nvim_win_get_buf(win)
      sidebar_was_open = sidebar_was_open or vim.bo[buf].filetype == 'neo-tree'
      claude_was_open = claude_was_open or is_claude(buf, win)
    end
    require('edgy').close()

    -- Only runs if Neovim is still alive after the `:q`. Reopens the panels directly:
    -- edgy closes windows without autocmds, so `edgy.open()` would think they're still open.
    vim.schedule(function()
      if sidebar_was_open then
        vim.cmd 'Neotree action=show source=filesystem position=left'
        vim.cmd 'Neotree action=show source=git_status position=right'
      end
      if claude_was_open then vim.cmd 'ClaudeCodeOpen' end
      vim.api.nvim_set_current_win(cur)
    end)
  end,
})

-- Drop the empty [No Name] tab Neovim starts with once a real file is opened
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(ev)
    if vim.api.nvim_buf_get_name(ev.buf) == '' then return end
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.bo[buf].buflisted
          and vim.bo[buf].buftype == ''
          and vim.api.nvim_buf_get_name(buf) == ''
          and not vim.bo[buf].modified
          and vim.api.nvim_buf_line_count(buf) == 1
          and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
          and #vim.fn.win_findbuf(buf) == 0 -- not shown in any tab page
        then
          vim.api.nvim_buf_delete(buf, {})
        end
      end
    end)
  end,
})

-- [[ Startup: open the sidebar (but not when reading from stdin, e.g. `git diff | nvim -`) ]]
local reading_stdin = false
vim.api.nvim_create_autocmd('StdinReadPre', {
  callback = function() reading_stdin = true end,
})
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if reading_stdin then return end
    -- (A restored session, see init.lua, counts as having files to edit)
    if vim.fn.argc() == 0 and vim.v.this_session == '' then
      -- With no file to edit, start in the file tree. Focus it first: `show` returns
      -- focus to whatever window was active when it was called, which is now the tree.
      vim.cmd 'Neotree action=focus source=filesystem position=left'
      vim.cmd 'Neotree action=show source=git_status position=right'
    else
      require('edgy').open 'left'
    end
  end,
})

-- [[ Keymaps ]]
vim.keymap.set('n', '\\', function() require('edgy').toggle 'left' end, { desc = 'Toggle sidebar' })

-- Moving left into the sidebar always lands in the file tree (<C-j> from there reaches Git).
-- Plain <C-w>h picks whichever panel is level with the cursor, often the Git one.
vim.keymap.set('n', '<C-h>', function()
  local from = vim.api.nvim_get_current_win()
  vim.cmd 'wincmd h'
  local to = vim.api.nvim_get_current_win()
  if to == from or vim.bo.filetype ~= 'neo-tree' or vim.bo[vim.api.nvim_win_get_buf(from)].filetype == 'neo-tree' then return end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source == 'filesystem' then return vim.api.nvim_set_current_win(win) end
  end
end, { desc = 'Move focus to the left window' })

-- Terminal panel below the files. Hiding keeps the shell running.
-- (<C-_> is what many terminals send for <C-/>)
local function toggle_terminal()
  require('snacks').terminal.toggle(nil, {
    win = {
      keys = {
        hide_slash = { '<C-/>', 'hide', mode = 't', desc = 'Hide terminal' },
        hide_underscore = { '<C-_>', 'hide', mode = 't', desc = 'Hide terminal' },
      },
    },
  })
end
vim.keymap.set('n', '<C-/>', toggle_terminal, { desc = 'Toggle terminal' })
vim.keymap.set('n', '<C-_>', toggle_terminal, { desc = 'Toggle terminal' })

require('which-key').add { { '<leader>a', group = '[A]I / Claude' } }
vim.keymap.set('n', '<leader>ac', '<Cmd>ClaudeCode<CR>', { desc = 'Toggle Claude' })
vim.keymap.set('n', '<leader>af', '<Cmd>ClaudeCodeFocus<CR>', { desc = 'Focus Claude' })
vim.keymap.set('n', '<leader>ar', '<Cmd>ClaudeCode --resume<CR>', { desc = 'Resume Claude session' })
vim.keymap.set('n', '<leader>ab', '<Cmd>ClaudeCodeAdd %<CR>', { desc = 'Add current file to Claude' })
vim.keymap.set('v', '<leader>as', '<Cmd>ClaudeCodeSend<CR>', { desc = 'Send selection to Claude' })
vim.keymap.set('n', '<leader>aa', '<Cmd>ClaudeCodeDiffAccept<CR>', { desc = 'Accept Claude diff' })
vim.keymap.set('n', '<leader>ad', '<Cmd>ClaudeCodeDiffDeny<CR>', { desc = 'Reject Claude diff' })
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'neo-tree',
  callback = function(ev) vim.keymap.set('n', '<leader>as', '<Cmd>ClaudeCodeTreeAdd<CR>', { buffer = ev.buf, desc = 'Add file to Claude' }) end,
})
