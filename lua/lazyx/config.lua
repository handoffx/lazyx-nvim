-- User-facing options, read from `vim.g.lazyx` at spec time.
-- Set `vim.g.lazyx` before calling `require("lazy").setup()`.
local M = {}

---@class LazyxConfig
---@field light boolean light-use machine: only `light_langs` are enabled
---@field langs string[] language groups enabled on full machines
---@field light_langs string[] language groups enabled on light machines
---@field at_edge "stop"|"wrap"|"split" smart-splits edge behavior, must match tmux.conf
M.defaults = {
  light = false,
  langs = { "lua", "bash", "python", "rust", "cpp", "typescript", "web", "data" },
  light_langs = { "lua", "python", "web", "data" },
  at_edge = "stop",
}

---@return LazyxConfig
-- Shallow merge: list options such as `langs` replace the defaults instead of
-- being merged index by index.
function M.get() return vim.tbl_extend("force", M.defaults, vim.g.lazyx or {}) end

---@return string[]
function M.langs()
  local cfg = M.get()
  return cfg.light and cfg.light_langs or cfg.langs
end

return M
