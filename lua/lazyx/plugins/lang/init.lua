-- Per-language overrides on top of the AstroCommunity packs.
-- Each module returns an empty spec when its language group is disabled.

---@type LazySpec
return {
  { import = "lazyx.plugins.lang.lua" },
  { import = "lazyx.plugins.lang.python" },
  { import = "lazyx.plugins.lang.cpp" },
  { import = "lazyx.plugins.lang.typescript" },
}
