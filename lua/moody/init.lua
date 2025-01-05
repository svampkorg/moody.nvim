---@tag moody

---@brief [[
--- Moody!
---@brief ]]

---@class Moody
---@field setup function: setup the plugin
local moody = {}

---@param win integer: The window to trigger Moody for
function moody.trigger(win)
  require("moody.config").trigger(win)
end

---@param win integer: The window to disable Moody for
function moody.disable(win)
  require("moody.config").reset(win)
end

--- Setup the plugin
---@param options Config: config table
---@eval { ['description'] = require('moody.config').__format_keys() }
function moody.setup(options)
  require("moody.config").__setup(options)
end

return moody
