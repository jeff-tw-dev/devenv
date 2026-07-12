return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    -- 新版 autotag 獨立運作，不再透過 treesitter configs 啟用
    { "windwp/nvim-ts-autotag", opts = {} },
  },
  config = function()
    local ensure_installed = {
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
      "html",
      "css",
      "javascript",
      "typescript",
      "tsx",
      "svelte",
      "elixir",
      "heex",
      "eex",
      "cpp",
      "c",
      "python",
      "bash",
      "gitignore",
      "json",
      "yaml",
      "toml",
      "rust",
      "go",
    }

    -- 新版 main branch 用 tree-sitter CLI 產生 parser 原始碼再以 C compiler
    -- 編譯；兩者缺一就沿用既有 parser、跳過自動安裝
    local deps = require("core.deps")
    if deps.need("tree-sitter", "treesitter parser 自動安裝")
        and deps.need_cc("treesitter parser 自動編譯") then
      require("nvim-treesitter").install(ensure_installed)
    end

    -- main branch 不再有 configs.setup 統一開關（incremental_selection 已被
    -- 上游移除），highlight / indent 改由 FileType autocmd 逐 buffer 啟用
    local function attach(buf, ft)
      local lang = vim.treesitter.language.get_lang(ft)
      if not (lang and pcall(vim.treesitter.start, buf, lang)) then
        return -- 沒有對應 parser 就維持一般 regex highlight
      end
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("core.treesitter", { clear = true }),
      callback = function(args)
        attach(args.buf, args.match)
      end,
    })

    -- 觸發本次載入的 buffer 可能已經 set 過 filetype，補跑一次
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
        attach(buf, vim.bo[buf].filetype)
      end
    end
  end,
}
