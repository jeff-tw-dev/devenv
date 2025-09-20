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
" call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*' })

" Automatically closing pair stuff
Plug 'cohama/lexima.vim'
" Commenting support (gc)
Plug 'tpope/vim-commentary'
" Heuristically set indent settings
Plug 'tpope/vim-sleuth'
" Language Server
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" CoC extensions
" let g:coc_global_extensions = ['coc-tsserver']
" " Remap keys for applying codeAction to the current line.
" nmap <leader>ac  <Plug>(coc-codeaction)
" " Apply AutoFix to problem on the current line.
" nmap <leader>cf  <Plug>(coc-fix-current)
" " GoTo code navigation.
" nmap <silent> gd <Plug>(coc-definition)
" nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
" nmap <silent> gr <Plug>(coc-references)
" inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

Plug 'williamboman/mason.nvim'
Plug 'neovim/nvim-lspconfig'

Plug 'github/copilot.vim'
Plug 'jackMort/ChatGPT.nvim'

" ---------------------------------------------------------------------------------------------------------------------
" JS (ES6, React)
" ---------------------------------------------------------------------------------------------------------------------

" Modern JS support (indent, syntax, etc)
Plug 'pangloss/vim-javascript'
" JSON syntax
Plug 'sheerun/vim-json'
" Typescript
Plug 'leafgarland/typescript-vim'
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
" let g:go_fmt_command = "gofmt"
" let g:go_fmt_autosave = 0
" let g:got_import_autosave = 0

" Rust
Plug 'rust-lang/rust.vim'
" Elixir
Plug 'elixir-editors/vim-elixir'

" ---------------------------------------------------------------------------------------------------------------------
" Interface improving
" ---------------------------------------------------------------------------------------------------------------------

" Close buffer without messing up the window layout
Plug 'famiu/bufdelete.nvim'

" File icon
" Plug 'ryanoasis/vim-devicons'
"
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'TheGLander/indent-rainbowline.nvim'

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

" !Plug 'ap/vim-buftabline'

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
let g:rainbow_active = 1 

	let g:rainbow_conf = {
	\	'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
	\	'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
	\	'operators': '_,_',
	\	'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
	\	'separately': {
	\		'*': {},
	\		'tex': {
	\			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
	\		},
	\		'lisp': {
	\			'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
	\		},
	\		'vim': {
	\			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
	\		},
	\		'html': {
	\			'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
	\		},
	\		'css': 0,
	\		'nerdtree': 0,
	\	}
	\}

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

" gitsign
Plug 'lewis6991/gitsigns.nvim'

" tabline
Plug 'romgrk/barbar.nvim'

" trouble.nvim
Plug 'folke/trouble.nvim', { 'tag': 'v2.10.0' }

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
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'nvimdev/lspsaga.nvim'

" LSP
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }

" Colorschemes
" Base16
Plug 'chriskempson/base16-vim'

" Colorscheme
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

" catppuccin catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
" tokyonight 
" gruvbox'
colorscheme gruvbox
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
" function! s:show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   else
"     call CocAction('doHover')
"   end
" endfunction
" nnoremap <silent> K :call <SID>show_documentation()<CR>

" Autosave
" Create an autocommand group to avoid duplication and errors
augroup AutosaveGroup
  autocmd!
  " Check if the buffer is modifiable and then write
  autocmd InsertLeave * if &modifiable | silent! write | endif
augroup END

" Remove underline in folded lines
hi! Folded term=NONE cterm=NONE gui=NONE ctermbg=NONE

" Link highlight groups to improve buftabline colors
hi! link BufTabLineCurrent Identifier
hi! link BufTabLineActive Comment
hi! link BufTabLineHidden Comment
hi! link BufTabLineFill Comment

" ==========================
" ==== Key mappings <k> ====
" ==========================

" Coc Command
" nnoremap <leader>o :CocOutline<CR>
" nnoremap <leader>ci :CocCommand document.showIncomingCalls<CR>
" nnoremap <leader>co :CocCommand document.showOutgoingCalls<CR>
nnoremap <leader>rn <Plug>(coc-rename)
nnoremap <leader>rf :CocCommand workspace.renameCurrentFile<CR>
nnoremap <leader>oi :CocCommand editor.action.organizeImport<CR>


" Remap some window and buffer operations
nnoremap <leader>a :bp<CR>
nnoremap <leader>d :bn<CR>
nnoremap <leader>r :b#<CR>
"nnoremap <leader>ee :bd<CR>

" Navigation between windows
nnoremap <leader>w :wincmd q<CR>
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

nnoremap <leader>ca :Lspsaga code_action<CR>
nnoremap <leader>o :Lspsaga outline<CR>
nnoremap <leader>ci :Lspsaga incoming_calls<CR>
nnoremap <leader>co :Lspsaga outgoing_calls<CR>
nnoremap <silent> F :Lspsaga finder<CR>
nmap <silent> gd :Lspsaga goto_definition<CR>
nmap <silent> gy :Lspsaga goto_type_definition<CR>
nmap <silent> gi :Lspsaga goto_implementation<CR>
nmap <silent> gr :Lspsaga finder ref<CR>
nnoremap <silent> K :Lspsaga hover_doc<CR>

