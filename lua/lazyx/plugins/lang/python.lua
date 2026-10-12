-- Python: resolve the interpreter for basedpyright.
--
-- The AstroCommunity pack uses `exepath("python")`, which is empty on Debian
-- and Homebrew where only `python3` exists, and ignores project virtualenvs.

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
        },
      },
    },
  },
}
