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
        local keymap = vim.keymap
        keymap.set("n", "gd", "<cmd>vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
        keymap.set("n", "gt", "<cmd>vim.lsp.buf.type_definition()<CR>", { desc = "Go to type definition" })
        keymap.set("n", "<leader>r", "<cmd>Telescope lsp_references<CR>", { desc = "Go to references" })
        keymap.set("n", "<leader>i", "<cmd>vim.lsp.buf.implementation()<CR>", { desc = "Go to implementation" })
        keymap.set("n", "<leader>s", "<cmd>Lspsaga goto_source<CR>", { desc = "Go to source definition" })
        keymap.set("n", "<S-k>", "<cmd>vim.lsp.buf.hover()<CR>", { desc = "Peek type/doc of code under cursor" })
      end

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "rust_analyzer", "gopls", "tsserver", "clangd" },
        handlers = {
          function(server_name)
            lspconfig[server_name].setup({
              on_attach = on_attach,
              capabilities = capabilities,
            })
          end,
        },
      })
    end,
  },
}
