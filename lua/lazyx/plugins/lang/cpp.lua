-- C / C++ on top of the AstroCommunity pack (clangd + clangd_extensions).
--
-- - Formatting without a .clang-format file: WebKit style (4-space indents).
--   --fallback-style only accepts predefined style names; inline YAML and
--   file:<path> are rejected as "Invalid fallback style".
-- - The pack maps "switch source/header" to <Leader>lw, which shadows
--   AstroNvim's workspace diagnostics. Move it to <Leader>lo ("other file").

if not vim.tbl_contains(require("lazyx.config").langs(), "cpp") then return {} end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      config = {
        clangd = {
          -- A project .clang-format still wins
          cmd = { "clangd", "--fallback-style=WebKit" },
        },
      },
    },
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        -- Same augroup and index as the pack, so this entry replaces its callback
        clangd_extension_mappings = {
          {
            event = "LspAttach",
            desc = "Map switch source/header for clangd",
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if client and client.name == "clangd" then
                require("astrocore").set_mappings({
                  n = { ["<Leader>lo"] = { "<Cmd>ClangdSwitchSourceHeader<CR>", desc = "Switch source/header file" } },
                }, { buffer = args.buf })
              end
            end,
          },
        },
      },
    },
  },
}
