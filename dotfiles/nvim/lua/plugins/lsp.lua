return {
  -- lsp manager
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(client, bufnr)
      end

      require("mason-lspconfig").setup({
        ensure_installed = { 
          "lua_ls",
          "rust_analyzer",
          "gopls",
          "tsserver",
          "clangd",
          "tailwindcss",
          "svelte",
          "elixirls",
          "pyright"
        },
        handlers = {
          function(server_name)
            if server_name ~= "rust_analyzer" then
              lspconfig[server_name].setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end
          end,
        },
      })
    end,
  },
}
