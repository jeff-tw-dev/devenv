return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    -- autotag now runs standalone, no longer enabled through treesitter configs
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

    -- the main branch generates parser sources with the tree-sitter CLI and
    -- compiles them with a C compiler; if either is missing, keep the existing
    -- parsers and skip auto-install
    local deps = require("core.deps")
    if deps.need("tree-sitter", "treesitter parser auto-install")
        and deps.need_cc("treesitter parser compilation") then
      require("nvim-treesitter").install(ensure_installed)
    end

    -- the main branch dropped the unified configs.setup (incremental_selection
    -- was removed upstream); highlight / indent attach per buffer via FileType
    local function attach(buf, ft)
      local lang = vim.treesitter.language.get_lang(ft)
      if not (lang and pcall(vim.treesitter.start, buf, lang)) then
        return -- no parser for this filetype: keep regular regex highlight
      end
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("core.treesitter", { clear = true }),
      callback = function(args)
        attach(args.buf, args.match)
      end,
    })

    -- the buffer that triggered this load may already have its filetype set; catch up
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
        attach(buf, vim.bo[buf].filetype)
      end
    end
  end,
}
