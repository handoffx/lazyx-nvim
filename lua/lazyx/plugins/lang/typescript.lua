-- TypeScript / JavaScript on top of the AstroCommunity packs (vtsls, prettier, eslint).
--
-- Prettier: the pack registers prettierd with none-ls for every web filetype,
-- regardless of project config, so it formatted alongside vtsls / jsonls /
-- cssls. Here prettierd only runs when the project has a prettier config, and
-- then it is the only formatter for that buffer.
-- ESLint: lint only. lspconfig enables its formatter by default; disable it.
--
-- The pack installs js-debug-adapter but mason-nvim-dap has no mapping for
-- it (only the legacy node2 / chrome / firefox adapters), so nothing was
-- registered and <F5> found no configuration. Register the pwa-node adapter
-- and launch/attach configurations from mason-nvim-dap's "js" handler.
-- Node >= 23 strips TypeScript types itself, so .ts files launch directly.

if not vim.tbl_contains(require("lazyx.config").langs(), "typescript") then return {} end

local filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

-- Filetypes none-ls's prettierd builtin formats
local prettier_filetypes = {
  "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html",
  "json", "jsonc", "yaml", "markdown", "markdown.mdx", "graphql", "handlebars", "svelte", "astro", "htmlangular",
}

local prettier_configs = {
  ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.json5",
  ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.ts", ".prettierrc.cts", ".prettierrc.mts",
  ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs", "prettier.config.ts",
  "prettier.config.cts", "prettier.config.mts",
}

--- Whether the buffer's project configures prettier (config file or "prettier" in package.json)
---@param bufnr integer
local function has_prettier(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return false end
  local dir = vim.fs.dirname(name)
  if vim.fs.find(prettier_configs, { path = dir, upward = true })[1] then return true end
  local pkg = vim.fs.find("package.json", { path = dir, upward = true })[1]
  if not pkg then return false end
  local ok, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), "\n"))
  return ok and type(json) == "table" and json.prettier ~= nil
end

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
    "jay-babu/mason-null-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.handlers = opts.handlers or {}
      opts.handlers.prettierd = function()
        local null_ls = require "null-ls"
        null_ls.register(null_ls.builtins.formatting.prettierd.with {
          runtime_condition = function(params) return has_prettier(params.bufnr) end,
        })
      end
    end,
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@param opts AstroLSPOpts
    opts = function(_, opts)
      opts.config = opts.config or {}
      opts.config.eslint = vim.tbl_deep_extend("force", opts.config.eslint or {}, { settings = { format = false } })
      opts.formatting = opts.formatting or {}
      local filter = opts.formatting.filter
      -- AstroLSP's filter only receives the client. Format-on-save runs in
      -- BufWritePre, where the buffer being written is current (also for :wa).
      opts.formatting.filter = function(client)
        if filter and not filter(client) then return false end
        if client.name == "null-ls" then return true end
        local bufnr = vim.api.nvim_get_current_buf()
        return not (vim.tbl_contains(prettier_filetypes, vim.bo[bufnr].filetype) and has_prettier(bufnr))
      end
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.handlers = opts.handlers or {}
      opts.handlers.js = setup_js_debug
    end,
  },
}
