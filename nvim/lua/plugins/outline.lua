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
        -- highlight the symbol under the cursor and auto-scroll it into view
        focus_on_open = false,
        winhl = "",
      },
      outline_items = {
        -- show type/details dimmed after each symbol (method, interface, ...)
        show_symbol_details = true,
        show_symbol_lineno = false,
      },
      symbol_folding = {
        autofold_depth = 2,
        -- auto-unfold the node under the cursor
        auto_unfold = { hovered = true },
      },
      guides = {
        enabled = true,
      },
      preview_window = {
        -- preview the selected symbol's code in a float (without jumping)
        auto_preview = false,
        width = 50,
        min_width = 50,
      },
      symbols = {
        -- icon source for symbol kinds
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
