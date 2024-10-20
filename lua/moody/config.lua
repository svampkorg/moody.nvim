---@class ConfigModule
---@field defaults Config: default options
---@field options Config: config table extending defaults
local M = {}

M.modes = {
  "normal",
  "insert",
  "visual",
  "command",
  "operator",
  "replace",
  "select",
  "terminal",
  "terminal_n",
}

M.sl_mark = vim.api.nvim_create_namespace("moodyline")

M.set_sl_mark = function(buffer, line, col, opts)
  M.sl_id = vim.api.nvim_buf_set_extmark(buffer, M.sl_mark, line, col, opts)
end

M.del_sl_mark = function(buffer)
  if not M.sl_mark or not M.sl_id then
    return
  end
  vim.api.nvim_buf_del_extmark(buffer, M.sl_mark, M.sl_id)
end

local function get_rec_text()
  local rec_reg = vim.fn.reg_recording()
  if rec_reg == "" then
    return ""
  else
    return M.options.recording.pre_registry_text .. rec_reg .. M.options.recording.post_registry_text .. " "
  end
end

local function get_virt_text()
  if get_rec_text() == "" then
    return nil
  end
  return {
    {
      " " .. (M.options.recording.icon or "󰑋") .. " ",
      { "CursorLineNr", "DiagnosticError", "CursorLine" },
    },
    {
      get_rec_text(),
      { "CursorLineNr", "CursorLine" },
    },
  }
end

---@param filetype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
local function is_disabled_filetype(filetype)
  local disabled_filetypes = require("moody.config").options.disabled_filetypes
  return vim.tbl_contains(disabled_filetypes, filetype)
end

-- local function setup_hl(ns, name, val)
--   vim.api.nvim_set_hl(ns and ns or 0, name, val)
-- end

local function setup_ns_and_hlgroups()
  local utils = require("moody.utils")
  local hl = utils.change_hl_property
  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blends)
  local statusLineHl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
  local extend = M.options.extend_cursorline

  for _, mode in ipairs(M.modes) do
    M["ns_" .. mode] = vim.api.nvim_create_namespace("Moody_" .. mode .. "_ns")

    hl(M["ns_" .. mode], "CursorLine", { bg = M.options.hl_blended[mode] })
    hl(M["ns_" .. mode], "CursorLineInverse", { fg = M.options.hl_blended[mode] })

    hl(M["ns_" .. mode], "CursorLineNr", {
      fg = M.options.hl_unblended[mode],
      bold = M.options.bold_nr,
      bg = "none",
    })

    hl(M["ns_" .. mode], "LineNrOffset", {
      fg = M.options.hl_blended[mode],
      bold = M.options.bold_nr,
      bg = "none",
    })

    if extend then
      hl(M["ns_" .. mode], "CursorLineNr", {
        fg = M.options.hl_unblended[mode],
        bold = M.options.bold_nr,
        bg = M.options.hl_blended[mode],
        force = true,
      })
      hl(M["ns_" .. mode], "CursorLineFold", {
        fg = M.options.hl_unblended[mode],
        bold = M.options.bold_nr,
        bg = M.options.hl_blended[mode],
        force = true,
      })
      hl(M["ns_" .. mode], "CursorLineSign", {
        fg = M.options.hl_unblended[mode],
        bold = M.options.bold_nr,
        bg = M.options.hl_blended[mode],
        force = true,
      })
    end

    hl(
      M["ns_" .. mode],
      "StatusLineMode",
      { fg = M.options.hl_unblended[mode], bold = M.options.bold_nr, bg = statusLineHl.bg }
    )
  end

  -- visual need special treatment
  ---@diagnostic disable-next-line: undefined-field
  vim.api.nvim_set_hl(M.ns_visual, "Visual", { bg = M.options.hl_blended.visual })

  -- if M.options.extend_cursorline then
  --   vim.api.nvim_set_hl(M.ns_normal, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_insert, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_visual, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_command, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_operator, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_replace, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_select, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_terminal, "CursorLineFold", { bg = M.options.hl_blended.normal })
  --   vim.api.nvim_set_hl(M.ns_terminal_n, "CursorLineFold", { bg = M.options.hl_blended.normal })
  -- end
