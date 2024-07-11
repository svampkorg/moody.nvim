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

---callback for use with the autocommand for mode change
---@param blended table: table of blended mode colours
---@param unblended table: table of unblended mode colours
---@param bold_nr boolean: use bold chars for CursorLineNr
local function hl_callback(blended, unblended, bold_nr)
  local utils = require("moody.utils")
  if vim.fn.win_gettype() == "" then
    utils.switch(vim.api.nvim_get_mode().mode, {
      ["n"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.normal })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.normal, bold = bold_nr })
      end,
      ["i"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.insert })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.insert, bold = bold_nr })
      end,
      ["v"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.visual })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.visual, bold = bold_nr })
      end,
      ["V"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.visual })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.visual, bold = bold_nr })
      end,
      [""] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.visual })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.visual, bold = bold_nr })
      end,
      ["x"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.visual })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.visual, bold = bold_nr })
      end,
      ["c"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.command })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.command, bold = bold_nr })
      end,
      ["r"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.replace })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.replace, bold = bold_nr })
      end,
      ["s"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.select })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.select, bold = bold_nr })
      end,
      ["t"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.terminal })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.terminal, bold = bold_nr })
      end,
      ["default"] = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = blended.terminal_n })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = unblended.terminal_n, bold = bold_nr })
      end,
    })()
  end
end

M.defaults = {
  blend = {
    normal = 0.2,
    insert = 0.2,
    visual = 0.2,
    command = 0.2,
    replace = 0.2,
    select = 0.2,
    terminal = 0.2,
    terminal_n = 0.2,
  },
  disabled_filetypes = {},
  bold_nr = true,
}

---@class Config
---@field blend table: how much to blend colors with black for the cursorline
---@field disabled_filetypes table: List of buffers to disable this plugin for
---@field bold_nr boolean: bold linenumbers or not
M.options = {}

---save highlights
local function save()
  M.cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  M.cursorlinenr_hl = vim.api.nvim_get_hl(0, { name = "CursorLineNr" })
  M.visual = vim.api.nvim_get_hl(0, { name = "Visual" })
end

---restore highlights
local function restore()
  if not M.cursorline_hl or not M.cursorlinenr_hl or not M.visual then
    return
  end
  vim.api.nvim_set_hl(0, "CursorLine", { fg = M.cursorline_hl.fg, bg = M.cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "CursorLineNr", {
    fg = M.cursorlinenr_hl.fg,
    bold = M.cursorlinenr_hl.bold,
    bg = M.cursorlinenr_hl.bg,
  })
  vim.api.nvim_set_hl(0, "Visual", { fg = M.visual.fg, bg = M.visual.bg })
end

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
function M.__setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
  local utils = require("moody.utils")

  -- save the current hl groups changed, so they can be restored for disabled filetypes
  save()

  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blend)

  -- InsertLeave added to catch the right mode after leaving telescope
  vim.api.nvim_create_autocmd({ "ModeChanged", "BufWinEnter", "WinEnter", "InsertLeave" }, {
    desc = "set highlights depending on mode",
    group = vim.api.nvim_create_augroup("MoodyGroupModeChanged", { clear = true }),
    callback = function()
      -- utils.P(event) -- TODO: use match in event, possibly replacing the "switch" in hl_callback
      if is_disabled_filetype(vim.bo.filetype) then
        restore()
        return
      end
      vim.api.nvim_set_hl(0, "Visual", { bg = M.options.hl_blended.visual })
      hl_callback(M.options.hl_blended, M.options.hl_unblended, M.options.bold_nr)
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
