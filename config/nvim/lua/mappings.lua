require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>")

-- terminal
map({"n", "t"}, "<leader>fs", function()
  require("nvchad.term").toggle {
    pos = "bo vsp",
    id = "vertical-full-height-terminal",
    size = "0.5"
  }
end, { desc = "Toggle a vertical full height terminal" })

map({"n", "t"}, "<leader>ff", function()
  require("nvchad.term").toggle {
    pos = "float",
    id = "floating-terminal",
    float_opts = {
      row = 0.05,
      col = 0.1,
      width = 0.8,
      height = 0.8,
    }
  }
end, { desc = "Toggle a floating terminal" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
