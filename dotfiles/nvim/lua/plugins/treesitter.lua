return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "svelte",
        "elixir",
        "heex",
        "eex",
        "cpp",
        "c",
        "python",
        "bash",
        "gitignore",
        "json",
        "yaml",
        "toml",
        "rust",
        "go",
      }

    -- parsers are compiled with a C compiler; without one, keep whatever
    -- is already compiled and skip auto-install instead of erroring
    if not require("core.deps").need_cc("treesitter parser 自動編譯") then
      ensure_installed = {}
    end

    require("nvim-treesitter.configs").setup({
      ensure_installed = ensure_installed,
      auto_install = false,
      highlight = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  end,
}
