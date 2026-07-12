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
      local deps = require("core.deps")
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(client, bufnr)
      end

      -- servers whose install/runtime needs an external toolchain;
      -- only install and start them when that toolchain exists
      local runtime_of = {
        ts_ls = "node",
        tailwindcss = "node",
        svelte = "node",
        pyright = "node",
        jsonls = "node",
        yamlls = "node",
        gopls = "go",
        elixirls = "elixir",
      }

      local ensure_installed = { "lua_ls", "rust_analyzer", "clangd", "taplo" }
      if deps.need("node", "JS/TS/Web LSP (ts_ls, tailwindcss, svelte, pyright, jsonls, yamlls)") then
        vim.list_extend(ensure_installed, { "ts_ls", "tailwindcss", "svelte", "pyright", "jsonls", "yamlls" })
      end
      if deps.need("go", "gopls") then
        table.insert(ensure_installed, "gopls")
      end
      if deps.need("elixir", "elixirls") then
        table.insert(ensure_installed, "elixirls")
      end

      -- even a previously-installed server is skipped when its runtime is
      -- gone, so a machine without node never tries to spawn ts_ls
      local function runtime_ok(server_name)
        local bin = runtime_of[server_name]
        return bin == nil or deps.has(bin)
      end

      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        handlers = {
          function(server_name)
            if server_name ~= "rust_analyzer" and runtime_ok(server_name) then
              lspconfig[server_name].setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end
          end,
          -- JSON: attach schemas from SchemaStore for hover docs on config fields
          ["jsonls"] = function()
            if not runtime_ok("jsonls") then
              return
            end
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
            if not runtime_ok("yamlls") then
              return
            end
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
