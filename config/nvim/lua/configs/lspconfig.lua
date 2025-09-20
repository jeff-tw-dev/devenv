require("nvchad.configs.lspconfig").defaults()
-- local on_attach = require("nvchad.configs.lspconfig").on_attach
-- local capabilities = require("nvchad.configs.lspconfig").capabilities

local servers = {
  "gopls",
  "rust_analyzer",
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "astro",
  "svelte",
  "cmake",
  "elixir_ls",
  "jsonls",
  "yamlls",
  "clangd",
  "bashls",
  "docker_language_server",
  "graphql",
  "luals",
  "pyright",
  "tailwindcss",
  "systemd_ls",
  "biome",
}
vim.lsp.enable(servers)

vim.lsp.config(
  "jsonls",
  {
    settings = {
      json = {
        schemas = require("schemastore").json.schemas(),
        validate = { enable = true },
      },
    }
  }
)

-- Other configs...
-- lspconfig.tsserver.setup { ... }
-- lspconfig.pyright.setup { ... }

-- read :h vim.lsp.config for changing options of lsp servers 
