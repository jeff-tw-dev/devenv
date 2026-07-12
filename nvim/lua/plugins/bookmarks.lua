-- Line-level bookmarks: toggle on a line, list/jump via telescope picker
-- (<C-d> in the list deletes a bookmark), tree view for bulk management.
-- Persisted across sessions in a sqlite db (stdpath("data")/bookmarks.sqlite.db).
return {
  "LintaoAmons/bookmarks.nvim",
  tag = "v4.0.0",
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-telescope/telescope.nvim",
  },
  event = "VeryLazy",
  config = function()
    require("bookmarks").setup({
      picker = { picker_backend = "telescope" },
    })
  end,
}
