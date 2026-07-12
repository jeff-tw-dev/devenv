-- set leader key
vim.g.mapleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- external dependency checks (must load before plugins use it in cond/config)
require("core.deps")

-- setup plugins
require("lazy").setup("plugins")

-- load core modules
require("core.options")
require("core.keymaps")
require("core.conflict").setup()
