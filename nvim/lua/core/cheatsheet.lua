-- All-keymaps cheatsheet: one fuzzy-searchable Telescope picker over
-- every keybinding in this config — live-registered global/buffer maps
-- (anything with a desc) PLUS a curated registry of context-local keys
-- that only exist while a panel or mode is active (tracegraph, projinfo,
-- bookmark list, conflict buffers, Neogit, cmp, ...). <CR> jumps to the
-- line that defines the mapping when the source is known.
local M = {}

-- Keys that are only registered (or hardcoded by a plugin) inside a
-- specific context, so nvim_get_keymap can't see them from outside.
local CONTEXT_KEYS = {
  ["trace panel"] = {
    { "n", "o / <Tab>", "Expand/collapse node (lazy LSP request)" },
    { "n", "<CR>", "Jump to call site" },
    { "n", "gd", "Jump to definition" },
    { "n", "p", "Preview call site in float" },
    { "n", "s", "Switch incoming/outgoing" },
    { "n", "q", "Close panel" },
  },
  ["project info"] = {
    { "n", "<CR>", "Jump to definition line" },
    { "n", "<Tab> / za", "Fold/unfold section or project" },
    { "n", "zM / zR", "Fold / unfold everything" },
    { "n", "r", "Run script/target in toggleterm" },
    { "n", "v", "Reveal/mask env values" },
    { "n", "a", "Add env var to file under cursor" },
    { "n", "q", "Close panel" },
  },
  ["bookmark list"] = {
    { "n", "<CR>", "Jump to bookmark" },
    { "n", "dd", "Delete bookmark" },
    { "n", "e", "Edit bookmark note" },
    { "n", "q", "Close panel" },
  },
  ["conflict buffer"] = {
    { "n", "co", "Keep ours" },
    { "n", "ct", "Keep theirs" },
    { "n", "cb", "Keep both" },
    { "n", "c0", "Keep none" },
    { "n", "]x / [x", "Next / previous conflict" },
  },
  ["multicursor active"] = {
    { "n", "<Left> / <Right>", "Focus previous / next cursor" },
    { "n", "<leader>x", "Delete focused cursor" },
    { "n", "<Esc>", "Clear extra cursors" },
  },
  ["neogit status"] = {
    { "n", "s / u", "Stage / unstage" },
    { "n", "c", "Commit popup" },
    { "n", "b", "Branch popup (b b checkout, b c create)" },
    { "n", "p / P", "Pull / push popup" },
    { "n", "l", "Log popup (graph)" },
    { "n", "x", "Discard" },
    { "n", "<Tab>", "Expand/collapse diff" },
    { "n", "?", "Neogit help" },
  },
  ["outline panel"] = {
    { "n", "<CR>", "Go to symbol" },
    { "n", "o", "Peek location" },
    { "n", "K", "Hover symbol" },
    { "n", "P", "Toggle preview" },
    { "n", "r", "Rename symbol" },
    { "n", "a", "Code actions" },
    { "n", "h / l / <Tab>", "Fold / unfold / toggle" },
    { "n", "W / E", "Fold all / unfold all" },
  },
  ["telescope prompt"] = {
    { "i", "<C-j> / <C-k>", "Next / previous result" },
    { "i", "<C-q>", "Send results to quickfix" },
  },
  ["completion menu"] = {
    { "i", "<C-j> / <C-k>", "Next / previous item" },
    { "i", "<C-b> / <C-f>", "Scroll docs" },
    { "i", "<C-Space>", "Trigger completion" },
    { "i", "<C-e>", "Abort" },
    { "i", "<CR>", "Confirm selection" },
  },
  ["diffview panel"] = {
    { "n", "<C-j> / <C-k>", "Next / previous file (or commit entry)" },
    { "n", "<Tab> / <S-Tab>", "Select file and open diff" },
    { "n", "[c / ]c", "Previous / next change hunk" },
    { "n", "g?", "Diffview built-in help" },
  },
  ["mermaid float"] = {
    { "n", "q / <Esc>", "Close float" },
  },
  ["llm marks panel"] = {
    { "n", "<CR>", "Jump to mark" },
    { "n", "dd", "Delete mark" },
    { "n", "e", "Edit mark note" },
    { "n", "C", "Clear all marks" },
    { "n", "q", "Close panel" },
  },
  ["llm history panel"] = {
    { "n", "<CR>", "Open exchange in vsplit" },
    { "n", "dd", "Delete exchange" },
    { "n", "q", "Close panel" },
  },
}

