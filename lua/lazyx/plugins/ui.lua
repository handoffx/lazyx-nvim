-- Catppuccin Mocha, shared with the WezTerm scheme and the tmux status line.
-- Use `catppuccin-mocha`: plain `catppuccin` may resolve to the copy bundled
-- with Neovim instead of catppuccin/nvim.

---@type LazySpec
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { flavour = "mocha" },
  },
  -- Rounded borders everywhere: most floats follow 'winborder' (AstroNvim sets
  -- "rounded"); toggleterm defaults to "single".
  {
    "akinsho/toggleterm.nvim",
    optional = true,
    opts = { float_opts = { border = "rounded" } },
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
