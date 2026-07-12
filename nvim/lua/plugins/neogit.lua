-- Magit-style git hub: status buffer with hunk-level staging, commit,
-- branch create/switch/delete, merge/rebase, stash, and a commit graph.
-- Inside the status buffer: s stage, u unstage, c commit popup, b branch
-- popup (b b checkout, b c create), p pull, P push, l log popup, x discard,
-- ? help. Diffs and the merge tool open through diffview.
return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = "Neogit",
  opts = {
    -- unicode commit graph in the log view
    graph_style = "unicode",
    integrations = {
      telescope = true,
      diffview = true,
    },
  },
}
