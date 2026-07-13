local keymap = vim.keymap

-- lsp
-- gd is i18n-aware: on an i18n key string (t("a.b.c")) it jumps into the
-- locale JSON instead; anywhere else it falls through to LSP definition
keymap.set("n", "gd", function()
  if not require("core.i18n").jump() then
    vim.cmd("Telescope lsp_definitions")
  end
end, { desc = "Go to definition (i18n key aware)" })
keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "Go to type definition" })
keymap.set("n", "<leader>r", "<cmd>Telescope lsp_references<CR>", { desc = "Go to references" })
keymap.set("n", "<leader>i", "<cmd>Telescope lsp_implementations<CR>", { desc = "Go to implementation" })
keymap.set("n", "<leader>ci", "<cmd>Telescope lsp_incoming_calls<CR>", { desc = "List incoming calls" })
keymap.set("n", "<leader>co", "<cmd>Telescope lsp_outgoing_calls<CR>", { desc = "List outgoing calls" })
-- code trace: recursive call tree (core/tracegraph)
-- panel keys: o expand/collapse, <CR> call site, gd definition, p preview, s direction, q quit
keymap.set("n", "<leader>ct", function()
  require("core.tracegraph").open("incoming")
end, { desc = "Trace callers (recursive tree)" })
keymap.set("n", "<leader>cT", function()
  require("core.tracegraph").open("outgoing")
end, { desc = "Trace callees (recursive tree)" })
-- K is i18n-aware: on an i18n key string it floats every locale's
-- translation; anywhere else it falls through to LSP hover
keymap.set("n", "<S-k>", function()
  if not require("core.i18n").peek() then
    vim.lsp.buf.hover()
  end
end, { desc = "Peek type/doc (i18n translations on keys)" })
keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol across project" })
keymap.set("n", "<leader>rN", "<cmd>Lspsaga rename ++project<CR>", { desc = "Rename symbol (project-wide preview)" })
keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Code action" })

-- exit insert mode
keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode" })

-- nvim-tree
keymap.set("n", "<leader>nt", ":NvimTreeToggle<CR>", { desc = "Toggle nvim-tree" })

-- outline
keymap.set("n", "<leader>o", ":Outline<CR>", { desc = "Toggle outline" })

