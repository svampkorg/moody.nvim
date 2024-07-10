---@class ConfigModule
---@field defaults Config: default options
---@field options Config: config table extending defaults
local M    = {}

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
  disabled_buffers = {},
  bold_nr = true,
}


---@class Config
---@field blend table: how much to blend colors with black for the cursorline
---@field disabled_buffers table: List of buffers to disable this plugin for.. HELP!
---@field bold_nr boolean: bold linenumbers or not
M.options = {}

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
function M.__setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
  local utils = require("moody.utils")

  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blend)

  vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "disable Moody for certain filetypes",
    group = vim.api.nvim_create_augroup("MoodyGroup", { clear = true }),
    callback = function()
      -- its annoying to have dap windows change too. This is where I wanna also disable for buffers :P
      -- or maybe make it a list of filetypes instead. Might make more sense 🤔
      if string.match(vim.bo.filetype, "dapui") then
        vim.wo.cursorline = false
        -- this will set dapui titles to whatever they are
        vim.wo.winbar = " %t"
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    desc = "change cursor line depending on mode",
    group = vim.api.nvim_create_augroup("MoodyGroup", { clear = true }),
    callback = function()
      utils.hl_callback(M.options.hl_blended, M.options.hl_unblended, M.options.bold_nr)
    end
  })
  vim.api.nvim_set_hl(0, "Visual", { bg = M.options.hl_blended.visual })
  utils.hl_callback(M.options.hl_blended, M.options.hl_unblended, M.options.bold_nr)
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
