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

local hl = require("moody.utils").change_hl_property
local utils = require("moody.utils")

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
  local right_padding = M.options.recording.right_padding
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
    -- TODO: make this into a repeatable space, so one can define some right padding
    { (" "):rep(right_padding), "CursorLine" },
  }
end

---@param filetype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
local function is_disabled_filetype(filetype)
  local disabled_filetypes = require("moody.config").options.disabled_filetypes
  return vim.tbl_contains(disabled_filetypes, filetype)
end

---@param buftype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
local function is_disabled_buftype(buftype)
  local disabled_buftypes = require("moody.config").options.disabled_buftypes
  return vim.tbl_contains(disabled_buftypes, buftype)
end

local function setup_ns_and_hlgroups()
  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blends)

  local statusLineHl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
  local visualHl = vim.api.nvim_get_hl(0, { name = "Visual" })
  local cursorLineHl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  -- local cursorLineSignHl = vim.api.nvim_get_hl(0, { name = "CursorLineSign" })
  -- local cursorLineFoldHl = vim.api.nvim_get_hl(0, { name = "CursorLineFold" })
  -- local signColumnHL = vim.api.nvim_get_hl(0, { name = "SignColumn" })
  -- local foldColumnHL = vim.api.nvim_get_hl(0, { name = "FoldColumn" })

  local visual_default_bg = visualHl.bg
  local cursorline_default_bg = cursorLineHl.bg
  -- local cursorline_sign_default_bg = cursorLineSignHl.bg
  -- local cursorline_fold_default_bg = cursorLineFoldHl.bg
  -- local sign_default_bg = cursorLineSignHl.bg
  -- local fold_default_bg = cursorLineFoldHl.bg

  local extend_to_linenr = M.options.extend_to_linenr
  local reduce_cursorline = M.options.reduce_cursorline
  local extend_to_signs = M.options.extend_to_signs
  local extend_to_folds = M.options.extend_to_folds
  local moody_column = M.options.moody_column

  for _, mode in ipairs(M.modes) do
    M["ns_" .. mode] = vim.api.nvim_create_namespace("Moody_" .. mode .. "_ns")

    local mode_color_unblended = M.options.hl_unblended[mode]
    local mode_color_blended = M.options.hl_blended[mode]

    hl(M["ns_" .. mode], "CursorLine", { bg = reduce_cursorline and cursorline_default_bg or mode_color_blended })
    hl(M["ns_" .. mode], "CursorLineInverse", { fg = mode_color_blended })

    hl(M["ns_" .. mode], "CursorLineNr", {
      fg = mode_color_unblended,
      bold = M.options.bold_nr,
      bg = "none",
    })
    hl(M["ns_" .. mode], "CursorLineSign", {
      bg = "none",
    })
    hl(M["ns_" .. mode], "CursorLineFold", {
      bg = "none",
    })

    -- I use this for my statusline mode indicator
    hl(M["ns_" .. mode], "StatusLineMoody", {
      fg = mode_color_unblended,
      bold = M.options.bold_nr,
      bg = statusLineHl.bg,
    })
    hl(M["ns_" .. mode], "StatusLineMoodyInverted", {
      bg = mode_color_unblended,
      bold = M.options.bold_nr,
      fg = statusLineHl.bg,
    })

    if extend_to_linenr then
      hl(M["ns_" .. mode], "CursorLineNr", {
        fg = mode_color_unblended,
        bold = M.options.bold_nr,
        bg = reduce_cursorline and cursorline_default_bg or mode_color_blended,
      })
    end

    if extend_to_signs then
      hl(M["ns_" .. mode], "CursorLineSign", {
        bg = reduce_cursorline and cursorline_default_bg or mode_color_blended,
      })
    end

    if extend_to_folds then
      hl(M["ns_" .. mode], "CursorLineFold", {
        bg = reduce_cursorline and cursorline_default_bg or mode_color_blended,
      })
    end

    if moody_column.enabled then
      local fold_colors = utils.generate_gradients(
        M.options.moody_column.folds_start_color,
        M.options.moody_column.folds_end_color,
        vim.o.foldnestmax
      )
      -- for fold levels
      for level, color in ipairs(fold_colors) do
        -- set the hl for foldcolumn for not current line
        hl(M["ns_" .. mode], "FoldLevel_" .. level, { fg = color })
        if mode == "visual" then
          hl(
            M["ns_" .. mode],
            "FoldLevelVisual_" .. level,
            { fg = color, bg = reduce_cursorline and cursorline_default_bg or mode_color_blended }
          )
        end
        -- settings for fold, and in case of ufo UfoCursorFoldedLine
        hl(
          M["ns_" .. mode],
          "UfoCursorFoldedLine",
          { bg = reduce_cursorline and cursorline_default_bg or mode_color_blended }
        )

        -- set the hl for foldcolumn for current line
        hl(M["ns_" .. mode], "CursorLineFoldLevel_" .. level, {
          -- extend_to_linenr because folds come before linenr
          bg = extend_to_linenr and (reduce_cursorline and cursorline_default_bg or mode_color_blended) or "none",
          fg = color,
        })
      end
    end
  end

  -- visual need special treatment
  vim.api.nvim_set_hl(
    ---@diagnostic disable-next-line: undefined-field
    M.ns_visual,
    "Visual",
    { bg = reduce_cursorline and visual_default_bg or M.options.hl_blended.visual }
  )

  -- Special hl group in global ns for use where you might want just a normal cursorline
  vim.api.nvim_set_hl(
    0,
    "MoodyNormal",
    { bg = reduce_cursorline and cursorline_default_bg or M.options.hl_blended.normal }
  )

  -- normal cursorline for global ns
  vim.api.nvim_set_hl(
    0,
    "CursorLine",
    { bg = reduce_cursorline and cursorline_default_bg or M.options.hl_blended.normal }
  )
