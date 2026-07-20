return {
  "nvimdev/lspsaga.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("lspsaga").setup({
      ui = {
        code_action = "",
      },
    })

    -- Lspsaga rename fails silently in two cases: it opens the rename box even
    -- when no rename-capable client is attached, and its response handler drops
    -- server errors (rename/init.lua: `if err or not result then return end`) —
    -- which also means the ++project window never opens on a failed rename.
    -- Wrap both paths so a failed rename always produces a visible message.
    -- The wrappers must live on the class table (the module's metatable): saga
    -- rawsets/wipes the module table itself via clean_context() after every
    -- rename, which would strip anything patched there after first use.
    local saga_rename_class = getmetatable(require("lspsaga.rename"))

    local orig_lsp_rename = saga_rename_class.lsp_rename
    saga_rename_class.lsp_rename = function(self, args)
      if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/rename" }) == 0 then
        vim.notify("Rename unavailable: no attached LSP client supports rename", vim.log.levels.WARN)
        return
      end
      return orig_lsp_rename(self, args)
    end

    local orig_do_rename = saga_rename_class.do_rename
    saga_rename_class.do_rename = function(self, project)
      -- saga installs a fresh global rename handler in here, then fires the
      -- async request; wrapping right after keeps the race harmless (worst
      -- case the unwrapped saga handler runs, same as stock behavior)
      orig_do_rename(self, project)
      local installed = vim.lsp.handlers["textDocument/rename"]
      vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx, cfg)
        if err then
          vim.notify("Rename failed: " .. (err.message or vim.inspect(err)), vim.log.levels.ERROR)
          return
        end
        if result == nil or (type(result) == "table" and vim.tbl_isempty(result)) then
          vim.notify("Rename: server returned no changes", vim.log.levels.WARN)
          return
        end
        return installed(err, result, ctx, cfg)
      end
    end
  end,
}
