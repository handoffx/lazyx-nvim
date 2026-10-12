-- Lua on top of the AstroCommunity pack (lua_ls + stylua via none-ls).
--
-- Exactly one formatter: stylua through none-ls (it passes
-- --search-parent-directories, so the global ~/.config/stylua/stylua.toml
-- applies to files without a project config). mason-lspconfig would also
-- start `stylua --lsp` because the stylua package is installed, and lua_ls
-- has its own formatter; turn both off.

if not vim.tbl_contains(require("lazyx.config").langs(), "lua") then return {} end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      handlers = { stylua = false },
      formatting = { disabled = { "lua_ls" } },
    },
  },
}
