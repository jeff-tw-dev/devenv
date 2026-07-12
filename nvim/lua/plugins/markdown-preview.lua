return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = { "markdown" },
  build = "cd app && npx --yes yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    -- mermaid、數學式等由前端 js 處理，預設已開啟
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_theme = "dark"
  end,
}
