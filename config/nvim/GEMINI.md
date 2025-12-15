You are in the nvim config project, which is my neovim config I want to use at any computer.

The spec is

Functions:
1. nvim-tree for file operations
2. telescope.nvim for search and preview
3. mason for lsp manager
4. flash.nvim for quick jump
5. I want to see outline of opened file
6. I want to see diagnostic of my workspace in one place
7. I want to change my colorscheme using cmd
8. I want to have autocomplete in my cmd
9. I want to have fast full-text search
10. I want to have good git status indicator in my workspace
11. I want to have a clock in my status bar
12. I want to easily find/switch between my tabs
13. I want my lsp/linter works immediatelly when I open a file, especially for Rust/typescript/C++/Go
15. floating terminal

Keymap:
leader key is space
<leader> nt for toggle nvim-tree
<leader> jj for exit insert mode
<leader> o for toggle outline
<leader> d for toggle trouble diagnostics
gd for Go to definition
gt for Go to type definition
<leader> r for Go to/List references
<leader> i for Go to Implementation
<leader> s for Go to source definition
<shift> k for peek type/doc of code under cursor
<leader> " for horizontal split
<leader> % for vertical split
<leader> ff for full-text search (maybe can have advance filter? Like targeting directory or file type.
<leader> f for file search
<leader> m for keymapping search
<leader> c for toggle floating terminal 
<leader> w for close current tab
<leader> q for close all tab
<leader> e for close all window 
<leader> h/j/k/l for moving between window


Please test and fix issues after all tasks done
