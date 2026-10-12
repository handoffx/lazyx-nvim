-- Capsule statusline and bufferline, matching the tmux status line.
--
-- Every item is a two-tone capsule on a transparent bar: a colored icon
-- segment and a surface0 body segment between rounded separators.
-- Bodies reuse AstroUI components (with their own `surround` disabled), so
-- providers, click handlers and update events stay upstream.

local L, R = "\u{e0b6}", "\u{e0b4}"

local icons = {
  mode = "\u{e7c5}",
  git = "\u{e725}",
  file = "\u{f15b}",
  lsp = "\u{f085}",
  position = "\u{e0a1}",
  macro = "\u{f192}",
  search = "\u{f002}",
}

-- AstroUI providers take an icon spec; "NONE" renders no icon (the capsule shows it instead)
local no_icon = { kind = "NONE", padding = { left = 0, right = 0 } }

local function palette() return require("catppuccin.palettes").get_palette "mocha" end

local function hl_fg(group)
  local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
  return fg and ("#%06x"):format(fg)
end

--- Icon and icon color for a buffer, from mini.icons
local function file_icon(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ok, mini_icons = pcall(require, "mini.icons")
  if not ok or name == "" then return icons.file, nil end
  local icon, group = mini_icons.get("file", vim.fn.fnamemodify(name, ":t"))
  return icon, hl_fg(group)
end

local function resolve(value, self)
  if type(value) == "function" then return value(self) end
  return value
end

--- Two-tone capsule
---@param spec { color: string|fun(self):string, icon: string|fun(self):string, body: table, condition?: fun(self):boolean, update?: any, body_hl?: table|fun(self):table }
local function capsule(spec)
  local p = palette()
  return {
    condition = spec.condition,
    update = spec.update,
    { provider = L, hl = function(self) return { fg = resolve(spec.color, self), bg = p.base } end },
    {
      provider = function(self) return resolve(spec.icon, self) .. " " end,
      hl = function(self) return { fg = p.crust, bg = resolve(spec.color, self), bold = true } end,
    },
    {
      hl = function(self)
        local hl = resolve(spec.body_hl, self) or {}
        return vim.tbl_extend("force", { fg = p.text }, hl, { bg = p.surface0 })
      end,
      { provider = " " },
      spec.body,
      { provider = " " },
    },
    { provider = R, hl = { fg = p.surface0, bg = p.base } },
  }
end

local space = { provider = " " }

local function statusline()
  local status = require "astroui.status"
  local condition = status.condition
  local p = palette()

  local mode_colors = {
    normal = p.blue,
    insert = p.green,
    visual = p.mauve,
    replace = p.red,
    command = p.peach,
    terminal = p.teal,
    inactive = p.overlay0,
  }
  local function mode_color() return mode_colors[status.hl.mode_bg()] or p.blue end
  local mode_update = {
    "ModeChanged",
    pattern = "*:*",
    callback = function() vim.schedule(vim.cmd.redrawstatus) end,
  }

  local mode = capsule {
    color = mode_color,
    icon = icons.mode,
    body = { provider = function() return require("astroui").config.status.modes[vim.fn.mode()][1] end },
    body_hl = { bold = true },
    update = mode_update,
  }

  local git = capsule {
    condition = condition.is_git_repo,
    color = p.mauve,
    icon = icons.git,
    body = {
      status.component.git_branch { git_branch = { icon = no_icon }, surround = false },
      status.component.git_diff { surround = false },
    },
  }

  local file = capsule {
    condition = condition.has_filetype,
    color = function() return select(2, file_icon(0)) or p.blue end,
    icon = function() return (file_icon(0)) end,
    body = status.component.file_info {
      file_icon = false,
      filename = {},
      filetype = false,
      surround = false,
    },
  }

  local diagnostics = capsule {
    condition = condition.has_diagnostics,
    color = p.red,
    icon = "\u{f188}",
    body = status.component.diagnostics { surround = false },
  }

  local cmd_info = capsule {
    condition = function()
      return vim.o.cmdheight == 0 and (condition.is_macro_recording() or condition.is_hlsearch())
    end,
    color = function() return condition.is_macro_recording() and p.red or p.yellow end,
    icon = function() return condition.is_macro_recording() and icons.macro or icons.search end,
    body = status.component.cmd_info {
      macro_recording = { icon = no_icon },
      search_count = { icon = no_icon, padding = { left = 0 } },
      surround = false,
    },
  }

  local lsp = capsule {
    condition = condition.lsp_attached,
    color = p.lavender,
    icon = icons.lsp,
    body = status.component.lsp { lsp_client_names = { icon = no_icon }, surround = false },
  }

  local position = capsule {
    color = mode_color,
    icon = icons.position,
    body = status.component.nav { scrollbar = false, surround = false },
    update = { "ModeChanged", "CursorMoved", "CursorMovedI", "BufEnter", pattern = "*" },
  }

  return {
    hl = { fg = p.text, bg = p.base },
    space,
    mode,
    space,
    git,
    space,
    file,
    space,
    diagnostics,
    status.component.fill(),
    cmd_info,
    status.component.fill(),
    lsp,
    space,
    position,
    space,
  }
end

local function buffer_capsule()
  local status = require "astroui.status"
  local p = palette()

  local function accent(self)
    if self.is_active then return p.blue end
    if self.is_visible then return p.overlay2 end
    return p.overlay0
  end

  return {
    capsule {
      color = accent,
      icon = function(self) return (file_icon(self.bufnr)) end,
      body = status.component.tabline_file_info { file_icon = false, padding = { right = 0 }, surround = false },
      body_hl = function(self) return { fg = self.is_active and p.text or p.subtext0, bold = self.is_active } end,
    },
    space,
  }
end

---@type LazySpec
return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      status = {
        -- AstroUI's make_buflist wraps each buffer in a "tab" surround; make it
        -- invisible so the capsule inside draws the shape.
        separators = { tab = { "", "" } },
        colors = function(hl)
          local base = palette().base
          hl.tabline_bg = base
          hl.buffer_bg = base
          hl.buffer_visible_bg = base
          hl.buffer_active_bg = base
          return hl
        end,
      },
    },
  },
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      opts.statusline = statusline()
      -- tabline[2] is AstroNvim's buffer list; keep the sidebar padding, fill
      -- and tab list around it.
      opts.tabline[2] = require("astroui.status").heirline.make_buflist(buffer_capsule())
    end,
  },
}
