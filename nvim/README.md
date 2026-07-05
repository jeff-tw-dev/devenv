# Neovim Configuration

My personal Neovim configuration.

## nvim-surround Cheatsheet

| Command | Action | Example |
| :--- | :--- | :--- |
| **Normal Mode** | | |
| `ys{motion}{char}` | **Add** surround | `ysiw"` (word -> "word") |
| `ds{char}` | **Delete** surround | `ds"` ("word" -> word) |
| `cs{target}{replacement}` | **Change** surround | `cs"'` ("word" -> 'word') |
| **Visual Mode** | | |
| `S{char}` | **Surround** selection | Select text -> `S)` -> (text) |

## toggleterm

Escape insert mode in terminal: `<C-/> <C-n>`
