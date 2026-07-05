return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    {
      "<leader>gd",
      function()
        require("core.git_differ").toggle()
      end,
      desc = "Toggle git diff viewer",
    },
    {
      "<leader>gp",
      function()
        require("core.git_differ").older()
      end,
      desc = "Git differ: older commit (n vs n-1)",
    },
    {
      "<leader>gn",
      function()
        require("core.git_differ").newer()
      end,
      desc = "Git differ: newer commit",
    },
    {
      "<leader>gf",
      function()
        require("core.git_differ").find_commit()
      end,
      desc = "Git differ: search commit by message/date",
    },
    {
      "<leader>gc",
      function()
        require("core.git_differ").compare_commits()
      end,
      desc = "Git differ: compare two picked commits",
    },
    {
      "<leader>gm",
      function()
        require("core.git_differ").toggle_message()
      end,
      desc = "Git differ: toggle commit message",
    },
    {
      "<leader>g?",
      function()
        require("core.git_differ").help()
      end,
      desc = "Git differ: keymap help",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File commit history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch commit history" },
  },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      hooks = {
        view_closed = function()
          require("core.git_differ").on_view_closed()
        end,
      },
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
