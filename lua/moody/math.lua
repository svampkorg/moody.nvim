---@class MathModule
---@field int_to_hex_string function: convert an integer colour to a "#rrggbb" string
---@field rgb function: split a "#rrggbb" string into {r, g, b} channels
---@field blend function: mix two colours by an amount from 0 (bg) to 1 (fg)
local M = {}

--- Will turn a integer colour value into a string hex value
--- @param number number: an integer number to convert
--- @return string: the string representation of the integer in a '%06x' format
--- @see string:format
function M.int_to_hex_string(number)
  if not number then
    return number
  else
    return "#" .. ("%06x"):format(number)
  end
end

-- Colour blending "borrowed" from folke/tokyonight.nvim (lua/tokyonight/util.lua).
-- M.bg / M.fg are the fallback endpoints when blend() is called without an
-- explicit background/foreground.
M.bg = "#000000"
M.fg = "#ffffff"

---@param c  string
function M.rgb(c)
  c = string.lower(c)
  return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) }
end

---@param foreground string foreground color
---@param background string background color
---@param alpha number|string number between 0 and 1. 0 results in bg, 1 results in fg
function M.blend(foreground, alpha, background)
  alpha = type(alpha) == "string" and (tonumber(alpha, 16) / 0xff) or alpha
  local bg = M.rgb(background or M.bg)
  local fg = M.rgb(foreground or M.fg)

  local function blendChannel(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02x%02x%02x", blendChannel(1), blendChannel(2), blendChannel(3))
end

return M
