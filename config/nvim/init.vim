" Autoinstall
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  augroup plug_install
    autocmd VimEnter * PlugInstall
  augroup END
endif
let mapleader = " "

call plug#begin('~/.config/nvim/plugged')
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" 1.1 Plugin list
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
" ---------------------------------------------------------------------------------------------------------------------
" Language agnostic plugins
" ---------------------------------------------------------------------------------------------------------------------
" Autocomplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Automatically closing pair stuff
Plug 'cohama/lexima.vim'
" Commenting support (gc)
Plug 'tpope/vim-commentary'
" CamelCase and snake_case motions
Plug 'bkad/CamelCaseMotion'
omap <silent> iw <Plug>CamelCaseMotion_iw
xmap <silent> iw <Plug>CamelCaseMotion_iw
omap <silent> ib <Plug>CamelCaseMotion_ib
xmap <silent> ib <Plug>CamelCaseMotion_ib
omap <silent> ie <Plug>CamelCaseMotion_ie
xmap <silent> ie <Plug>CamelCaseMotion_ie
" Heuristically set indent settings
Plug 'tpope/vim-sleuth'
" Language Server
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" CoC extensions
let g:coc_global_extensions = ['coc-tsserver']
" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>cf  <Plug>(coc-fix-current)
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

Plug 'williamboman/mason.nvim'
Plug 'neovim/nvim-lspconfig'

Plug 'github/copilot.vim'

" ---------------------------------------------------------------------------------------------------------------------
" JS (ES6, React)
" ---------------------------------------------------------------------------------------------------------------------

" Modern JS support (indent, syntax, etc)
Plug 'pangloss/vim-javascript'
" JSON syntax
Plug 'sheerun/vim-json'
" Typescript
Plug 'leafgarland/typescript-vim'

" ---------------------------------------------------------------------------------------------------------------------
" HTML/CSS
" ---------------------------------------------------------------------------------------------------------------------

" HTML5 syntax
Plug 'othree/html5.vim'
" SCSS syntax
Plug 'cakebaker/scss-syntax.vim'
" Color highlighter
Plug 'lilydjwg/colorizer', { 'for': ['css', 'sass', 'scss', 'less', 'html', 'xdefaults', 'javascript', 'javascript.jsx'] }
" Emmet
Plug 'mattn/emmet-vim'
let g:user_emmet_leader_key='<C-z>'

" ---------------------------------------------------------------------------------------------------------------------
" Other languages
" ---------------------------------------------------------------------------------------------------------------------

" Yaml indentation
Plug 'martin-svk/vim-yaml'
" Markdown syntax
Plug 'tpope/vim-markdown'
" Git syntax
Plug 'tpope/vim-git'
" Dockerfile
Plug 'honza/dockerfile.vim'
" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_def_mapping_enabled = 0
" Rust
Plug 'rust-lang/rust.vim'
" Elixir
Plug 'elixir-editors/vim-elixir'

" ---------------------------------------------------------------------------------------------------------------------
" Interface improving
" ---------------------------------------------------------------------------------------------------------------------

" Nerdtree file browser
" Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeFind', 'NERDTreeToggle'] }
" Nerdtree git status
" Plug 'Xuyuanp/nerdtree-git-plugin'
" File icon
" Plug 'ryanoasis/vim-devicons'

" Lightline (simple status line)
Plug 'itchyny/lightline.vim'
" Add current branch into statusline
function MyFugitiveHead()
  let head = FugitiveHead()
  if head != ""
    let head = "\uf126 " .. head
  endif
  return head
endfunction

let g:lightline = {
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
    \ },
    \ 'component_function': {
    \   'gitbranch': 'MyFugitiveHead'
    \ },
    \}

Plug 'ap/vim-buftabline'

" Easymotion
Plug 'easymotion/vim-easymotion'
" File Search
Plug 'kien/ctrlp.vim'

" Faster Fuzzy Search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
nnoremap <leader><leader>f :Ag<CR>
nnoremap <leader>f :Files<CR>

" Improve Vim Mark
Plug 'chentoast/marks.nvim'
" Git integration
Plug 'tpope/vim-fugitive'

" Rainbow Parenthesis
Plug 'luochen1990/rainbow'
let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle

" == MultiTerminal in nvim
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}
" set
let toggleterm_cmd = "ToggleTerm direction=float"
autocmd TermEnter term://*toggleterm#*
      \ tnoremap <silent><c-t> <Cmd>exe v:count1 . toggleterm_cmd<CR>
" By applying the mappings this way you can pass a count to your
" mapping to open a specific window.
" For example: 2<C-t> will open terminal 2
nnoremap <silent><c-t> <Cmd>exe v:count1 . toggleterm_cmd<CR>
inoremap <silent><c-t> <Esc><Cmd>exe v:count1 . toggleterm_cmd<CR>

" trouble.nvim
Plug 'folke/trouble.nvim'
nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle document_diagnostics<cr>
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
nnoremap gR <cmd>TroubleToggle lsp_references<cr>
" nmap <silent> gL <cmd>call coc#rpc#request('fillDiagnostics', [bufnr('%')])<CR><cmd>Trouble loclist<CR>

