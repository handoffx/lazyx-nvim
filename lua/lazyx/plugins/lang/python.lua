-- Python on top of the AstroCommunity pack (base + basedpyright + ruff):
-- - basedpyright: interpreter resolution, "standard" type checking, types only
-- - ruff: lint, format, organize imports on save
--
-- The pack uses `exepath("python")`, which is empty on Debian and Homebrew
-- where only `python3` exists, and ignores project virtualenvs.

local is_win = vim.fn.has "win32" == 1

local function venv_python(venv)
  local python = vim.fs.joinpath(venv, is_win and "Scripts/python.exe" or "bin/python")
  if vim.uv.fs_stat(python) then return python end
end

--- Interpreter for a project: active venv, then <root>/.venv or <root>/venv, then PATH
---@param root? string
---@return string
local function python_path(root)
  for _, venv in ipairs { vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX } do
    local python = venv and venv_python(venv)
    if python then return python end
  end
  if root then
    for _, name in ipairs { ".venv", "venv" } do
      local python = venv_python(vim.fs.joinpath(root, name))
      if python then return python end
    end
  end
  for _, exe in ipairs { "python3", "python" } do
    local python = vim.fn.exepath(exe)
    if python ~= "" then return python end
  end
  return "python3"
end

--- Apply ruff's organize-imports code action synchronously
---@param client vim.lsp.Client
---@param bufnr integer
local function organize_imports(client, bufnr)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  ---@diagnostic disable-next-line: inject-field
  params.context = { only = { "source.organizeImports.ruff" }, diagnostics = {} }
  local res = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
  for _, action in ipairs(res and res.result or {}) do
    if not action.edit and client:supports_method("codeAction/resolve", bufnr) then
      local resolved = client:request_sync("codeAction/resolve", action, 1000, bufnr)
      action = resolved and resolved.result or action
    end
    if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
  end
end

if not vim.tbl_contains(require("lazyx.config").langs(), "python") then return {} end

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      config = {
        basedpyright = {
          before_init = function(_, config)
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = python_path(config.root_dir)
          end,
          settings = {
            basedpyright = {
              analysis = {
                -- pyproject.toml [tool.basedpyright] still takes precedence
                typeCheckingMode = "standard",
                diagnosticSeverityOverrides = {
                  -- ruff reports these (F401, F841)
                  reportUnusedImport = "none",
                  reportUnusedVariable = "none",
                  -- the pack silences these; restore the "standard" defaults
                  reportGeneralTypeIssues = "error",
                  reportOptionalMemberAccess = "error",
                  reportOptionalSubscript = "error",
                  reportPrivateImportUsage = "error",
                },
              },
            },
          },
        },
      },
      autocmds = {
        -- Runs before AstroLSP's format-on-save in the same BufWritePre
        lazyx_ruff_organize_imports = {
          cond = function(client) return client.name == "ruff" end,
          {
            event = "BufWritePre",
            desc = "Organize imports with ruff",
            callback = function(args)
              local client = vim.lsp.get_clients({ bufnr = args.buf, name = "ruff" })[1]
              if client then organize_imports(client, args.buf) end
            end,
          },
        },
      },
    },
  },
}
