-- code trace: recursive call tree, extracted to jeff-tw-dev/tracegraph.nvim
-- panel keys: o expand/collapse, <CR> call site, gd definition, p preview, s direction, q quit
return {
  "jeff-tw-dev/tracegraph.nvim",
  keys = {
    {
      "<leader>ct",
      function()
        require("tracegraph").open("incoming")
      end,
      desc = "Trace callers (recursive tree)",
    },
    {
      "<leader>cT",
      function()
        require("tracegraph").open("outgoing")
      end,
      desc = "Trace callees (recursive tree)",
    },
  },
  opts = {},
}