" Editing
Plug 'kylechui/nvim-surround'
Plug 'xiyaowong/transparent.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" lspsaga
" Plug 'nvimdev/lspsaga.nvim'

" Colorschemes
" Base16
Plug 'chriskempson/base16-vim'

" Colorscheme
" Plug 'cocopon/iceberg'
Plug 'namrabtw/rusty.nvim', { 'branch': 'main' }
Plug 'ghifarit53/tokyonight-vim' 
Plug 'shatur/neovim-ayu'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'ellisonleao/gruvbox.nvim'

" Tree
Plug 'nvim-neo-tree/neo-tree.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'MunifTanjim/nui.nvim'

call plug#end()


" ======================================================================================================================
" 2.0 Basic settings (Neovim defaults: https://neovim.io/doc/user/vim_diff.html#nvim-option-defaults)
" ======================================================================================================================

set encoding=utf-8                          " The encoding displayed.
set fileencoding=utf-8                      " The encoding written to file.
scriptencoding utf-8                        " Set utf-8 as default script encoding

set shell=/bin/zsh                          " Setting shell to zsh
set number                                  " Line numbers on
set relativenumber
set showmode                                " Always show mode
set showcmd                                 " Show commands as you type them
set textwidth=120                           " Text width is 120 characters
set cmdheight=1                             " Command line height
set pumheight=10                            " Completion window max size
set noswapfile                              " New buffers will be loaded without creating a swapfile
set hidden                                  " Enables to switch between unsaved buffers and keep undo history
set clipboard+=unnamed                      " Allow to use system clipboard
set lazyredraw                              " Don't redraw while executing macros (better performance)
set showmatch                               " Show matching brackets when text indicator is over them
set matchtime=2                             " How many tenths of a second to blink when matching brackets
set nostartofline                           " Prevent cursor from moving to beginning of line when switching buffers
set virtualedit=block                       " To be able to select past EOL in visual block mode
set nojoinspaces                            " No extra space when joining a line which ends with . ? !
set scrolloff=5                             " Scroll when closing to top or bottom of the screen
set updatetime=1000                         " Update time used to create swap file or other things
set suffixesadd+=.js,.rb                    " Add js and ruby files to suffixes
set synmaxcol=160                           " Don't try to syntax highlight minified files

" ---------------------------------------------------------------------------------------------------------------------
" 2.1 Search settings
" ---------------------------------------------------------------------------------------------------------------------
set ignorecase                              " Ignore case by default
set smartcase                               " Make search case sensitive only if it contains uppercase letters
set wrapscan                                " Search again from top when reached the bottom
set nohlsearch                              " Don't highlight after search

" ---------------------------------------------------------------------------------------------------------------------
" 2.2 Persistent undo settings
" ---------------------------------------------------------------------------------------------------------------------
if has('persistent_undo')
  set undofile
  set undodir=~/.config/nvim/tmp/undo//
endif

" ---------------------------------------------------------------------------------------------------------------------
" 2.3 White characters settings
" ---------------------------------------------------------------------------------------------------------------------
set list                                    " Show listchars by default
set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮,trail:·,nbsp:·
set showbreak=↪

" ---------------------------------------------------------------------------------------------------------------------
" 2.4 Filetype settings
" ---------------------------------------------------------------------------------------------------------------------
filetype plugin on
filetype indent on

" ---------------------------------------------------------------------------------------------------------------------
" 2.5 Folding settings
" ---------------------------------------------------------------------------------------------------------------------
set foldmethod=marker                       " Markers are used to specify folds.
set foldlevel=2                             " Start folding automatically from level 2
set fillchars="fold: "                      " Characters to fill the statuslines and vertical separators

" ---------------------------------------------------------------------------------------------------------------------
" 2.6 Neovim specific settings
" ---------------------------------------------------------------------------------------------------------------------
if has('nvim')
  let g:loaded_python_provider=1                        " Disable python 2 interface
  let g:python_host_skip_check=1                        " Skip python 2 host check
  let g:python3_host_prog='/usr/local/bin/python3'      " Set python 3 host program
  set inccommand=nosplit                                " Live preview of substitutes and other similar commands
endif

" -----------------------------------------------------
" 2.7 True colors settings
" -----------------------------------------------------
if has('termguicolors')
  set termguicolors " Turn on true colors support
endif

" -----------------------------------------------------
" 2.8 File Tree settings
" -----------------------------------------------------
"NERDTree UI improvements
" let NERDTreeMinimalUI = 1
" let NERDTreeDirArrows = 1
" let NERDTreeShowHidden = 1
" 
" "Start NERDTree if no files or directory selected
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTreeToggle' argv()[0] | wincmd p | ene | endif
" 
" "Close vim if only NERDTree is open
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree")) | q | endif
" 
" "Ctrl+n NERDTree mapping
" nnoremap wleaderwnt :NERDTreeToggle<CR>
" 
" "NERDTree on the left
" let g:NERDTreeWinPos = "left"

nnoremap <leader>nt :Neotree toggle<CR>

