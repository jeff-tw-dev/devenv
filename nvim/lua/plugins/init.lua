return {
  -- colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- floating command line
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        -- you can enable a preset theme here
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to lsp doc highlights
        },
        routes = {
          {
            filter = {
              event = "lsp",
              kind = "hover",
            },
            opts = { skip = true },
          },
        },
      })
    end,
  },

  -- nvim-tree
  require("plugins.nvim-tree"),

  -- autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- bufdelete
  {
    "famiu/bufdelete.nvim",
  },

  -- fuzzy finder
  require("plugins.telescope"),

  -- flash
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- lsp
  require("plugins.lsp"),

  -- autocompletion
  require("plugins.cmp"),

  -- lspsaga
  require("plugins.lspsaga"),

  -- outline
  require("plugins.outline"),

  -- markdown 編輯器內即時渲染
  require("plugins.render-markdown"),

  -- markdown 瀏覽器預覽 (內建 mermaid / 數學式)
  require("plugins.markdown-preview"),

  -- multicursor (VSCode cmd+D 風格多游標)
  require("plugins.multicursor"),

  -- trouble
  require("plugins.trouble"),

  -- gitsigns
  require("plugins.gitsigns"),

  -- diffview
  require("plugins.diffview"),

  -- lualine
  require("plugins.lualine"),

  -- bufferline
  require("plugins.bufferline"),

  -- toggleterm
  require("plugins.toggleterm"),

  -- treesitter
  require("plugins.treesitter"),

  -- neotest
  require("plugins.neotest"),

  -- lang extras
  require("plugins.lang_extras"),

  -- rust
  require("plugins.rust"),

  -- go
  require("plugins.go"),
}
