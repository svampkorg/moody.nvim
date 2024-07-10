local M = {}

local darken = require('moody.math').darken
local tohex = require('moody.math').int_to_hex_string

--- switch between string choice in table of string key, and table value choices
--- A default case is not mandatory, but it will return nil if there is none :P
--- @param choice string: The "case", key in your table of choices
--- @param choices table: The "value", in your table of case keys
--- @return table value choices.choice case
function M.switch(choice, choices)
  return choices[choice] or choices["default"]
end

---comment
---@return table
function M.hl_unblended()
  return {
    normal = tohex(vim.api.nvim_get_hl(0, { name = "NormalMoody" }).fg),
    insert = tohex(vim.api.nvim_get_hl(0, { name = "InsertMoody" }).fg),
    visual = tohex(vim.api.nvim_get_hl(0, { name = "VisualMoody" }).fg),
    command = tohex(vim.api.nvim_get_hl(0, { name = "CommandMoody" }).fg),
    replace = tohex(vim.api.nvim_get_hl(0, { name = "ReplaceMoody" }).fg),
    select = tohex(vim.api.nvim_get_hl(0, { name = "SelectMoody" }).fg),
    terminal = tohex(vim.api.nvim_get_hl(0, { name = "TerminalMoody" }).fg),
    terminal_n = tohex(vim.api.nvim_get_hl(0, { name = "TerminalNormalMoody" }).fg),
  }
end

--- get darkened variant of the HL colours
--- @param blend table|number: number: a number between 0 and 1 used to darken.
--- table: a table of modes with their respective blend
--- @return table: a table of all the modes with values of blended colors
function M.hl_blended(blend)
  local blend_type = type(blend)
  if blend_type == "table" then
    return {
      normal = darken(M.hl_unblended().normal, blend.normal),
      insert = darken(M.hl_unblended().insert, blend.insert),
      visual = darken(M.hl_unblended().visual, blend.visual),
      command = darken(M.hl_unblended().command, blend.command),
      replace = darken(M.hl_unblended().replace, blend.replace),
      select = darken(M.hl_unblended().select, blend.select),
      terminal = darken(M.hl_unblended().terminal, blend.terminal),
      terminal_n = darken(M.hl_unblended().terminal_n, blend.terminal_n),
    }
  else if blend_type == "number" then
      return {
        normal = darken(M.hl_unblended().normal, blend),
        insert = darken(M.hl_unblended().insert, blend),
        visual = darken(M.hl_unblended().visual, blend),
        command = darken(M.hl_unblended().command, blend),
        replace = darken(M.hl_unblended().replace, blend),
        select = darken(M.hl_unblended().select, blend),
        terminal = darken(M.hl_unblended().terminal, blend),
        terminal_n = darken(M.hl_unblended().terminal_n, blend),
      }
    else return {
        normal = darken(M.hl_unblended().normal, 0.3),
        insert = darken(M.hl_unblended().insert, 0.3),
        visual = darken(M.hl_unblended().visual, 0.3),
        command = darken(M.hl_unblended().command, 0.3),
        replace = darken(M.hl_unblended().replace, 0.3),
        select = darken(M.hl_unblended().select, 0.3),
        terminal = darken(M.hl_unblended().terminal, 0.3),
        terminal_n = darken(M.hl_unblended().terminal_n, 0.3),
      }
    end
  end
end

---callback for use with the autocommand for mode change
---@param blended table: table of blended mode colours
---@param unblended table: table of unblended mode colours
---@param bold_nr boolean: use bold chars for CursorLineNr
function M.hl_callback(blended, unblended, bold_nr)
  if vim.fn.win_gettype() == "" then
    M.switch(vim.api.nvim_get_mode().mode, {
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

--- short hand method for printing stuff in neovim
--- @param v any
--- @return any
function M.P(v)
  print(vim.inspect(v))
  return v
end

return M