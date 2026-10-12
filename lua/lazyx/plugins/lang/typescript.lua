-- TypeScript / JavaScript on top of the AstroCommunity pack (vtsls).
--
-- The pack installs js-debug-adapter but mason-nvim-dap has no mapping for
-- it (only the legacy node2 / chrome / firefox adapters), so nothing was
-- registered and <F5> found no configuration. Register the pwa-node adapter
-- and launch/attach configurations from mason-nvim-dap's "js" handler.
-- Node >= 23 strips TypeScript types itself, so .ts files launch directly.

if not vim.tbl_contains(require("lazyx.config").langs(), "typescript") then return {} end

local filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

local function setup_js_debug()
  local dap = require "dap"
  local adapter = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = { command = vim.fn.exepath "js-debug-adapter", args = { "${port}" } },
  }
  dap.adapters["pwa-node"] = adapter
  -- launch.json files written for VS Code use type "node"
  dap.adapters["node"] = function(cb, config)
    if config.type == "node" then config.type = "pwa-node" end
    cb(adapter)
  end
  for _, ft in ipairs(filetypes) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to process",
        processId = function() return require("dap.utils").pick_process() end,
        cwd = "${workspaceFolder}",
      },
    }
  end
end

---@type LazySpec
return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.handlers = opts.handlers or {}
      opts.handlers.js = setup_js_debug
    end,
  },
}
