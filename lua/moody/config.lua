---@class ConfigModule
---@field defaults Config: default options
---@field options Config: config table extending defaults
local M = {}

---@param filetype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
local function is_disabled_filetype(filetype)
  local disabled_filetypes = require("moody.config").options.disabled_filetypes
  return vim.tbl_contains(disabled_filetypes, filetype) or string.match(filetype, "dapui")
end

-- ---save highlights, also converts to hex string because reasons :)
-- local function save_all_highlight()
--   local tohex = require("moody.math").int_to_hex_string
--   M.cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
--   M.cursorlinenr_hl = vim.api.nvim_get_hl(0, { name = "CursorLineNr" })
--   M.visual = vim.api.nvim_get_hl(0, { name = "Visual" })
--   M.cursorline_bg = tohex(M.cursorline_hl.bg)
--   M.cursorline_fg = tohex(M.cursorline_hl.fg)
--   M.cursorlinenr_bg = tohex(M.cursorlinenr_hl.bg)
--   M.cursorlinenr_fg = tohex(M.cursorlinenr_hl.fg)
--   M.visual_bg = tohex(M.visual.bg)
--   M.visual_fg = tohex(M.visual.fg)
-- end

local function cache_colors()
  local utils = require("moody.utils")
  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blends)
end

---@type Config
M.defaults = {
  ---@class Blends
  ---@field normal number: hex value for normal mode color
  ---@field insert number: hex value for insert mode color
  ---@field visual number: hex value for visual mode color
  ---@field command number: hex value for command mode color
  ---@field operator number: hex value for operator mode color
  ---@field replace number: hex value for replace mode color
  ---@field select number: hex value for select mode color
  ---@field terminal number: hex value for terminal mode color
  ---@field terminal_n number: hex value for terminal normal mode color
  blends = {
    normal = 0.2,
    insert = 0.2,
    visual = 0.2,
    command = 0.2,
    operator = 0.2,
    replace = 0.2,
    select = 0.2,
    terminal = 0.2,
    terminal_n = 0.2,
  },
  ---@class Colors
  ---@field normal string: hex value for normal mode color
  ---@field insert string: hex value for insert mode color
  ---@field visual string: hex value for visual mode color
  ---@field command string: hex value for command mode color
  ---@field operator string: hex value for operator mode color
  ---@field replace string: hex value for replace mode color
  ---@field select string: hex value for select mode color
  ---@field terminal string: hex value for terminal mode color
  ---@field terminal_n string: hex value for terminal normal mode color
  colors = {
    normal = "#00BFFF",
    insert = "#70CF67",
    visual = "#AD6FF7",
    command = "#EB788B",
    operator = "#FF8F40",
    replace = "#E66767",
    select = "#AD6FF7",
    terminal = "#4CD4BD",
    terminal_n = "#00BBCC",
  },
  disabled_filetypes = {},
  ---@type boolean
  bold_nr = true,
}

---@alias MoodyFocus "window" | "neovim" | "both"

