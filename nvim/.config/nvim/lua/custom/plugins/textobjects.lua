-- nvim-treesitter-textobjects: syntax-aware motions like "next function"
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects

vim.pack.add { { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' } }

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
