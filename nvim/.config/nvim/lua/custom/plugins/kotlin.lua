-- Kotlin development
-- kotlin_lsp (JetBrains, IntelliJ-based) is enabled + installed via `servers` in init.lua;
-- this only adds Kotlin-specific keymaps on top of the default LSP ones.
-- https://github.com/Kotlin/kotlin-lsp

vim.lsp.config('kotlin_lsp', {
  on_attach = function(client, bufnr)
    local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = bufnr, desc = 'Kotlin: ' .. desc }) end
    -- Apply the code action of the given kind directly (prompts if there are several)
    local action = function(kind)
      return function() vim.lsp.buf.code_action { context = { only = { kind }, diagnostics = {} }, apply = true } end
    end
    local builtin = require 'telescope.builtin'

    map('<leader>ko', action 'source.organizeImports', '[O]rganize imports')
    map('<leader>kq', action 'quickfix', '[Q]uick fix', { 'n', 'x' })
    map('<leader>kv', action 'refactor.extract.variable', 'Extract [v]ariable', { 'n', 'x' })
    map('<leader>ki', action 'refactor.inline.variable', '[I]nline variable')
    map('<leader>kc', builtin.lsp_incoming_calls, 'Incoming [c]alls')
    map('<leader>kC', builtin.lsp_outgoing_calls, 'Outgoing [C]alls')
    map('<leader>ks', function() vim.lsp.buf.typehierarchy 'subtypes' end, '[S]ubtypes')
    map('<leader>kS', function() vim.lsp.buf.typehierarchy 'supertypes' end, '[S]upertypes')

    -- `:make <task>` runs Gradle in the project root; compiler errors land in the quickfix list
    local root = client.root_dir or vim.fn.getcwd()
    local gradlew = root .. '/gradlew'
    vim.bo[bufnr].makeprg = vim.fn.shellescape(vim.uv.fs_stat(gradlew) and gradlew or 'gradle') .. ' -q --console=plain -p ' .. vim.fn.shellescape(root)
    vim.bo[bufnr].errorformat = '%t: file://%f:%l:%c %m'
    map('<leader>kb', '<cmd>make testClasses<CR>', '[B]uild (compile main + test)')
  end,
})

require('which-key').add { { '<leader>k', group = '[K]otlin' } }
