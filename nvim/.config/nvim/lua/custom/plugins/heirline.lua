-- Heirline: statusline, winbar, tabline and statuscolumn
-- https://github.com/rebelot/heirline.nvim
-- Components are copied from rebelot's own config, see `lua/custom/heirline/`
-- https://github.com/rebelot/dotfiles/tree/master/nvim/lua/plugins/heirline

vim.pack.add {
  'https://github.com/rebelot/heirline.nvim',
  'https://github.com/SmiteshP/nvim-navic',
}

-- Code context (breadcrumbs) for the winbar
require('nvim-navic').setup { separator = '', lsp = { auto_attach = true } }

require 'custom.heirline'

-- The tabline lists buffers, so cycle and close buffers
vim.keymap.set('n', '<S-h>', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', '<Cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>x', function() require('snacks').bufdelete() end, { desc = 'Close buffer' })
