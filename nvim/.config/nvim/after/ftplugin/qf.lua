-- Quickfix and location list windows
--  q        close the list
--  <C-n/p>  show the next/previous item in its file, staying in the list

local prefix = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1 and 'l' or 'c'
local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc }) end

map('q', '<Cmd>' .. prefix .. 'close<CR>', 'Close list')
map('<C-n>', '<Cmd>' .. prefix .. 'next<CR>zt<C-w>p', 'Show next item')
map('<C-p>', '<Cmd>' .. prefix .. 'previous<CR>zt<C-w>p', 'Show previous item')

-- Darker background, like the side panels (NormalDark is defined in the kanagawa overrides)
vim.wo.winhighlight = 'Normal:NormalDark'