---@class Config
---@field blends Blends: how much to blend colors with black for the cursorline
---@field colors Colors: table of colours with respective mode
---@field disabled_filetypes table: List of buffers to disable this plugin for
---@field bold_nr boolean: bold linenumbers or not
M.options = {}

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
function M.__setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
  local utils = require("moody.utils")

  local augroup = vim.api.nvim_create_augroup("MoodyGroupModeChanged", { clear = true })
  M.ns_hl = vim.api.nvim_create_namespace("MoodyHighlightNS")

  -- load up the "colour caches"
  cache_colors()
  vim.api.nvim_set_hl(M.ns_hl, "Visual", { bg = M.options.hl_blended.visual })

  -- A few cases where cursorline is needed to be set to not
  -- have a default gray line before any modes are enterd.
  vim.api.nvim_create_autocmd({
    -- Added to set normal colors when only one buffer is open
    "BufWinEnter",
    -- Whenever entering a window
    "WinEnter",
    -- Added to catch when leaving telescope
    "InsertLeave",
  }, {
    group = augroup,
    callback = function()
      if is_disabled_filetype(vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      vim.api.nvim_set_hl(M.ns_hl, "CursorLine", { bg = M.options.hl_blended.normal })
      vim.api.nvim_set_hl(M.ns_hl, "CursorLineNr", { fg = M.options.hl_unblended.normal, bold = M.options.bold_nr })
      vim.api.nvim_set_hl_ns(M.ns_hl)
    end,
  })

  -- set highlight depending on mode changed
  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    desc = "set highlights depending on mode",
    group = augroup,
    callback = function(event)
      -- utils.P(event)

      -- utils.P("active window: " .. win_id)

      -- restore all highlights if disabled
      if is_disabled_filetype(vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      -- use saved values as defaults
      local blended = M.cursorline_bg
      local unblended = M.cursorlinenr_fg

      -- regex match with mode entered
      local mode = string.match(event.match, ".*:([^:]+)")

      -- local debugText = "nothing"

      utils.switch(mode, {
        ["n"] = function()
          -- debugText = "normal"
          blended = M.options.hl_blended.normal
          unblended = M.options.hl_unblended.normal
        end,
        ["i"] = function()
          -- debugText = "insert"
          blended = M.options.hl_blended.insert
          unblended = M.options.hl_unblended.insert
        end,
        ["ix"] = function()
          -- debugText = "insert-completion"
          blended = M.options.hl_blended.insert
          unblended = M.options.hl_unblended.insert
        end,
        ["v"] = function()
          -- debugText = "visual"
          blended = M.options.hl_blended.visual
          unblended = M.options.hl_unblended.visual
        end,
        ["V"] = function()
          -- debugText = "visual-line"
          blended = M.options.hl_blended.visual
          unblended = M.options.hl_unblended.visual
        end,
        [""] = function()
          -- debugText = "visual-block"
          blended = M.options.hl_blended.visual
          unblended = M.options.hl_unblended.visual
        end,
        ["c"] = function()
          -- debugText = "command"
          blended = M.options.hl_blended.command
          unblended = M.options.hl_unblended.command
        end,
        ["r"] = function()
          -- debugText = "replace"
          blended = M.options.hl_blended.replace
          unblended = M.options.hl_unblended.replace
        end,
        ["s"] = function()
          -- debugText = "select"
          blended = M.options.hl_blended.select
          unblended = M.options.hl_unblended.select
        end,
        ["t"] = function()
          -- debugText = "terminal"
          blended = M.options.hl_blended.terminal
          unblended = M.options.hl_unblended.terminal
        end,
        ["nt"] = function()
          -- debugText = "terminal-normal"
          blended = M.options.hl_blended.terminal_n
          unblended = M.options.hl_unblended.terminal_n
        end,
        ["no"] = function()
          -- debugText = "operator-pending"
          blended = M.options.hl_blended.operator
          unblended = M.options.hl_unblended.operator
        end,
        ["default"] = function()
          -- debugText = "default"
          blended = M.cursorline_hl.bg
          unblended = M.cursorlinenr_hl.fg
        end,
      })()

      -- setup and print some debug data top cmdline
      -- local debugdata = "mode is " .. mode .. " debugText is: " .. debugText
      -- vim.cmd(string.format([[echo "%s"]], debugdata))

      vim.api.nvim_set_hl(M.ns_hl, "CursorLine", { bg = blended })
      vim.api.nvim_set_hl(M.ns_hl, "CursorLineNr", { fg = unblended, bold = M.options.bold_nr })
      vim.api.nvim_set_hl_ns(M.ns_hl)
    end,
  })

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = augroup,
    callback = cache_colors,
  })

  vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function()
      vim.wo.cursorline = true
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = augroup,
    callback = function()
      vim.wo.cursorline = false
    end,
  })
end

---Format the defaults options table for documentation
---@return table
M.__format_keys = function()
  local tbl = vim.split(vim.inspect(M.defaults), "\n")
  table.insert(tbl, 1, "<pre>")
  table.insert(tbl, 2, "Defaults: ~")
  table.insert(tbl, #tbl, "</pre>")
  return tbl
end

return M
