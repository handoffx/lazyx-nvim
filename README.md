# lazyx-nvim

A Neovim distribution layered on top of [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6,
built to run inside tmux inside WezTerm.

lazyx-nvim is a lazy.nvim plugin, not a config directory: your config imports AstroNvim first,
then lazyx-nvim, then your machine-local overrides.

## Requirements

- Neovim >= 0.12
- AstroNvim v6 requirements (Nerd Font, C compiler, tree-sitter CLI via Mason, ...)
- tmux >= 3.7 for pane navigation (optional; without tmux navigation stays inside Neovim)

## Usage

```lua
vim.g.lazyx = { light = false } -- see lua/lazyx/config.lua

require("lazy").setup({
  { "AstroNvim/AstroNvim", version = "^6", import = "astronvim.plugins", opts = { mapleader = " " } },
  { "handoffx/lazyx-nvim", import = "lazyx.community" }, -- AstroCommunity packs
  { import = "lazyx.plugins" },                          -- lazyx overrides
  { import = "plugins" },                                -- machine-local overrides
})
```

A complete entry config lives in [handoffx/dotfiles](https://github.com/handoffx/dotfiles)
(`dot_config/nvim`).

## Options (`vim.g.lazyx`)

| Option        | Default                                    | Description |
|---------------|--------------------------------------------|-------------|
| `light`       | `false`                                    | Light-use machine: enable `light_langs` only |
| `langs`       | lua, bash, python, rust, cpp, go, typescript, web, data | Language groups (AstroCommunity packs) |
| `light_langs` | lua, python, web, data                     | Language groups on light machines |
| `at_edge`     | `"stop"`                                   | smart-splits edge behavior; must match `tmux.conf` |

## What lazyx changes on top of AstroNvim

- **Pane navigation**: smart-splits.nvim v3 with `backend-tmux` (AstroNvim pins v2).
  Loaded at startup so tmux always knows when a pane runs Neovim.
  `<C-hjkl>` moves, `<M-hjkl>` resizes (arrow-key resizing is removed) — same keys as tmux.
- **Colorscheme**: Catppuccin Mocha (`catppuccin-mocha`), matching WezTerm and the tmux status line.
- **Clipboard**: OSC 52 over SSH.

## Development

Point lazy.nvim at a local checkout:

```lua
{ "handoffx/lazyx-nvim", dev = true, import = "lazyx.community" }
-- lazy.nvim options
dev = { path = "/path/to/parent/dir", fallback = true }
```

Format with [StyLua](https://github.com/JohnnyMorganz/StyLua).
