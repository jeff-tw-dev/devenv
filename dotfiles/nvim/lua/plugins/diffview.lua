return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    {
      "<leader>gd",
      function()
        local view = require("diffview.lib").get_current_view()
        if view then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end,
      desc = "Toggle git diff viewer",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File commit history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch commit history" },
  },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      keymaps = {
        file_history_panel = {
          { "n", "<C-j>", actions.select_next_entry, { desc = "Next commit" } },
          { "n", "<C-k>", actions.select_prev_entry, { desc = "Previous commit" } },
        },
        file_panel = {
          { "n", "<C-j>", actions.select_next_entry, { desc = "Next file" } },
          { "n", "<C-k>", actions.select_prev_entry, { desc = "Previous file" } },
        },
      },
    })
  end,
}
