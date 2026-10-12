-- smart-splits.nvim v3 with the tmux backend.
--
-- AstroNvim ships a v2 spec under the old repository name and pins it through
-- its lazy snapshot. Keep the same plugin name so its keymaps still merge, but
-- point at the new repository, drop the pinned commit and track v3.
local config = require "lazyx.config"

---@type LazySpec
return {
  {
    "mrjones2014/smart-splits.nvim",
    url = "https://github.com/smart-splits-nvim/smart-splits.nvim",
    commit = false,
    version = "^3",
    -- tmux only learns that a pane runs Neovim when the plugin loads; a lazily
    -- loaded plugin lets tmux swallow <C-hjkl>.
    lazy = false,
    dependencies = {
      { "smart-splits-nvim/backend-tmux", main = "smart-splits-backend-tmux" },
    },
    opts = {
      move = { at_edge = config.get().at_edge },
      mux = {
        backend = { "smart-splits-backend-tmux" },
        -- Windows and plain terminals run without tmux; that is expected.
        warn_if_unusable = false,
      },
    },
    specs = {
      {
        "AstroNvim/astrocore",
        opts = function(_, opts)
          local maps = opts.mappings
          -- Resize with M-hjkl to match tmux.conf; free the arrow keys.
          for _, key in ipairs { "<C-Up>", "<C-Down>", "<C-Left>", "<C-Right>" } do
            maps.n[key] = false
          end
          local ss = function(fn) return function() require("smart-splits")[fn]() end end
          maps.n["<M-h>"] = { ss "resize_left", desc = "Resize split left" }
          maps.n["<M-j>"] = { ss "resize_down", desc = "Resize split down" }
          maps.n["<M-k>"] = { ss "resize_up", desc = "Resize split up" }
          maps.n["<M-l>"] = { ss "resize_right", desc = "Resize split right" }
        end,
      },
    },
  },
}
