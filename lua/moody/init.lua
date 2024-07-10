---@tag moody

---@brief [[
--- Moody!
---@brief ]]

---@class Moody
---@field setup function: setup the plugin
local moody = {}

--- Setup the plugin
---@param options Config: config table
---@eval { ['description'] = require('moody.config').__format_keys() }
function moody.setup(options)
  require("moody.config").__setup(options)
end

return moody
