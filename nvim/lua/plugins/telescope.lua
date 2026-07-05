return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      -- skip entirely when there is no build toolchain, so startup
      -- never errors on machines without make/cc
      cond = function()
        local deps = require("core.deps")
        return deps.has("make") and deps.has_cc()
      end,
    },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = { "truncate" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        },
      },
    })

    -- fall back to the built-in sorter when fzf-native is unavailable
    -- (missing make/cc, or the native lib failed to build)
    if not pcall(telescope.load_extension, "fzf") then
      require("core.deps").note("make/cc", "telescope fzf 原生排序（已改用內建 sorter）")
    end
  end,
}