return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  config = function()
    require("outline").setup({
      outline_window = {
        position = "right",
        width = 25,
        relative_width = true,
        auto_close = false,
        -- 跟隨游標所在符號高亮，並自動捲到視野中
        focus_on_open = false,
        winhl = "",
      },
      outline_items = {
        -- 在符號後面淡色顯示型別/細節（method、interface…）
        show_symbol_details = true,
        show_symbol_lineno = false,
      },
      symbol_folding = {
        autofold_depth = 2,
        -- 游標移到某節點時自動展開它
        auto_unfold = { hovered = true },
      },
      guides = {
        enabled = true,
      },
      preview_window = {
        -- 選到符號時右下角浮窗預覽該段程式碼（不自動跳過去）
        auto_preview = false,
        width = 50,
        min_width = 50,
      },
      symbols = {
        -- 游標所在符號即時追蹤定位
        icon_source = "lspkind",
      },
      keymaps = {
        close = { "<Esc>", "q" },
        goto_location = "<CR>",
        peek_location = "o",
        hover_symbol = "K",
        toggle_preview = "P",
        rename_symbol = "r",
        code_actions = "a",
        fold = "h",
        unfold = "l",
        fold_toggle = "<Tab>",
        fold_all = "W",
        unfold_all = "E",
      },
    })
  end,
}
