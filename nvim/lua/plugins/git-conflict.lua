-- Inline merge-conflict resolution: highlights conflict regions and adds
-- buffer-local keys — co keep ours, ct keep theirs, cb keep both, c0 keep
-- none, ]x / [x next / previous conflict. :GitConflictListQf collects all
-- conflicts into the quickfix list. For hairy conflicts use the diffview
-- merge tool (<leader>gd during a merge shows the 3-way view).
return {
  "akinsho/git-conflict.nvim",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    default_mappings = true,
    -- keep false: the disable_diagnostics path calls the pre-0.11
    -- vim.diagnostic.enable(bufnr) signature and errors on resolve
    disable_diagnostics = false,
  },
}
