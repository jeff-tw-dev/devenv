return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- VSCode cmd+D: select the word under the cursor, press again to add a cursor at the next match
    set({ "n", "x" }, "<C-n>", function()
      mc.matchAddCursor(1)
    end, { desc = "MC: add cursor at next match" })
    set({ "n", "x" }, "<C-p>", function()
      mc.matchAddCursor(-1)
    end, { desc = "MC: add cursor at prev match" })

    -- VSCode cmd+K cmd+D: skip the current match and take the next one
    set({ "n", "x" }, "<C-x>", function()
      mc.matchSkipCursor(1)
    end, { desc = "MC: skip current match" })

    -- VSCode cmd+Shift+L: select all matches at once
    set({ "n", "x" }, "<leader>A", function()
      mc.matchAllAddCursors()
    end, { desc = "MC: add cursors to all matches" })

    -- add cursors on adjacent lines (column editing)
    set({ "n", "x" }, "<C-Up>", function()
      mc.lineAddCursor(-1)
    end, { desc = "MC: add cursor above" })
    set({ "n", "x" }, "<C-Down>", function()
      mc.lineAddCursor(1)
    end, { desc = "MC: add cursor below" })

    -- keymap layer active only while multiple cursors exist
    mc.addKeymapLayer(function(layerSet)
      -- move focus between cursors
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)
      -- delete the focused cursor
      layerSet("n", "<leader>x", mc.deleteCursor)
      -- Esc clears all extra cursors, back to a single cursor
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- highlights follow the colorscheme
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { link = "Cursor" })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  end,
}