" -----------------------------------------------------
" 2.9 Navigation
" -----------------------------------------------------

"Ctrl P
nmap <leader>lf :CtrlPMRU<CR>
let g:ctrlp_show_hidden=1

" ======================================================================================================================
" 3.0 Color and highlighting settings
" ======================================================================================================================
" Color scheme
let g:tokyonight_style = 'night' " available: night, storm let g:tokyonight_enable_italic = 1

" lua require("ayu").colorscheme()
" colorscheme tokyonight
"catppuccin catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
colorscheme ayu 
" colorscheme catppuccin-macchiato

" Syntax highlighting
syntax on

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Highlight term cursor differently
highlight TermCursor ctermfg=green guifg=green
hi Visual  guifg=White guibg=GreenYellow gui=none

" Multiple Cursor Editing
nmap <expr> <silent> <C-d> <SID>select_current_word()
function! s:select_current_word()
  if !get(b:, 'coc_cursors_activated', 0)
    return "\<Plug>(coc-cursors-word)"
  endif
  return "*\<Plug>(coc-cursors-word):nohlsearch\<CR>"
endfunc
" Display type on hover
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  end
endfunction
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Autosave
" BUG: After edit file in the neo-tree window, this cmd will be trigger but cause error (can't write)
autocmd InsertLeave * :w!

" Remove underline in folded lines
hi! Folded term=NONE cterm=NONE gui=NONE ctermbg=NONE

" Link highlight groups to improve buftabline colors
hi! link BufTabLineCurrent Identifier
hi! link BufTabLineActive Comment
hi! link BufTabLineHidden Comment
hi! link BufTabLineFill Comment
nnoremap <leader>a :bprev<CR>
nnoremap <leader>d :bnext<CR>
nnoremap <leader>r :b#<CR>
nnoremap <leader>w :bd<CR>
" Remap some window operations
"Navigation between windows
nmap <leader>h :wincmd h<CR>
nmap <leader>l :wincmd l<CR>
nmap <leader>j :wincmd j<CR>
nmap <leader>k :wincmd k<CR>
" Spliting
nnoremap <leader>v :wincmd v<CR>
nnoremap <leader>c :wincmd s<CR>
" Change window layout
nnoremap <leader>q :wincmd q<CR>
nnoremap <leader>H :wincmd H<CR>
nnoremap <leader>L :wincmd L<CR>
nnoremap <leader>J :wincmd J<CR>
nnoremap <leader>K :wincmd K<CR>

inoremap jj <Esc>
nnoremap <leader>ev :vsplit ~/.config/nvim/init.vim<CR>
nnoremap <leader>sv :source ~/.config/nvim/init.vim<CR>
au BufNewFile,BufRead Jenkinsfile setf groovy

" Lua plugins setup
lua require("toggleterm").setup()
lua require("trouble").setup()
lua require("nvim-surround").setup()
lua require("transparent").setup()
lua require("marks").setup()
lua require("mason").setup()

lua <<EOF
  local lspconfig = require("lspconfig")
  vim.filetype.add({ extension = { templ = "templ" } })

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches

  local servers = { 'rust_analyzer', 'gopls', 'ccls', 'cmake', 'tsserver', 'templ' }
  for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end

  lspconfig.html.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      filetypes = { "html", "templ", "pug" },
  })

  lspconfig.tailwindcss.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      filetypes = { "templ", "astro", "javascript", "typescript", "react" },
      init_options = { userLanguages = { templ = "html" } },
  })
EOF

lua <<EOF
    require ('neo-tree').setup {
      close_if_last_window = false,
      filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false
          },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = true
          }
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true
      },
      buffer = {
        follow_current_file = {
          enabled = true,
        },
      },
      window = {
        width = 30
      }
    }

    -- If you want icons for diagnostic errors, you'll need to define them somewhere:
    vim.fn.sign_define("DiagnosticSignError",
      {text = " ", texthl = "DiagnosticSignError"})
    vim.fn.sign_define("DiagnosticSignWarn",
      {text = " ", texthl = "DiagnosticSignWarn"})
    vim.fn.sign_define("DiagnosticSignInfo",
      {text = " ", texthl = "DiagnosticSignInfo"})
    vim.fn.sign_define("DiagnosticSignHint",
      {text = "󰌵", texthl = "DiagnosticSignHint"})
EOF

lua <<EOF
require ('nvim-treesitter.configs').setup {
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = {
      'c',
      'cpp',
      'c_sharp',
      'rust',
      'go',
      'gomod',
      'proto',
      'templ',
      'python',
      'swift',
      'java',
      'jsdoc',
      'typescript',
      'javascript',
      'tsx',
      'css',
      'scss',
      'html',
      'pug',
      'astro',
      'vue',
      'svelte',
      'graphql',
      'prisma',
      'elixir',
      'heex',
      'eex',
      'yaml',
      'toml',
      'json',
      'xml',
      'markdown',
      'terraform',
      'dockerfile',
      'sql',
      'ini',
      'ssh_config',
      'make',
      'cmake'
  }
}
EOF
