return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- load only for markdown-like files
  ft = { "markdown", "markdown.mdx", "codecompanion" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- math is handled by the browser preview (<leader>mp), no latex parser
    latex = { enabled = false },
    -- the cursor line shows raw markdown while other lines render — easier editing
    render_modes = { "n", "c", "t" },
    anti_conceal = {
      enabled = true,
    },
    heading = {
      -- headings as full-width colored banners
      width = "block",
      min_width = 20,
    },
    code = {
      -- code blocks get a background and a language label
      width = "block",
      min_width = 40,
      border = "thin",
    },
    checkbox = {
      enabled = true,
    },
  },
}
