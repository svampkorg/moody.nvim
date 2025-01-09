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

function M.set_sl_mark(buffer, line, col, opts)
  M.sl_id = vim.api.nvim_buf_set_extmark(buffer, M.sl_mark, line, col, opts)
end

function M.del_sl_mark(buffer)
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

---@return boolean: Current window is part of disabled windows
local function is_disabled_window_list()
  local win = vim.api.nvim_get_current_win()
  return M.options.disabled_list["win" .. win] ~= nil
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

---@param buftype string: the filetype to check if it's disabled
---@param filetype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes or buftypes
function M.is_disabled(buftype, filetype)
  return is_disabled_buftype(buftype) or is_disabled_filetype(filetype) or is_disabled_window_list()
end

local function setup_ns_and_hlgroups()
  M.options.hl_unblended = utils.hl_unblended()
  M.options.hl_blended = utils.hl_blended(M.options.blends)

  -- local statusLineHl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
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

  local moody_column = M.options.moody_column
  local default_cursorline = M.options.default_cursorline
  local extend_to_linenr = M.options.extend_to_linenr or moody_column.enabled
  local extend_to_signs = M.options.extend_to_signs or moody_column.enabled
  local extend_to_folds = M.options.extend_to_folds or moody_column.enabled

  -- local extend_to_linenr = M.options.extend_to_linenr
  -- local extend_to_signs = M.options.extend_to_signs
  -- local extend_to_folds = M.options.extend_to_folds

  for _, mode in ipairs(M.modes) do
    M["ns_" .. mode] = vim.api.nvim_create_namespace("Moody_" .. mode .. "_ns")

    local mode_color_unblended = M.options.hl_unblended[mode]
    local mode_color_blended = M.options.hl_blended[mode]

    hl(M["ns_" .. mode], "MoodyAlphabeticMark", {
      fg = "#ff007c",
      bg = "none",
      -- bold = true,
    })
    hl(M["ns_" .. mode], "MoodyAlphabeticMarkMode", {
      fg = "#ff007c",
      bg = mode_color_blended,
    })
    hl(M["ns_" .. mode], "MoodyOtherMark", {
      fg = "#48ff32",
      bg = "none",
      -- bold = true,
    })
    hl(M["ns_" .. mode], "MoodyOtherMarkMode", {
      fg = "#48ff32",
      bg = mode_color_blended,
      -- bold = true,
    })

    hl(M["ns_" .. mode], "MoodySignColumn", {
      bg = "none",
    })
    hl(M["ns_" .. mode], "MoodySignColumnMode", {
      bg = mode_color_blended,
    })

    -- hl(M["ns_" .. mode], "MiniDiffSignAddMoody", {
    --   bg = mode_color_blended,
    -- })
    -- hl(M["ns_" .. mode], "MiniDiffSignChangeMoody", {
    --   bg = mode_color_blended,
    -- })
    -- hl(M["ns_" .. mode], "MiniDiffSingDeleteMoody", {
    --   bg = mode_color_blended,
    -- })
    hl(M["ns_" .. mode], "MoodyAdded", {
      link = "Added",
      bg = mode_color_blended,
    })
    hl(M["ns_" .. mode], "MoodyChanged", {
      link = "Changed",
      bg = mode_color_blended,
    })
    hl(M["ns_" .. mode], "MoodyRemoved", {
      link = "Removed",
      bg = mode_color_blended,
    })

    -- hl(M["ns_" .. mode], "MoodyColumnInVisual", {
    --   bg = M.options.hl_blended["visual"],
    -- })

    -- hl(M["ns_" .. mode], "SignVisual", {
    --   bg = M.options.hl_blended["visual"],
    -- })

    hl(M["ns_" .. mode], "MoodySeparator", {
      fg = moody_column.separator.color or cursorline_default_bg,
      bg = "none",
    })

    hl(M["ns_" .. mode], "MoodySeparatorMode", {
      fg = moody_column.separator.color or cursorline_default_bg,
      bg = mode_color_blended,
    })

    hl(M["ns_" .. mode], "MoodySign", {
      bg = mode_color_blended,
    })

    hl(M["ns_" .. mode], "CursorLine", { bg = default_cursorline and cursorline_default_bg or mode_color_blended })
    hl(M["ns_" .. mode], "CursorLineInverse", { fg = mode_color_blended })

    hl(M["ns_" .. mode], "CursorLineNr", {
      fg = mode_color_unblended,
      bold = M.options.bold_nr,
      bg = extend_to_linenr and mode_color_blended or "none",
    })
    hl(M["ns_" .. mode], "CursorLineSign", {
      bg = extend_to_signs and mode_color_blended or "none",
    })
    hl(M["ns_" .. mode], "CursorLineFold", {
      bg = extend_to_folds and mode_color_blended or "none",
    })

    -- I use this for my statusline mode indicator
    hl(M["ns_" .. mode], "StatusLineMoody", {
      fg = mode_color_unblended,
      bold = M.options.bold_nr,
      bg = mode_color_blended,
    })
    hl(M["ns_" .. mode], "StatusLineMoodyInverted", {
      bg = mode_color_unblended,
      bold = M.options.bold_nr,
      fg = mode_color_blended,
    })

    if extend_to_linenr then
      hl(M["ns_" .. mode], "CursorLineNr", {
        fg = mode_color_unblended,
        bold = M.options.bold_nr,
        bg = default_cursorline and cursorline_default_bg or mode_color_blended,
      })
    end

    if extend_to_signs then
      hl(M["ns_" .. mode], "CursorLineSign", {
        bg = default_cursorline and cursorline_default_bg or mode_color_blended,
      })
    end

    if extend_to_folds then
      hl(M["ns_" .. mode], "CursorLineFold", {
        bg = default_cursorline and cursorline_default_bg or mode_color_blended,
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
            { fg = color, bg = default_cursorline and cursorline_default_bg or mode_color_blended }
          )
        end
        -- settings for fold, and in case of ufo UfoCursorFoldedLine
        hl(
          M["ns_" .. mode],
          "UfoCursorFoldedLine",
          { bg = default_cursorline and cursorline_default_bg or mode_color_blended }
        )

        -- set the hl for foldcolumn for current line
        hl(M["ns_" .. mode], "CursorLineFoldLevel_" .. level, {
          -- extend_to_linenr because folds come before linenr
          bg = extend_to_linenr and (default_cursorline and cursorline_default_bg or mode_color_blended) or "none",
          fg = color,
        })
      end
    end
  end

  -- visual need special treatment because neovim does
  -- not seem to use namespace specified hl group for Visual.
  hl(
    ---@diagnostic disable-next-line: undefined-field
    M.ns_visual,
    "Visual",
    { bg = default_cursorline and visual_default_bg or M.options.hl_blended.visual }
  )

  -- Special hl group in global ns for use where you might want just a normal cursorline
  hl(0, "MoodyNormal", { bg = default_cursorline and cursorline_default_bg or M.options.hl_blended.normal })
end

---@class Config
---@field blends Blends: how much to blend colors with black for the cursorline
---@field colors Colors: table of colours with respective mode
---@field disabled_filetypes table<string>: List of filetypes to disable this plugin for
---@field disabled_buftypes table<string>: List of buffers to disable this plugin for
---@field bold_nr boolean: bold linenumbers or not
---@field default_cursorline boolean: bold linenumbers or not
---@field extend_to_linenr boolean: extend the cursorline into linenumbers
---@field recording Recording: bold linenumbers or not
---@field extend_to_signs boolean: textend to signcolumn
---@field extend_to_folds boolean: textend to foldcolumn
---@field moody_column MoodyColumn: settings for the statuscolumn folds
---@field disabled_list table: list of window ids where Moody is disabled. Internally handled.
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
  ---@field disabled_list table: list of window ids where Moody is disabled. Internally handled.
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
  ---@class MoodyColumnSeparator
  ---@field char string: A character to use as separator. Defaults to empty.
  ---@field color string?: A hexadecimal value to use for the foreground of separator. Defaults to bg of CursorLine

  ---@class MoodyColumnOptions
  ---@field folds boolean: Include folds
  ---@field signs boolean: Include signs
  ---@field marks boolean: Incluse marks
  ---@field numbers boolean: Include line numbers

  ---@class MoodyColumn
  ---@field enabled boolean: use moody column
  ---@field extend_to boolean: extend moody to moody column
  ---@field folds_start_color string: hex format start color for fold levels
  ---@field folds_end_color string: hex format end color for fold levels
  ---@field separator MoodyColumnSeparator: some settings for the separator between moody_column and code
  ---@field column_options MoodyColumnOptions: What to show in the MoodyColumn
  ---@field alphabetic_marks boolean: Show alphabetic marks in the Column
  ---@field other_marks boolean: Show other non-alphabetic marks in the Column
  moody_column = {
    enabled = false,
    folds_start_color = "#C1C1C1",
    folds_end_color = "#2F2F2F",
    separator = {
      char = "",
      color = nil,
    },
    column_options = {
      folds = true,
      signs = true,
      marks = true,
      numbers = true,
    },
    alphabetic_marks = true,
    other_marks = true,
  },
  ---@type table<string>
  disabled_filetypes = {},
  ---@type table<string>
  disabled_buftypes = {
    "nofile",
    "terminal",
    "prompt",
  },
  disabled_list = {},
  ---@type boolean
  bold_nr = true,
  ---@type boolean
  default_cursorline = false,
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

---@param win integer: The window to trigger Moody for
function M.trigger(win)
  win = win or vim.api.nvim_get_current_win()
  M.options.disabled_list["win" .. win] = nil
  ---@diagnostic disable-next-line: undefined-field
  vim.api.nvim_win_set_hl_ns(win, M.ns_normal)
end

---@param win integer: The window to disable Moody for
function M.reset(win)
  win = win or vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) then
    M.options.disabled_list["win" .. win] = win
  end
  vim.api.nvim_set_hl_ns(0)
