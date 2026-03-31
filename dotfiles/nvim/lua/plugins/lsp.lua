return {
  -- lsp manager
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  -- JSON/YAML schema catalog
  { "b0o/SchemaStore.nvim", lazy = true },
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
          "pyright",
          "jsonls",
          "yamlls",
          "taplo",
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
          -- JSON: attach schemas from SchemaStore for hover docs on config fields
          ["jsonls"] = function()
            lspconfig.jsonls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                json = {
                  schemas = require("schemastore").json.schemas(),
                  validate = { enable = true },
                },
              },
            })
          end,
          -- YAML: attach schemas from SchemaStore
          ["yamlls"] = function()
            lspconfig.yamlls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                yaml = {
                  schemaStore = { enable = false, url = "" },
                  schemas = require("schemastore").yaml.schemas(),
                },
              },
            })
          end,
          -- TOML: taplo already ships with built-in schemas for Cargo.toml etc.
          ["taplo"] = function()
            lspconfig.taplo.setup({
              on_attach = on_attach,
              capabilities = capabilities,
            })
          end,
        },
      })
    end,
  },
}