end

-- local function setup_hl_namespaces()
--   for _, mode in ipairs(M.modes) do
--     M["ns_" .. mode] = vim.api.nvim_create_namespace("Moody_" .. mode .. "_ns")
--   end
--
--   -- M.ns_normal = vim.api.nvim_create_namespace("Moody_NORMAL_NS")
--   -- M.ns_insert = vim.api.nvim_create_namespace("Moody_INSERT_NS")
--   -- M.ns_visual = vim.api.nvim_create_namespace("Moody_VISUAL_NS")
--   -- M.ns_command = vim.api.nvim_create_namespace("Moody_COMMAND_NS")
--   -- M.ns_operator = vim.api.nvim_create_namespace("Moody_OPERATOR_NS")
--   -- M.ns_replace = vim.api.nvim_create_namespace("Moody_REPLACE_NS")
--   -- M.ns_select = vim.api.nvim_create_namespace("Moody_SELECT_NS")
--   -- M.ns_terminal = vim.api.nvim_create_namespace("Moody_TERMINAL_NS")
--   -- M.ns_terminal_n = vim.api.nvim_create_namespace("Moody_TERMINAL_N_NS")
-- end

---@class Config
---@field blends Blends: how much to blend colors with black for the cursorline
---@field colors Colors: table of colours with respective mode
---@field disabled_filetypes table<string>: List of buffers to disable this plugin for
---@field bold_nr boolean: bold linenumbers or not
---@field extend_cursorline boolean: extend the cursorline into signcolumn
---@field recording Recording: bold linenumbers or not
M.options = {}

