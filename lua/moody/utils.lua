---@class Utils
---@field switch function: a switch kind of function, provide a lookup table and a key as case
---@field hl_unblended function: a function to return a table of Colors from either HL groups or Config
---@field is_disabled_filetype function: return true if filetype is disabled, false if not
---@field hl_blended function: calculate new blends using either a number or Blend
local M = {}

local darken = require("moody.math").darken

local tohex = require("moody.math").int_to_hex_string
-- local options = require("moody.config").options

--- switch between string choice in table of string key, and table value choices
--- A default case is not mandatory, but it will return nil if there is none :P
--- The return should be a function, what to execute on choice
--- @param choice string: The "case", key in your table of choices
--- @param choices table: The "value", in your table of case keys
--- @return function value choices.choice case
function M.switch(choice, choices)
  return choices[choice] or choices["default"]
end

function M.trigger_mode(event)
  local mode = string.match(event.match, ".*:([^:]+)")
  local win = vim.api.nvim_get_current_win()

  local currentMode = "normal"

  M.switch(mode, {
    ["n"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_normal)
      currentMode = "normal"
      -- debugText = "normal"
    end,
    ["i"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
      currentMode = "insert"
      -- debugText = "insert"
    end,
    ["ix"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
      currentMode = "insert"
      -- debugText = "insert-completion"
    end,
    ["v"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
      currentMode = "visual"
      -- debugText = "visual"
    end,
    ["V"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
      currentMode = "visual"
      -- debugText = "visual-line"
    end,
    [""] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
      currentMode = "visual"
      -- debugText = "visual-block"
    end,
    ["c"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_command)
      currentMode = "command"
      -- debugText = "command"
    end,
    ["r"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_replace)
      currentMode = "replace"
      -- debugText = "replace"
    end,
    ["s"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_select)
      currentMode = "select"
      -- debugText = "select"
    end,
    ["t"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_terminal)
      currentMode = "terminal"
      -- debugText = "terminal"
    end,
    ["nt"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_terminal_n)
      currentMode = "terminal_n"
      -- debugText = "normal-terminal"
    end,
    ["no"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_operator)
      currentMode = "operator"
      -- debugText = "operator-pending"
    end,
    ["default"] = function()
      vim.api.nvim_set_hl_ns(0)
      currentMode = "default"
      -- debugText = "default"
    end,
  })()
end

---@return Colors
function M.hl_unblended()
  local options = require("moody.config").options
  return {
    normal = tohex(vim.api.nvim_get_hl(0, { name = "NormalMoody" }).fg) or options.colors.normal,
    insert = tohex(vim.api.nvim_get_hl(0, { name = "InsertMoody" }).fg) or options.colors.insert,
    visual = tohex(vim.api.nvim_get_hl(0, { name = "VisualMoody" }).fg) or options.colors.visual,
    command = tohex(vim.api.nvim_get_hl(0, { name = "CommandMoody" }).fg) or options.colors.command,
    operator = tohex(vim.api.nvim_get_hl(0, { name = "OperatorMoody" }).fg) or options.colors.operator,
    replace = tohex(vim.api.nvim_get_hl(0, { name = "ReplaceMoody" }).fg) or options.colors.replace,
    select = tohex(vim.api.nvim_get_hl(0, { name = "SelectMoody" }).fg) or options.colors.select,
    terminal = tohex(vim.api.nvim_get_hl(0, { name = "TerminalMoody" }).fg) or options.colors.terminal,
    terminal_n = tohex(vim.api.nvim_get_hl(0, { name = "TerminalNormalMoody" }).fg) or options.colors.terminal_n,
  }
end

---@param filetype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
function M.is_disabled_filetype(filetype)
  local disabled_filetypes = require("moody.config").options.disabled_filetypes
  return vim.tbl_contains(disabled_filetypes, filetype)
end

---@alias blend function
--- get darkened variant of the HL colours
--- @param blend table|number: number: a number between 0 and 1 used to darken.
--- table: a table of modes with their respective blend
--- @return Colors: a table of all the modes with values of blended colors
function M.hl_blended(blend)
  local blend_type = type(blend)
  if blend_type == "table" then
    return {
      normal = darken(M.hl_unblended().normal, blend.normal),
      insert = darken(M.hl_unblended().insert, blend.insert),
      visual = darken(M.hl_unblended().visual, blend.visual),
      command = darken(M.hl_unblended().command, blend.command),
      operator = darken(M.hl_unblended().operator, blend.operator),
      replace = darken(M.hl_unblended().replace, blend.replace),
      select = darken(M.hl_unblended().select, blend.select),
      terminal = darken(M.hl_unblended().terminal, blend.terminal),
      terminal_n = darken(M.hl_unblended().terminal_n, blend.terminal_n),
    }
  else
    if blend_type == "number" then
      return {
        normal = darken(M.hl_unblended().normal, blend),
        insert = darken(M.hl_unblended().insert, blend),
        visual = darken(M.hl_unblended().visual, blend),
        command = darken(M.hl_unblended().command, blend),
        operator = darken(M.hl_unblended().operator, blend),
        replace = darken(M.hl_unblended().replace, blend),
        select = darken(M.hl_unblended().select, blend),
        terminal = darken(M.hl_unblended().terminal, blend),
        terminal_n = darken(M.hl_unblended().terminal_n, blend),
      }
    else
      return {
        normal = darken(M.hl_unblended().normal, 0.2),
        insert = darken(M.hl_unblended().insert, 0.2),
        visual = darken(M.hl_unblended().visual, 0.2),
        command = darken(M.hl_unblended().command, 0.2),
        operator = darken(M.hl_unblended().operator, 0.2),
        replace = darken(M.hl_unblended().replace, 0.2),
        select = darken(M.hl_unblended().select, 0.2),
        terminal = darken(M.hl_unblended().terminal, 0.2),
        terminal_n = darken(M.hl_unblended().terminal_n, 0.2),
      }
    end
  end
end

--- short hand method for printing stuff in neovim
--- @param v any
--- @return any
function M.P(v)
  print(vim.inspect(v))
  return v
end

--- Updates a highlight group.
---
--- @param ns integer Namespace id for this highlight `nvim_create_namespace()`.
---              Use 0 to set a highlight group globally `:highlight`.
---              Highlights from non-global namespaces are not active by
---              default, use `nvim_set_hl_ns()` or `nvim_win_set_hl_ns()` to
---              activate them.
--- @param name string Highlight group name, e.g. "ErrorMsg"
--- @param val vim.api.keyset.highlight Highlight definition map, accepts the following keys:
---            • fg: color name or "#RRGGBB", see note.
---            • bg: color name or "#RRGGBB", see note.
---            • sp: color name or "#RRGGBB"
---            • blend: integer between 0 and 100
---            • bold: boolean
---            • standout: boolean
---            • underline: boolean
---            • undercurl: boolean
---            • underdouble: boolean
---            • underdotted: boolean
---            • underdashed: boolean
---            • strikethrough: boolean
---            • italic: boolean
---            • reverse: boolean
---            • nocombine: boolean
---            • link: name of another highlight group to link to, see
---              `:hi-link`.
---            • default: Don't override existing definition `:hi-default`
---            • ctermfg: Sets foreground of cterm color `ctermfg`
---            • ctermbg: Sets background of cterm color `ctermbg`
---            • cterm: cterm attribute map, like `highlight-args`. If not
---              set, cterm attributes will match those from the attribute map
---              documented above.
---            • force: if true force update the highlight group when it
---              exists.
function M.change_hl_property(ns, name, val)
  local old_hl = vim.api.nvim_get_hl(ns and ns or 0, { name = name })
  local new_hl = vim.tbl_extend("force", old_hl, val)
  vim.api.nvim_set_hl(ns and ns or 0, name, new_hl)
end
return M
