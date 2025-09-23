local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

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
  "elixirls",
  "jsonls",
  "yamlls",
  "clangd",
  "bashls",
  "docker_language_server",
  "graphql",
  -- "lua_ls",
  "pyright",
  "tailwindcss",
  "systemd_ls",
  "biome",
}

local server_configs = {
  jsonls = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  }
}

-- Update configs
local lspconfig = vim.lsp.config
lspconfig("*", {
  root_markers = { ".git" },
})

for _, server_name in ipairs(servers) do
  local server_opts = {
    on_attach = on_attach,
    capabilities = capabilities,

    -- language server settings
    settings = server_configs[server_name]
  }

  lspconfig(server_name, server_opts)
end

-- Enable configs 
vim.lsp.enable(servers)
