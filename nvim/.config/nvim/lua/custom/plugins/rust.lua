-- Rust development
-- rustaceanvim: manages rust-analyzer (do NOT also enable `rust_analyzer` via vim.lsp.enable)
-- https://github.com/mrcjkb/rustaceanvim
-- crates.nvim: Cargo.toml dependency versions, features and completion
-- https://github.com/saecki/crates.nvim

-- Must be set before rustaceanvim loads
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = { allFeatures = true },
        check = { command = 'clippy' },
        procMacro = { enable = true },
      },
    },
    on_attach = function(_, bufnr)
      local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc }) end
      local rust = function(...)
        local args = { ... }
        return function() vim.cmd.RustLsp(args) end
      end

      -- Rust-aware replacements for the default LSP maps
      map('gra', rust 'codeAction', '[G]oto Code [A]ction', { 'n', 'x' })
      map('K', rust('hover', 'actions'), 'Hover actions')

      map('<leader>rr', rust 'runnables', '[R]unnables')
      map('<leader>rR', rust('runnables', 'last'), '[R]erun last runnable')
      map('<leader>rt', rust 'testables', '[T]estables')
      map('<leader>rd', rust 'debuggables', '[D]ebuggables')
      map('<leader>rD', rust('debuggables', 'last'), '[D]ebug last')
      map('<leader>re', rust 'explainError', '[E]xplain error')
      map('<leader>rx', rust 'renderDiagnostic', 'Render diagnostic')
      map('<leader>rm', rust 'expandMacro', 'Expand [m]acro')
      map('<leader>rc', rust 'openCargo', 'Open [C]argo.toml')
      map('<leader>rp', rust 'parentModule', '[P]arent module')
      map('<leader>ro', rust 'openDocs', '[O]pen docs.rs')
      map('<leader>rj', rust 'joinLines', '[J]oin lines', { 'n', 'x' })
      map('<leader>rk', rust('moveItem', 'up'), 'Move item up')
      map('<leader>rK', rust('moveItem', 'down'), 'Move item down')
    end,
  },
}

vim.pack.add {
  { src = 'https://github.com/mrcjkb/rustaceanvim', version = vim.version.range '*' },
  { src = 'https://github.com/saecki/crates.nvim', version = 'stable' },
}

require('crates').setup {
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    hover = true,
  },
  completion = { crates = { enabled = true } },
}

require('which-key').add { { '<leader>r', group = '[R]ust' } }
