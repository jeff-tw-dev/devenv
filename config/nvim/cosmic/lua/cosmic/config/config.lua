local config = {
  -- See :h nvim_open_win for possible border options
  border = 'rounded',
  -- LSP settings
  lsp = {
    -- Enable/disable inlay hints
    inlay_hint = false,
    -- Time in MS before format timeout
    format_timeout = 3000,
    -- Set to false to disable rename notification
    rename_notification = true,
    -- Enable non-default servers, use default lsp config
    -- Check here for configs that will be used by default: https://github.com/williamboman/nvim-lsp-installer/tree/main/lua/nvim-lsp-installer/servers

    -- lsp servers that should be installed
    ensure_installed = {
      'rust_analyzer',
    },

    -- See Cosmic defaults cosmic/plugins/null-ls/init.lua and https://github.com/jose-elias-alvarez/null-ls.nvim/
    -- If adding additional sources, be sure to also copy the defaults that you would like to preserve from cosmic/plugins/null-ls/init.lua
    null_ls = {
      -- Disable default list of sources provided by CosmicNvim
      default_cosmic_sources = false,
      --disable formatting
      format_on_save = false,
      -- Add additional sources here
      get_sources = function()
        local null_ls = require('null-ls')
        return {
          null_ls.builtins.diagnostics.shellcheck,
          null_ls.builtins.diagnostics.actionlint.with({
            condition = function()
              local cwd = vim.fn.expand('%:p:.')
              return cwd:find('.github/workflows')
            end,
          }),
        }
      end,
    },

    -- lsp servers that should be enabled
    servers = {
      -- Enable rust_analyzer
      rust_analyzer = true,
    },
  },

  -- adjust default plugin settings
  plugins = {
    -- See https://github.com/rmagatti/auto-session#%EF%B8%8F-configuration
    auto_session = {},
    -- https://github.com/numToStr/Comment.nvim#configuration-optional
    comment_nvim = {},
    -- See https://github.com/CosmicNvim/cosmic-ui#%EF%B8%8F-configuration
    cosmic_ui = {},
    -- See :h vim.diagnostic.config for all diagnostic configuration options
    diagnostic = {},
    -- See :h gitsigns-usage
    gitsigns = {},
    -- See https://github.com/nvim-lualine/lualine.nvim#default-configuration
    lualine = {},
    -- See https://github.com/L3MON4D3/LuaSnip/blob/577045e9adf325e58f690f4d4b4a293f3dcec1b3/README.md#config
    luasnip = {},
    -- See :h telescope.setup
    telescope = {},
    -- See https://github.com/folke/todo-comments.nvim#%EF%B8%8F-configuration
    todo_comments = {},
    -- See :h nvim-treesitter-quickstart
    treesitter = {},
    -- See :h cmp-usage
    nvim_cmp = {},
    -- See :h nvim-tree.setup
    nvim_tree = {},
  },

  -- Disable plugins default enabled by CosmicNvim
  disable_builtin_plugins = {
    --[[
    'auto-session',
    'colorizer',
    'comment-nvim',
    'dashboard',
    'fugitive',
    'gitsigns',
    'lualine',
    'noice',
    'nvim-cmp',
    'nvim-tree',
    'telescope',
    'terminal',
    'theme',
    'todo-comments',
    'treesitter',
    ]]
  },

  -- Add additional plugins (lazy.nvim)
  add_plugins = {
    {
      "ellisonleao/gruvbox.nvim",
      priority = 50,
      config = true ,
    },
    'ggandor/lightspeed.nvim',
    {
      'romgrk/barbar.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
  },
}

return config
