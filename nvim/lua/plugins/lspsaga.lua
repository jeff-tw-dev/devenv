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
    -- server errors (rename/init.lua: `if err or not result then return end`).
    -- Wrap both paths so a failed rename always produces a visible message.
    local saga_rename = require("lspsaga.rename")

    local orig_lsp_rename = saga_rename.lsp_rename
    saga_rename.lsp_rename = function(self, args)
      if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/rename" }) == 0 then
        vim.notify("Rename unavailable: no attached LSP client supports rename", vim.log.levels.WARN)
        return
      end
      return orig_lsp_rename(self, args)
    end

    local wrapper
    local orig_do_rename = saga_rename.do_rename
    saga_rename.do_rename = function(self, project)
      orig_do_rename(self, project)
      local installed = vim.lsp.handlers["textDocument/rename"]
      if installed == wrapper then
        return
      end
      wrapper = function(err, result, ctx, cfg)
        if err then
          vim.notify("Rename failed: " .. (err.message or vim.inspect(err)), vim.log.levels.ERROR)
          return
        end
        if result == nil then
          vim.notify("Rename: server returned no changes", vim.log.levels.WARN)
          return
        end
        return installed(err, result, ctx, cfg)
      end
      vim.lsp.handlers["textDocument/rename"] = wrapper
    end
  end,
}
