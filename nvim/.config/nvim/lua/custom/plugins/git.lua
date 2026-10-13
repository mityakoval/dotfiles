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
vim.keymap.set('n', '<leader>gd', '<Cmd>DiffviewOpen<CR>', { desc = '[D]iff working tree' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Current file [h]istory' })
vim.keymap.set('n', '<leader>gH', '<Cmd>DiffviewFileHistory<CR>', { desc = 'Repo [H]istory' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = '[Q]uit diff view' })
vim.keymap.set('n', '<leader>gb', '<Cmd>Gitsigns blame<CR>', { desc = '[B]lame file' })
