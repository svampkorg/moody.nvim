---@class MathModule
---@field int_to_hex_string function: Will return the bigger number
---@field blend function: Blends two colors together with an amount from 0 to 1,
--- 0 being one color and 1 being the other.
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

-- "Borrowed" from Mr Folke TokyoNight :)
-- https://github.com/folke/tokyonight.nvim/blob/66a272ba6cf93bf303c4b7a91b100ca0dd3ec7bd/lua/tokyonight/util.lua#L30
M.bg = "#000000"
M.fg = "#ffffff"
M.m_day_brightness = 0.3

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

  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02x%02x%02x", blendChannel(1), blendChannel(2), blendChannel(3))
end

function M.blend_bg(hex, amount, bg)
  return M.blend(hex, amount, bg or M.bg)
end

function M.blend_fg(hex, amount, fg)
  return M.blend(hex, amount, fg or M.fg)
end

M.darken = M.blend_bg
M.lighten = M.blend_fg

return M
