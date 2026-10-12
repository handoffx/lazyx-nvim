-- Over SSH there is no local clipboard tool; let the terminal handle it via
-- OSC 52 (tmux forwards it with `set-clipboard on`). Locally Neovim picks
-- wl-copy / pbcopy / win32yank on its own.
local remote = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = { options = { g = { clipboard = remote and "osc52" or nil } } },
  },
}
