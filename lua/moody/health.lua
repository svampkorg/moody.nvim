---@class HealthModule
---@field check function: run `:checkhealth moody`
local M = {}

-- Support both the 0.10+ names (`vim.health.start`, ...) and the older
-- `vim.health.report_*` aliases, so health checks work on nvim 0.9 too.
local health = vim.health
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local report_error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start("moody")

  if vim.fn.has("nvim-0.9") == 1 then
    ok("Neovim >= 0.9")
  else
    report_error("Neovim >= 0.9 is required")
  end

  local config = require("moody.config")

  -- Has setup() run? M.options stays empty until then.
  if config.options and next(config.options) ~= nil then
    ok("setup() has run")
  else
    warn("setup() has not run yet; call require('moody').setup()")
  end

  -- Re-run the same validation setup() uses, against the live options.
  local valid, err = config.validate(config.options)
  if valid then
    ok("configuration is valid")
  else
    report_error("invalid configuration: " .. tostring(err))
  end

  -- The cursorline blend needs a background to blend against; without one it
  -- falls back to black/white by &background.
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if normal.bg then
    ok(("Normal highlight has a background (#%06x)"):format(normal.bg))
  else
    warn("Normal highlight has no background; cursorline blends against a black/white fallback")
  end

  local disabled = config.options.disabled or {}
  local ft = disabled.filetypes or {}
  local bt = disabled.buftypes or {}
  info(("disabled filetypes: %s"):format(#ft > 0 and table.concat(ft, ", ") or "none"))
  info(("disabled buftypes: %s"):format(#bt > 0 and table.concat(bt, ", ") or "none"))
end

return M
