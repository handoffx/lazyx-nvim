-- AstroCommunity imports. Import this module before `lazyx.plugins` so that
-- lazyx overrides are applied on top of community specs.
local config = require "lazyx.config"

-- Language group -> AstroCommunity packs
local packs = {
  lua = { "lua" },
  bash = { "bash" },
  python = { "python.base", "python.basedpyright", "python.ruff" }, -- ruff instead of black + isort
  rust = { "rust" },
  cpp = { "cpp", "cmake" },
  go = { "go" },
  typescript = { "typescript" },
  web = { "html-css" },
  data = { "json", "yaml", "toml", "markdown" },
}

---@type LazySpec
local spec = {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.colorscheme.catppuccin" },
}

for _, lang in ipairs(config.langs()) do
  for _, pack in ipairs(packs[lang] or {}) do
    table.insert(spec, { import = "astrocommunity.pack." .. pack })
  end
end

return spec
