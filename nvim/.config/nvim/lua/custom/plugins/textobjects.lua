-- nvim-treesitter-textobjects: syntax-aware motions like "next function"
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
-- (the text objects themselves, `F` function and `c` class, are in mini.ai's setup in init.lua)
--
-- nvim-treesitter-context: keeps the enclosing function/impl signature pinned at the top of the window
-- https://github.com/nvim-treesitter/nvim-treesitter-context

vim.pack.add {
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
}

require('treesitter-context').setup {}

require('nvim-treesitter-textobjects').setup {
  move = {
    -- Add jumps to the jumplist, so <C-o> takes you back
    set_jumps = true,
  },
}

local move = require 'nvim-treesitter-textobjects.move'
local function map(lhs, fn, query, desc)
  vim.keymap.set({ 'n', 'x', 'o' }, lhs, function() move[fn](query, 'textobjects') end, { desc = desc })
end

map(']f', 'goto_next_start', '@function.outer', 'Next function start')
map('[f', 'goto_previous_start', '@function.outer', 'Previous function start')
map(']F', 'goto_next_end', '@function.outer', 'Next function end')
map('[F', 'goto_previous_end', '@function.outer', 'Previous function end')
map(']a', 'goto_next_start', '@parameter.inner', 'Next argument')
map('[a', 'goto_previous_start', '@parameter.inner', 'Previous argument')
map(']m', 'goto_next_start', '@class.outer', 'Next struct/enum/impl')
map('[m', 'goto_previous_start', '@class.outer', 'Previous struct/enum/impl')

local swap = require 'nvim-treesitter-textobjects.swap'
vim.keymap.set('n', '<leader>]', function() swap.swap_next '@parameter.inner' end, { desc = 'Swap argument with next' })
vim.keymap.set('n', '<leader>[', function() swap.swap_previous '@parameter.inner' end, { desc = 'Swap argument with previous' })