end

--- switches the hl-namespace depending on the mode in event.
--- only usefull for ModeChanged event, as it's used in
--- ModeChanged autocommand inside this plugin.
---@param event? any
---@param win? integer: window number to trigger for
function M.trigger_mode(event, win)
  event = nil
  local mode = "n"
  if event ~= nil then
    mode = string.match(event.match, ".*:([^:]+)")
  else
    ---@diagnostic disable-next-line: undefined-field
    mode = vim.api.nvim_get_mode().mode
  end
  win = win or vim.api.nvim_get_current_win()

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
    -- setup statuscolumn
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
      if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      ---@diagnostic disable-next-line: undefined-field
      vim.api.nvim_set_hl_ns(M.ns_normal)
    end,
  })

  -- set highlight depending on mode changed
  vim.api.nvim_create_autocmd({
    "ModeChanged",
  }, {
    desc = "set highlights depending on mode",
    group = mode_group,
    callback = function(event)
      if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
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
  vim.api.nvim_create_autocmd({
    "VimEnter",
    "WinEnter",
    "BufWinEnter",
  }, {
    group = mode_group,
    callback = function(_)
      if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
        vim.api.nvim_set_hl_ns(0)
        return
      end

      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("cursorline", true, {
        win = win,
      })
    end,
  })
  vim.api.nvim_create_autocmd({
    "WinLeave",
    "BufLeave",
  }, {
    group = mode_group,
    callback = function(_)
      if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
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
    vim.api.nvim_create_autocmd({
      "RecordingEnter",
    }, {
      group = rec_group,
      callback = function(event)
        if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
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

    vim.api.nvim_create_autocmd({
      "RecordingLeave",
    }, {
      group = rec_group,
      callback = function(event)
        if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
          vim.api.nvim_set_hl_ns(0)
          return
        end

        M.del_sl_mark(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({
      "CursorMoved",
    }, {
      group = rec_group,
      callback = function(event)
        if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
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

    vim.api.nvim_create_autocmd({
      "WinLeave",
    }, {
      group = rec_group,
      callback = function(event)
        if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
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
function M.__format_keys()
  local tbl = vim.split(vim.inspect(M.defaults), "\n")
  table.insert(tbl, 1, "<pre>")
  table.insert(tbl, 2, "Defaults: ~")
  table.insert(tbl, #tbl, "</pre>")
  return tbl
end

return M
