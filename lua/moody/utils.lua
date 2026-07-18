---@class Utils
---@field switch function: a switch kind of function, provide a lookup table and a key as case
---@field hl_unblended function: a function to return a table of Colors from either HL groups or Config
---@field is_disabled_filetype function: return true if filetype is disabled, false if not
---@field hl_blended function: calculate new blends using either a number or Blend
local M = {}

local darken = require("moody.math").darken
local blend_c = require("moody.math").blend

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

--- Resolve each mode's base colour: the `*Moody` highlight group's foreground
--- if a colorscheme defines it, otherwise the colour from the user config.
---@return Colors
function M.hl_unblended()
  local config = require("moody.config")
  local colors = config.options.colors
  local result = {}
  for _, mode in ipairs(config.modes) do
    local group_fg = tohex(vim.api.nvim_get_hl(0, { name = config.mode_hl_groups[mode] }).fg)
    result[mode] = group_fg or colors[mode]
  end
  return result
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
  -- Blend the mode colors toward the actual editor background, not a hardcoded
  -- black. Without this the cursorline is always blended toward #000000, which
  -- looks correct on a dark background but ignores light backgrounds entirely.
  local base = tohex(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
    or (vim.o.background == "light" and "#ffffff" or "#000000")

  local modes = require("moody.config").modes
  local unblended = M.hl_unblended()
  local blend_type = type(blend)

  -- Resolve the per-mode blend amount from either a table, a single number, or
  -- fall back to 0.2.
  local function amount(mode)
    if blend_type == "table" then
      return blend[mode]
    elseif blend_type == "number" then
      return blend
    end
    return 0.2
  end

  local result = {}
  for _, mode in ipairs(modes) do
    result[mode] = darken(unblended[mode], amount(mode), base)
  end
  return result
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

---generates a table of colors with a gradient from
---first (hex format) to second color (hex format) count steps
---@param first string: hex format #XXXXXX
---@param second string: hex format #XXXXXX
---@param steps integer: the number of steps to generate
---@return table
function M.generate_gradients(first, second, steps)
  local colors = {}
  local increment = 1 / steps

  -- var, limit, step
  for step = 0, 1, increment do
    table.insert(colors, blend_c(first, step, second))
  end
  return colors
end
return M
