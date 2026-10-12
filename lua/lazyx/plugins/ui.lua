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
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