" Lua plugins setup
lua require("toggleterm").setup()
lua require("nvim-surround").setup()
lua require("transparent").setup()
lua require("trouble").setup()
lua require("marks").setup()
lua require("mason").setup()
" require('indent-rainbowline').make_opts({})
lua require("gitsigns").setup()
lua require("barbar").setup()

lua <<EOF

    local bd = require('bufdelete')
    vim.keymap.set('n', '<leader>ee', bd.bufdelete, {})

   ----------------------
    -- Telescope keymap --
    ----------------------
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

    ------------------------------------------------
    -- TODO: Prevent error message after easymotion jump --
    ------------------------------------------------
    function ToggleDiagnostics(enable)
      if enable then
	vim.diagnostic.enable()
      else
	vim.diagnostic.disable()
      end
    end

    ---------------------------------
    -- Setup indentation indicator --
    ---------------------------------
    local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
    }
    local hooks = require "ibl.hooks"
    -- create the highlight groups in the highlight setup hook, so they are reset
    -- every time the colorscheme changes
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
    end)

    require ("ibl").setup {
      scope = { highlight = highlight },
    }
    vim.g.rainbow_delimiters = { highlight = highlight }
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    -----------------------------------

    ---------------------------------
    -- Neovim native Lspconfig settings --
    ---------------------------------
    require ("lspsaga").setup {
      ui = {
	code_action = '',
      },
      folder_level = 2
    }

    local lspconfig = require("lspconfig")
    vim.filetype.add({ extension = { templ = "templ", pug = "pug" } })

    -- Use a loop to conveniently call 'setup' on multiple servers and
    -- map buffer local keybindings when the language server attaches

    local servers = { 'rust_analyzer', 'gopls', 'cmake', 'tsserver', 'templ', 'clangd', 'pyright' }
    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({
	on_attach = on_attach,
      })
    end

    lspconfig.terraformls.setup {
	on_attach = on_attach,
	filetypes = { "terraform", "terraform-vars" },
	init_options = { userLanguages = { tf = "terraform", tfvars = "terraform-vars" } },
    }

    lspconfig.html.setup {
	on_attach = on_attach,
	filetypes = { "html", "templ", "pug", "typescriptreact" },
    }

    lspconfig.tailwindcss.setup {
	on_attach = on_attach,
	filetypes = { "svelte", "templ", "astro", "javascript", "typescript", "react", "typescriptreact", "html", "pug" },
	init_options = { userLanguages = { svelte = "html", templ = "html", pug = "html" } },
    }

    -------------------
    -- Setup neo-tree --
    -------------------
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
            leave_dirs_open = false 
          }
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false 
      },
      buffer = {
        follow_current_file = {
          enabled = true,
        },
      },
      window = {
        width = 40
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

    -------------------
    -- Treesitter --
    -------------------
    require ('nvim-treesitter.configs').setup {
      textobjects = {
	select = {
	  enable = true,

	  -- Automatically jump forward to textobj, similar to targets.vim
	  lookahead = true,

	  keymaps = {
	    -- You can use the capture groups defined in textobjects.scm
	    ["af"] = "@function.outer",
	    ["if"] = "@function.inner",
	    ["ac"] = "@class.outer",
	    -- You can optionally set descriptions to the mappings (used in the desc parameter of
	    -- nvim_buf_set_keymap) which plugins like which-key display
	    ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
	    -- You can also use captures from other query groups like `locals.scm`
	    ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
	  },
	  -- You can choose the select mode (default is charwise 'v')
	  --
	  -- Can also be a function which gets passed a table with the keys
	  -- * query_string: eg '@function.inner'
	  -- * method: eg 'v' or 'o'
	  -- and should return the mode ('v', 'V', or '<c-v>') or a table
	  -- mapping query_strings to modes.
	  selection_modes = {
	    ['@parameter.outer'] = 'v', -- charwise
	    ['@function.outer'] = 'V', -- linewise
	    ['@class.outer'] = '<c-v>', -- blockwise
	  },
	  -- If you set this to `true` (default is `false`) then any textobject is
	  -- extended to include preceding or succeeding whitespace. Succeeding
	  -- whitespace has priority in order to act similarly to eg the built-in
	  -- `ap`.
	  --
	  -- Can also be a function which gets passed a table with the keys
	  -- * query_string: eg '@function.inner'
	  -- * selection_mode: eg 'v'
	  -- and should return true or false
	  include_surrounding_whitespace = true,
	},
      },
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
	  'cmake',
      }
    }
EOF

autocmd BufWritePre *.tfvars lua vim.lsp.buf.format()
autocmd BufWritePre *.tf lua vim.lsp.buf.format()
