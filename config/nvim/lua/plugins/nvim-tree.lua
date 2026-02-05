return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup({
      view = {
        width = 30,
        side = "left",
      },
      renderer = {
        group_empty = true,
        highlight_git = true,
      },
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
      },
      update_focused_file = {
        enable = true,
        update_root = false,
      },
    })

    vim.cmd([[highlight NvimTreeGitStaged guifg=#50FA7B]])
    vim.cmd([[highlight NvimTreeGitDirty guifg=#FFB86C]])
    vim.cmd([[highlight NvimTreeGitNew guifg=#BD93F9]])
    vim.cmd([[highlight NvimTreeGitRenamed guifg=#FF79C6]])
    vim.cmd([[highlight NvimTreeGitDeleted guifg=#FF5555]])
    vim.cmd([[highlight NvimTreeGitIgnored guifg=#6272A4]])
    vim.cmd([[highlight NvimTreeGitSubmodule guifg=#F1FA8C]])
  end,
}
