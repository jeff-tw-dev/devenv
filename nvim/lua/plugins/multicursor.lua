return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- VSCode cmd+D：選游標下的字，再按加下一個相同字的游標
    set({ "n", "x" }, "<C-n>", function()
      mc.matchAddCursor(1)
    end, { desc = "MC: add cursor at next match" })
    set({ "n", "x" }, "<C-p>", function()
      mc.matchAddCursor(-1)
    end, { desc = "MC: add cursor at prev match" })

    -- VSCode cmd+K cmd+D：跳過當前 match，改選下一個
    set({ "n", "x" }, "<C-x>", function()
      mc.matchSkipCursor(1)
    end, { desc = "MC: skip current match" })

    -- VSCode cmd+Shift+L：一次選取全部相同字
    set({ "n", "x" }, "<leader>A", function()
      mc.matchAllAddCursors()
    end, { desc = "MC: add cursors to all matches" })

    -- 上下相鄰行加游標（欄編輯）
    set({ "n", "x" }, "<C-Up>", function()
      mc.lineAddCursor(-1)
    end, { desc = "MC: add cursor above" })
    set({ "n", "x" }, "<C-Down>", function()
      mc.lineAddCursor(1)
    end, { desc = "MC: add cursor below" })

    -- 多游標啟用期間才生效的按鍵層
    mc.addKeymapLayer(function(layerSet)
      -- 在游標之間切換 focus
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)
      -- 刪掉當前 focus 的那顆游標
      layerSet("n", "<leader>x", mc.deleteCursor)
      -- Esc 清除所有額外游標，回到單游標
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- 高亮跟隨主題
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { link = "Cursor" })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  end,
}