-- markdown render toggle (raw markdown / rendered)
keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle markdown render" })
-- markdown browser preview (mermaid / math)
keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Toggle markdown browser preview" })
-- mermaid block under cursor -> ASCII float
keymap.set("n", "<leader>md", function()
  require("core.mermaid").render()
end, { desc = "Render mermaid block as ASCII" })

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
keymap.set("n", "<leader>ff", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
keymap.set("n", "<leader>fm", "<cmd>Telescope man_pages<cr>", { desc = "Find man page" })
keymap.set("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", { desc = "Find jump position" })
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Find diagnostics" })
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffer" })
keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent files (last session first)" })
keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Search keymaps" })
-- cheatsheet: search every keymap incl. panel-local keys, <CR> jumps to definition
keymap.set("n", "<leader>?", function()
  require("core.cheatsheet").show()
end, { desc = "Cheatsheet: search ALL keymaps incl. panel keys" })
keymap.set("n", "<leader>p", "<cmd>Telescope resume<cr>", { desc = "Resume telescope" })
keymap.set("n", "<leader>cs", "<cmd>Telescope colorscheme<cr>", { desc = "Switch colorscheme" })
keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Switch git branch" })

-- project info (npm scripts/deps, make targets, cargo/go.mod deps, env files)
-- panel keys: <CR> jump to definition, r run in toggleterm, q quit
keymap.set("n", "<leader>pi", function()
  require("core.projinfo").show()
end, { desc = "Project info (scripts/deps/targets)" })

-- bookmarks (core/bookmarks): line bookmarks, JSON-persisted
-- in the list panel: <CR> jump, dd delete, e edit note, q close
keymap.set("n", "<leader>bm", function()
  require("core.bookmarks").toggle()
end, { desc = "Toggle bookmark on current line" })
keymap.set("n", "<leader>ba", function()
  require("core.bookmarks").annotate()
end, { desc = "Annotate bookmark" })
keymap.set("n", "<leader>bl", function()
  require("core.bookmarks").list()
end, { desc = "Bookmark list panel" })
keymap.set("n", "]b", function()
  require("core.bookmarks").next()
end, { desc = "Next bookmark in buffer" })
keymap.set("n", "[b", function()
  require("core.bookmarks").prev()
end, { desc = "Previous bookmark in buffer" })

-- llm (core/llm): mark code/files -> compose prompt -> headless claude -p or TUI paste
-- marks panel: <CR> jump, dd delete, e note, C clear; history panel: <CR> open, dd delete
keymap.set({ "n", "v" }, "<leader>am", function()
  require("core.llm").mark()
end, { desc = "LLM: mark selection/file" })
keymap.set("n", "<leader>aa", function()
  require("core.llm").ask()
end, { desc = "LLM: ask about marks (intent/model/effort)" })
keymap.set("n", "<leader>al", function()
  require("core.llm").list()
end, { desc = "LLM: marks panel" })
keymap.set("n", "<leader>ah", function()
  require("core.llm").history()
end, { desc = "LLM: history panel" })
keymap.set("n", "<leader>af", function()
  require("core.llm").followup()
end, { desc = "LLM: follow-up on last exchange" })
keymap.set("n", "<leader>an", function()
  require("core.llm").annotate()
end, { desc = "LLM: annotate mark" })

-- neogit: git hub (in status buffer: s stage, c commit, b branch, p pull, P push, ? help)
keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Neogit status (stage/commit/branch)" })
keymap.set("n", "<leader>gL", "<cmd>Neogit log<CR>", { desc = "Git log with commit graph" })
-- merge conflicts (core/conflict): co ours, ct theirs, cb both, c0 none, ]x/[x navigate
keymap.set("n", "<leader>gx", function()
  require("core.conflict").qf()
end, { desc = "List all merge conflicts (quickfix)" })

-- git blame (gitsigns)
keymap.set("n", "<leader>gB", "<cmd>Gitsigns blame<CR>", { desc = "Blame whole file (window)" })
keymap.set("n", "<leader>gl", function()
  require("gitsigns").blame_line({ full = true })
end, { desc = "Blame current line (popup)" })

-- splits
keymap.set("n", "<leader>\"", "<cmd>split<CR>", { desc = "New horizontal split" })
keymap.set("n", "<leader>%", "<cmd>vsplit<CR>", { desc = "New vertical split" })

-- floating terminal
keymap.set("n", "<leader>c", "<cmd>ToggleTerm<CR>", { desc = "Toggle floating terminal" })

-- buffers (core/bufclose: keep window layout when closing)
keymap.set("n", "<leader>w", function()
  require("core.bufclose").delete()
end, { desc = "Close current buffer" })
keymap.set("n", "<leader>q", function()
  require("core.bufclose").delete_all()
end, { desc = "Close all buffers" })
keymap.set("n", "<leader>e", "<cmd>only<CR>", { desc = "Close all other windows" })

-- Trouble.nvim
keymap.set("n", "<leader>d", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle workspace diagnostics" })
keymap.set("n", "<leader>dl", "<cmd>Trouble loclist toggle<cr>", { desc = "Toggle workspace loclist" })
keymap.set("n", "<leader>dq", "<cmd>Trouble qflist toggle<cr>", { desc = "Toggle workspace quickfix list" })

-- window navigation
keymap.set("n", "<leader>h", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<leader>j", "<C-w>j", { desc = "Move to down window" })
keymap.set("n", "<leader>k", "<C-w>k", { desc = "Move to up window" })
keymap.set("n", "<leader>l", "<C-w>l", { desc = "Move to right window" })

-- buffer navigation
keymap.set("n", "<leader><leader>l", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader><leader>h", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
