return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- SchemaStore for jsonls and yamlls
  {
    "b0o/schemastore.nvim",
  },

  { import = "plugins/treesitter" },
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
  {
    "artemave/workspace-diagnostics.nvim"
  },

  {
    "kelly-lin/telescope-ag",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },

  {
    "hedyhli/outline.nvim",
    -- config = function()
    --   require("outline").setup {}
    -- end,
  },
}
