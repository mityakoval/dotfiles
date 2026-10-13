local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local function setup_colors()
    return {
        bright_bg = utils.get_highlight("Folded").bg,
        bright_fg = utils.get_highlight("Folded").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        dark_red = utils.get_highlight("DiffDelete").bg,
        green = utils.get_highlight("String").fg,
        blue = utils.get_highlight("Function").fg,
        gray = utils.get_highlight("NonText").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        cyan = utils.get_highlight("Special").fg,
        diag_warn = utils.get_highlight("DiagnosticWarn").fg,
        diag_error = utils.get_highlight("DiagnosticError").fg,
        diag_hint = utils.get_highlight("DiagnosticHint").fg,
        diag_info = utils.get_highlight("DiagnosticInfo").fg,
        git_del = utils.get_highlight("diffDeleted").fg,
        git_add = utils.get_highlight("diffAdded").fg,
        git_change = utils.get_highlight("diffChanged").fg,
    }
end

vim.o.laststatus = 3
vim.o.showcmdloc = "statusline"
-- vim.o.showtabline = 2

require("heirline").setup({
    statusline = require("custom.heirline.statusline").statusline,
    winbar = require("custom.heirline.statusline").winbar,
    tabline = require("custom.heirline.tabline"),
    statuscolumn = require("custom.heirline.statuscolumn"),
    opts = {
        disable_winbar_cb = function(args)
            -- buffer already wiped, e.g. the startup buffer after a session restore
            if not vim.api.nvim_buf_is_valid(args.buf) then
                return true
            end
            -- edgy draws its own titles in the winbar of the windows it manages
            if vim.tbl_contains({ "neo-tree", "snacks_terminal" }, vim.bo[args.buf].filetype) then
                return true
            end
            return conditions.buffer_matches({
                buftype = { "nofile", "prompt", "help", "quickfix" },
                filetype = { "^git.*", "fugitive", "Trouble", "dashboard", "msg", "cmd", "pager", "dialog", "fzf" },
            }, args.buf)
        end,
        colors = setup_colors,
    },
})

vim.o.statuscolumn = require("heirline").eval_statuscolumn()

vim.api.nvim_create_augroup("Heirline", { clear = true })

vim.cmd([[au Heirline FileType * if index(['wipe', 'delete'], &bufhidden) >= 0 | set nobuflisted | endif]])

-- vim.cmd("au BufWinEnter * if &bt != '' | setl stc= | endif")

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        utils.on_colorscheme(setup_colors)
    end,
    group = "Heirline",
})
