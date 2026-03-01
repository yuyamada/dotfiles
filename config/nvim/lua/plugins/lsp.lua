return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
      -- lua-language-server 3.17+ は lazydev と非互換のため 3.16.4 に固定
      local pkg = require("mason-registry").get_package("lua-language-server")
      if not pkg:is_installed() then
        pkg:install({ version = "3.16.4" })
      end
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "lua_ls", "basedpyright", "gopls" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim", "folke/lazydev.nvim" },
    config = function()
      -- lazydev との統合（native LSP API 用）
      require("lazydev.integrations.lspconfig").setup()

      -- Neovim 0.11 native LSP API (replaces lspconfig.server.setup())
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable({ "lua_ls", "basedpyright", "gopls" })

      -- diagnostic のインライン表示（LSP 設定後に適用）
      vim.diagnostic.config({
        virtual_text = true,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })
    end,
  },
}