---------------------------------------------------------------------------
-- Collection
---------------------------------------------------------------------------

local MODES = { "n", "v", "x", "i", "t", "c", "o" }

-- internal byte representation -> readable key notation; lhs already in
-- notation form (contains no control bytes) is kept as-is
local function pretty_lhs(lhs)
  local disp = lhs:find("[%c\128-\255]") and vim.fn.keytrans(lhs) or lhs
  disp = disp:gsub("^<Space>", "<leader>"):gsub("^ ", "<leader>")
  return disp
end

-- find where a mapping is defined by searching the config source for its
-- lhs literal (lua-callback maps carry no line info in nvim_get_keymap)
local function definition_location(disp_lhs)
  if vim.fn.executable("rg") ~= 1 then
    return nil
  end
  local config = vim.fn.stdpath("config")
  local pattern = ('["\']%s["\']'):format(vim.fn.escape(disp_lhs, "[](){}.*+?^$|\\"))
  local hits = vim.fn.systemlist({ "rg", "--line-number", "--no-heading", pattern, config .. "/lua", config .. "/init.lua" })
  if vim.v.shell_error ~= 0 or #hits == 0 then
    return nil
  end
  -- keep hits that look like actual mapping definitions (not comments),
  -- and prefer the central keymaps file over plugin-spec keys tables
  local defs = vim.tbl_filter(function(h)
    return h:match("keymap") or h:match("layerSet") or h:match('{%s*"')
  end, hits)
  if #defs > 0 then
    hits = defs
  end
  table.sort(hits, function(a, b)
    local ak = a:match("keymaps%.lua") and 0 or 1
    local bk = b:match("keymaps%.lua") and 0 or 1
    return ak < bk
  end)
  local path, lnum = hits[1]:match("^(.-):(%d+):")
  return path, tonumber(lnum)
end

function M.entries()
  local out, seen = {}, {}

  -- live maps: global + current buffer, desc required (skips <Plug> noise)
  for _, mode in ipairs(MODES) do
    for _, source in ipairs({
      vim.api.nvim_get_keymap(mode),
      vim.api.nvim_buf_get_keymap(0, mode),
    }) do
      for _, m in ipairs(source) do
        if m.desc and m.desc ~= "" and not m.lhs:match("^<Plug>") then
          local key = mode .. "\0" .. m.lhs
          if not seen[key] then
            seen[key] = true
            table.insert(out, {
              mode = mode,
              lhs = pretty_lhs(m.lhs),
              desc = m.desc,
              context = m.buffer == 1 and "buffer" or "",
            })
          end
        end
      end
    end
  end

  for context, keys in pairs(CONTEXT_KEYS) do
    for _, k in ipairs(keys) do
      table.insert(out, { mode = k[1], lhs = k[2], desc = k[3], context = context })
    end
  end

  table.sort(out, function(a, b)
    if a.context ~= b.context then
      return a.context < b.context -- global ("") first, then contexts A-Z
    end
    if a.mode ~= b.mode then
      return a.mode < b.mode
    end
    return a.lhs < b.lhs
  end)
  return out
end

---------------------------------------------------------------------------
-- Picker
---------------------------------------------------------------------------

function M.show()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 2 },
      { width = 22 },
      { width = 16 },
      { remaining = true },
    },
  })

  pickers
    .new({}, {
      prompt_title = "Cheatsheet (all keymaps)",
      finder = finders.new_table({
        results = M.entries(),
        entry_maker = function(e)
          return {
            value = e,
            display = function(entry)
              local it = entry.value
              return displayer({
                { it.mode, "Comment" },
                { it.lhs, "Special" },
                { it.context, "Statement" },
                { it.desc, "" },
              })
            end,
            ordinal = ("%s %s %s %s"):format(e.mode, e.lhs, e.context, e.desc),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local e = entry and entry.value
          -- jump to where the mapping is defined in the config source
          if e and e.context ~= "buffer" and e.context ~= "" then
            return -- curated context keys have no single definition site
          end
          local path, lnum = definition_location(e and e.lhs)
          if path then
            vim.cmd.edit(vim.fn.fnameescape(path))
            vim.api.nvim_win_set_cursor(0, { lnum, 0 })
            vim.cmd("normal! zz")
          end
        end)
        return true
      end,
    })
    :find()
end

return M