end

---@class Config
---@field blends Blends: how much to blend colors with black for the cursorline
---@field colors Colors: table of colours with respective mode
---@field disabled_filetypes table<string>: List of filetypes to disable this plugin for
---@field disabled_buftypes table<string>: List of buffers to disable this plugin for
---@field bold_nr boolean: bold linenumbers or not
---@field reduce_cursorline boolean: bold linenumbers or not
---@field extend_to_linenr boolean: extend the cursorline into linenumbers
---@field recording Recording: bold linenumbers or not
---@field extend_to_signs boolean: textend to signcolumn
---@field extend_to_folds boolean: textend to foldcolumn
---@field moody_column MoodyColumn: settings for the statuscolumn folds
M.options = {}

---@type Config
---@diagnostic disable-next-line: missing-fields
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
  ---@class MoodyColumn
  ---@field enabled boolean: extend moody to statuscolumn
  ---@field folds_start_color string: hex format start color for fold levels
  ---@field folds_end_color string: hex format end color for fold levels
  moody_column = {
    enabled = false,
    folds_start_color = "#C1C1C1",
    folds_end_color = "#2F2F2F",
  },
  ---@type table<string>
  disabled_filetypes = {},
  ---@type table<string>
  disabled_buftypes = {},
  ---@type boolean
  bold_nr = true,
  ---@type boolean
  reduce_cursorline = false,
  ---@type boolean
  extend_to_linenr = false,
  ---@type boolean
  extend_to_signs = false,
  ---@type boolean
  extend_to_folds = false,
  ---@class Recording
  ---@field enabled boolean: set to true to enable recording indicator
  ---@field icon string: set an icon to show next to the register indicator
  ---@field pre_registry_text string: text or char to show before recording registry
  ---@field post_registry_text string: text or char to show after recording registry
  ---@field right_padding integer: how much space to pad to the right of the recording indicator (shifts it to the left)
  recording = {
    enabled = false,
    icon = "󰑋",
    pre_registry_text = "[",
    post_registry_text = "]",
    right_padding = 2,
  },
}

--- switches the hl-namespace depending on the mode in event.
--- only usefull for ModeChanged event, as it's used in
--- ModeChanged autocommand inside this plugin.
---@param event any
function M.trigger_mode(event)
  local mode = string.match(event.match, ".*:([^:]+)")
  local win = vim.api.nvim_get_current_win()

  utils.switch(mode, {
    ["n"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_normal)
    end,
    ["i"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
    end,
    ["ix"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_insert)
    end,
    ["v"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
    end,
    ["V"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
    end,
    [""] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_visual)
    end,
    ["c"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_command)
    end,
    ["r"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_replace)
    end,
    ["s"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_select)
    end,
    ["t"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_terminal)
    end,
    ["nt"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_terminal_n)
    end,
    ["no"] = function()
      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_win_set_hl_ns(win, M.ns_operator)
    end,
    ["default"] = function()
      vim.api.nvim_set_hl_ns(0)
    end,
  })()
end

local function setup_statuscolumn()
  if M.options.moody_column.enabled then
    vim.cmd("set statuscolumn=%!v:lua.require('moody.statuscolumn').myStatusColumn()")
  end
end

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
function M.__setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})

  local mode_group = vim.api.nvim_create_augroup("MoodyModeGroup", { clear = true })
  local rec_group = vim.api.nvim_create_augroup("MoodyRecordingGroup", { clear = true })

  -- load up the "colour caches" and setup highlights with it
  setup_ns_and_hlgroups()

  if M.options.moody_column.enabled then
    -- setup signcolumn
    setup_statuscolumn()
  end

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
      if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      M.trigger_mode(event)
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
      if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("cursorline", true, {
        win = win,
      })
    end,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = mode_group,
    callback = function(_)
      if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("cursorline", false, {
        win = win,
      })
    end,
  })

  if M.options.recording.enabled then
    vim.api.nvim_create_autocmd({ "RecordingEnter" }, {
      group = rec_group,
      callback = function(event)
        if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
          vim.api.nvim_set_hl_ns(0)
          return
        end

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
        if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
          vim.api.nvim_set_hl_ns(0)
          return
        end

        M.del_sl_mark(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = rec_group,
      callback = function(event)
        if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
          vim.api.nvim_set_hl_ns(0)
          return
        end

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
        if is_disabled_filetype(vim.bo.filetype) or is_disabled_buftype(vim.bo.buftype) then
          vim.api.nvim_set_hl_ns(0)
          return
        end

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
