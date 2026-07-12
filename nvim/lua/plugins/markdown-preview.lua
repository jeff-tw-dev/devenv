return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = { "markdown" },
  build = "cd app && npx --yes yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    -- mermaid, math etc. are handled by the frontend js, enabled by default
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_theme = "dark"
  end,
}
