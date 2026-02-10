local keymap = vim.keymap

-- lsp
keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Go to definition" })
keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "Go to type definition" })
keymap.set("n", "<leader>r", "<cmd>Telescope lsp_references<CR>", { desc = "Go to references" })
keymap.set("n", "<leader>i", "<cmd>Telescope lsp_implementations<CR>", { desc = "Go to implementation" })
keymap.set("n", "<leader>ci", "<cmd>Telescope lsp_incoming_calls<CR>", { desc = "List incoming calls" })
keymap.set("n", "<leader>co", "<cmd>Telescope lsp_outgoing_calls<CR>", { desc = "List outgoing calls" })
keymap.set("n", "<S-k>", vim.lsp.buf.hover, { desc = "Peek type/doc of code under cursor" })

-- exit insert mode
keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode" })

-- nvim-tree
keymap.set("n", "<leader>nt", ":NvimTreeToggle<CR>", { desc = "Toggle nvim-tree" })

-- outline
keymap.set("n", "<leader>o", ":SymbolsOutline<CR>", { desc = "Toggle outline" })

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
keymap.set("n", "<leader>ff", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
keymap.set("n", "<leader>fm", "<cmd>Telescope man_pages<cr>", { desc = "Find man page" })
keymap.set("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", { desc = "Find jump position" })
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Find diagnostics" })
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffer" })
keymap.set("n", "<leader>p", "<cmd>Telescope resume<cr>", { desc = "Resume telescope" })
keymap.set("n", "<leader>m", "<cmd>Telescope keymaps<cr>", { desc = "Search keymaps" })
keymap.set("n", "<leader>cs", "<cmd>Telescope colorscheme<cr>", { desc = "Switch colorscheme" })

-- splits
keymap.set("n", "<leader>\"", "<cmd>split<CR>", { desc = "New horizontal split" })
keymap.set("n", "<leader>%", "<cmd>vsplit<CR>", { desc = "New vertical split" })

-- floating terminal
keymap.set("n", "<leader>c", "<cmd>ToggleTerm<CR>", { desc = "Toggle floating terminal" })

-- buffers
keymap.set("n", "<leader>w", "<cmd>Bdelete<CR>", { desc = "Close current buffer" })
keymap.set("n", "<leader>q", "<cmd>bufdo bdelete<CR>", { desc = "Close all buffers" })
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
