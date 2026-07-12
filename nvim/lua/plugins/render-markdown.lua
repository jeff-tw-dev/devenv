return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- 只在打開 markdown 類檔案時載入
  ft = { "markdown", "markdown.mdx", "codecompanion" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- 數學式交給 browser preview（<leader>mp），不裝 latex parser
    latex = { enabled = false },
    -- 游標所在那一行顯示原始 markdown，其他行渲染 —— 方便編輯
    render_modes = { "n", "c", "t" },
    anti_conceal = {
      enabled = true,
    },
    heading = {
      -- 標題用寬底色橫幅呈現
      width = "block",
      min_width = 20,
    },
    code = {
      -- 程式碼區塊有底色與語言標籤
      width = "block",
      min_width = 40,
      border = "thin",
    },
    checkbox = {
      enabled = true,
    },
  },
}
