-- Add indentation guides even on blank lines

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }
-- Highlight the guide of the current scope, without underlining its first/last line
-- Thin guides; their colors are in the kanagawa overrides in init.lua
require('ibl').setup {
  indent = { char = '▏' },
  scope = { show_start = false, show_end = false },
}
