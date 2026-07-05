return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Adapters
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
    "alfaix/neotest-gtest",
    "nvim-neotest/neotest-jest",
    "marilari88/neotest-vitest",
    "jfpedroza/neotest-elixir",
  },
  keys = {
    { "<leader>t", "", desc = "+test" },
    { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
    { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
  },
  config = function()
    local deps = require("core.deps")

    -- only register adapters whose runtime exists on this machine
    local adapters = {
      require("neotest-plenary"),
      require("neotest-gtest").setup({}),
    }
    if deps.need("python3", "neotest-python") then
      table.insert(adapters, require("neotest-python")({
        dap = { justMyCode = false },
      }))
    end
    if deps.need("node", "neotest jest/vitest") then
      table.insert(adapters, require("neotest-jest")({
        jestCommand = "npm test --",
        jestConfigFile = "custom.jest.config.ts",
        env = { CI = true },
        cwd = function(path)
          return vim.fn.getcwd()
        end,
      }))
      table.insert(adapters, require("neotest-vitest"))
    end
    if deps.need("elixir", "neotest-elixir") then
      table.insert(adapters, require("neotest-elixir"))
    end

    require("neotest").setup({
      adapters = adapters,
    })
  end,
}