---@type Config
M.defaults = {
  ---@class Blends
  ---@field normal number: hex value for normal mode color
  ---@field insert number: hex value for insert mode color
  ---@field visual number: hex value for visual mode color
  ---@field command number: hex value for command mode color
  ---@field operator number: hex value for operator mode color
  ---@field replace number: hex value for replace mode color
  ---@field select number: hex value for select mode color
  ---@field terminal number: hex value for terminal mode color
  ---@field terminal_n number: hex value for terminal normal mode color
  blends = {
    normal = 0.2,
    insert = 0.2,
    visual = 0.2,
    command = 0.2,
    operator = 0.2,
    replace = 0.2,
    select = 0.2,
    terminal = 0.2,
    terminal_n = 0.2,
  },
  ---@class Colors
  ---@field normal string: hex value for normal mode color
  ---@field insert string: hex value for insert mode color
  ---@field visual string: hex value for visual mode color
  ---@field command string: hex value for command mode color
  ---@field operator string: hex value for operator mode color
  ---@field replace string: hex value for replace mode color
  ---@field select string: hex value for select mode color
  ---@field terminal string: hex value for terminal mode color
  ---@field terminal_n string: hex value for terminal normal mode color
  colors = {
    normal = "#00BFFF",
    insert = "#70CF67",
    visual = "#AD6FF7",
    command = "#EB788B",
    operator = "#FF8F40",
    replace = "#E66767",
    select = "#AD6FF7",
    terminal = "#4CD4BD",
    terminal_n = "#00BBCC",
  },
  ---@type table<string>
  disabled_filetypes = {},
  ---@type boolean
  bold_nr = true,
  ---@type boolean
  extend_cursorline = false,
  ---@class Recording
  ---@field enabled boolean: set to true to enable recording indicator
  ---@field icon string: set an icon to show next to the register indicator
  ---@field pre_registry_text string: text or char to show before recording registry
  ---@field post_registry_text string: text or char to show after recording registry
  recording = {
    enabled = false,
    icon = "󰑋",
    pre_registry_text = "[",
    post_registry_text = "]",
  },
}

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
function M.__setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
  local utils = require("moody.utils")

  local mode_group = vim.api.nvim_create_augroup("MoodyModeGroup", { clear = true })
  local rec_group = vim.api.nvim_create_augroup("MoodyRecordingGroup", { clear = true })
  -- load up the "colour caches" and setup highlights with it
  setup_ns_and_hlgroups()

  -- A few cases where cursorline is needed to be set to not
  -- have a default gray line before any modes are enterd.
  vim.api.nvim_create_autocmd({
    -- Added to set normal colors when only one buffer is open
    "BufWinEnter",
    -- Whenever entering a window
    "WinEnter",
    -- Added to catch when leaving telescope
    "InsertLeave",
  }, {
    group = mode_group,
    callback = function()
      if is_disabled_filetype(vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_set_hl_ns(M.ns_normal)
    end,
  })

  -- set highlight depending on mode changed
  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    desc = "set highlights depending on mode",
    group = mode_group,
    callback = function(event)
      -- restore all highlights if disabled
      if is_disabled_filetype(vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      -- regex match with mode entered
      local mode = string.match(event.match, ".*:([^:]+)")

      local win = vim.api.nvim_get_current_win()

      -- local debugText = "default"

      utils.switch(mode, {
        ["n"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_normal)
          -- debugText = "normal"
        end,
        ["i"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
          -- debugText = "insert"
        end,
        ["ix"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
          -- debugText = "insert-completion"
        end,
        ["v"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
          -- debugText = "visual"
        end,
        ["V"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
          -- debugText = "visual-line"
        end,
        [""] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
          -- debugText = "visual-block"
        end,
        ["c"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_command)
          -- debugText = "command"
        end,
        ["r"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_replace)
          -- debugText = "replace"
        end,
        ["s"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_select)
          -- debugText = "select"
        end,
        ["t"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_terminal)
          -- debugText = "terminal"
        end,
        ["nt"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_terminal_n)
          -- debugText = "normal-terminal"
        end,
        ["no"] = function()
          ---@diagnostic disable-next-line: undefined-field
          vim.api.nvim_win_set_hl_ns(win, M.ns_operator)
          -- debugText = "operator-pending"
        end,
        ["default"] = function()
          vim.api.nvim_set_hl_ns(0)
          -- debugText = "default"
        end,
      })()

      -- setup and print some debug data top cmdline
      -- local debugdata = "mode is " .. mode .. " debugText is: " .. debugText
      -- vim.cmd(string.format([[echo "%s"]], debugdata))
    end,
  })

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = mode_group,
    callback = setup_ns_and_hlgroups,
  })

  -- only show cursorline in active window
  vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = mode_group,
    callback = function(_)
      local win = vim.api.nvim_get_current_win()
      -- vim.wo.cursorline = true
      vim.api.nvim_set_option_value("cursorline", true, {
        win = win,
      })
    end,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = mode_group,
    callback = function(_)
      local win = vim.api.nvim_get_current_win()
      -- vim.wo.cursorline = false
      vim.api.nvim_set_option_value("cursorline", false, {
        win = win,
      })
    end,
  })

  if M.options.recording.enabled then
    vim.api.nvim_create_autocmd({ "RecordingEnter" }, {
      group = rec_group,
      callback = function(event)
        if not get_virt_text() then
          return
        end

        local win_id = vim.api.nvim_get_current_win()
        local cursor_line_pos = vim.api.nvim_win_get_cursor(win_id)

        M.set_sl_mark(event.buf, cursor_line_pos[1] - 1, 0, {
          id = M.sl_id,
          virt_text = get_virt_text(),
          hl_mode = "blend",
          virt_text_pos = "right_align",
        })
      end,
    })

    vim.api.nvim_create_autocmd({ "RecordingLeave" }, {
      group = rec_group,
      callback = function(event)
        M.del_sl_mark(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = rec_group,
      callback = function(event)
        if not get_virt_text() then
          return
        end
        local win_id = vim.api.nvim_get_current_win()
        local cursor_line_pos = vim.api.nvim_win_get_cursor(win_id)
        M.set_sl_mark(event.buf, cursor_line_pos[1] - 1, 0, {
          id = M.sl_id,
          virt_text = get_virt_text(),
          hl_mode = "blend",
          virt_text_pos = "right_align",
        })
      end,
    })

    vim.api.nvim_create_autocmd({ "WinLeave" }, {
      group = rec_group,
      callback = function(event)
        M.del_sl_mark(event.buf)
      end,
    })
  end
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
