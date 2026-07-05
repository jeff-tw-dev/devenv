return {
  "ray-x/go.nvim",
  dependencies = { -- optional packages
    "ray-x/guihua.lua",
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
  },
  -- don't load at all on machines without the go toolchain
  cond = function()
    return require("core.deps").need("go", "go.nvim（Go 開發指令）")
  end,
  config = function()
    require("go").setup()
  end,
  event = { "CmdlineEnter" },
  ft = { "go", "gomod" },
  build = function()
    -- install/update helper binaries, but only when go exists
    if vim.fn.executable("go") == 1 then
      require("go.install").update_all_sync()
    end
  end,
}
