---@class ConfigModule
---@field defaults Config: default options
---@field options Config: config table extending defaults
local M = {}

local blend = require("moody.math").blend
local tohex = require("moody.math").int_to_hex_string

-- Single source of truth for the modes moody colours. `M.modes` fixes the order
-- (namespace creation iterates it); `M.mode_hl_groups` maps each mode to the
-- `*Moody` highlight group a colorscheme can define to override its colour.
-- Everything mode-related (namespaces, blended/unblended colours) derives from
-- these two — do not hardcode the list anywhere else.
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

M.mode_hl_groups = {
  normal = "NormalMoody",
  insert = "InsertMoody",
  visual = "VisualMoody",
  command = "CommandMoody",
  operator = "OperatorMoody",
  replace = "ReplaceMoody",
  select = "SelectMoody",
  terminal = "TerminalMoody",
  terminal_n = "TerminalNormalMoody",
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
    return M.options.recording.prefix .. rec_reg .. M.options.recording.suffix .. " "
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
  return vim.tbl_contains(M.options.disabled.filetypes, filetype)
end

---@param buftype string: the filetype to check if it's disabled
---@return boolean: true if filetype was in list of disabled filetypes
local function is_disabled_buftype(buftype)
  return vim.tbl_contains(M.options.disabled.buftypes, buftype)
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

  local column = M.options.column
  local column_hl = column.highlight
  local lineNrHl = vim.api.nvim_get_hl(0, { name = "LineNr" })
  local normalHl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local signColumnHl = vim.api.nvim_get_hl(0, { name = "SignColumn" })
  local cursorLineHl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local line_number_only = M.options.line_number_only

  -- Separator between the moody column and the code: blend the LineNr
  -- foreground toward the editor background.
  local separator_color = lineNrHl.fg
  if normalHl.bg and lineNrHl.fg then
    separator_color = blend(tohex(normalHl.bg), 0.55, tohex(lineNrHl.fg))
  end

  local cursorline_default_bg = cursorLineHl.bg

  -- Enabling the moody column implies extending the cursorline through it.
  local extend = M.options.extend
  local extend_to_linenr = extend.line_number or column.enabled
  local extend_to_signs = extend.signs or column.enabled
  local extend_to_folds = extend.folds or column.enabled

  for _, mode in ipairs(M.modes) do
    M["ns_" .. mode] = vim.api.nvim_create_namespace("Moody_" .. mode .. "_ns")

    local mode_color_unblended = M.options.hl_unblended[mode]
    local mode_color_blended = M.options.hl_blended[mode]
    local mode_color_blended_darker = blend(tohex(normalHl.bg), 0.5, M.options.hl_blended[mode])

    hl(M["ns_" .. mode], "LineNr", {
      fg = column_hl.fg or lineNrHl.fg,
      bg = column_hl.bg or lineNrHl.bg,
    })
    hl(M["ns_" .. mode], "SignColumn", { bg = column_hl.bg or signColumnHl.bg })

    hl(M["ns_" .. mode], "MoodyAlphabeticMark", {
      fg = "#ff007c",
      bg = not line_number_only and column_hl.bg or "none",
    })
    hl(M["ns_" .. mode], "MoodyAlphabeticMarkMode", {
      fg = "#ff007c",
      bg = not line_number_only and mode_color_blended or "none",
    })
    hl(M["ns_" .. mode], "MoodyOtherMark", {
      fg = "#48ff32",
      bg = column_hl.bg or "none",
    })
    hl(M["ns_" .. mode], "MoodyOtherMarkMode", {
      fg = "#48ff32",
      bg = not line_number_only and mode_color_blended or "none",
    })

    hl(M["ns_" .. mode], "MoodySignColumn", {
      bg = column_hl.bg or "none",
    })
    hl(M["ns_" .. mode], "MoodySignColumnMode", {
      bg = mode_color_blended,
    })

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

    hl(M["ns_" .. mode], "MoodySeparator", {
      fg = separator_color,
      bg = lineNrHl.bg,
    })

    hl(M["ns_" .. mode], "MoodySeparatorMode", {
      fg = column.separator.highlight.fg or cursorline_default_bg,
      bg = not line_number_only and (mode_color_blended or cursorline_default_bg) or "none",
    })

    hl(M["ns_" .. mode], "MoodySign", {
      bg = not line_number_only and mode_color_blended or "none",
    })

    hl(M["ns_" .. mode], "CursorLine", { bg = mode_color_blended })
    hl(M["ns_" .. mode], "ColorColumn", { bg = mode_color_blended_darker })

    hl(M["ns_" .. mode], "CursorLineInverse", { fg = mode_color_blended })

    hl(M["ns_" .. mode], "CursorLineNr", {
      fg = mode_color_unblended,
      bold = M.options.bold_line_number,
      bg = not line_number_only and (extend_to_linenr and mode_color_blended) or (column_hl.bg or "none"),
    })
    hl(M["ns_" .. mode], "CursorLineSign", {
      bg = not line_number_only and (extend_to_signs and mode_color_blended) or (column_hl.bg or "none"),
    })
    hl(M["ns_" .. mode], "CursorLineFold", {
      bg = not line_number_only and (extend_to_folds and mode_color_blended) or (column_hl.bg or "none"),
    })

    -- Exposed for a statusline mode indicator.
    hl(M["ns_" .. mode], "StatusLineMoody", {
      fg = mode_color_unblended,
      bold = M.options.bold_line_number,
      bg = mode_color_blended,
    })
    hl(M["ns_" .. mode], "StatusLineMoodyInverted", {
      bg = mode_color_unblended,
      bold = M.options.bold_line_number,
      fg = mode_color_blended,
    })

    if column.enabled then
      local fold_colors = utils.generate_gradients(column.folds.start_color, column.folds.end_color, vim.o.foldnestmax)
      for level, color in ipairs(fold_colors) do
        -- fold-column colour for non-current lines
        hl(M["ns_" .. mode], "FoldLevel_" .. level, { fg = color })
        if mode == "visual" then
          hl(
            M["ns_" .. mode],
            "FoldLevelVisual_" .. level,
            { fg = color, bg = line_number_only and cursorline_default_bg or mode_color_blended }
          )
        end
        -- fold background (ufo's UfoCursorFoldedLine) on the cursor line
        hl(
          M["ns_" .. mode],
          "UfoCursorFoldedLine",
          { bg = line_number_only and cursorline_default_bg or mode_color_blended }
        )

        -- fold-column colour for the current line (folds sit before linenr)
        hl(M["ns_" .. mode], "CursorLineFoldLevel_" .. level, {
          bg = extend_to_linenr and (line_number_only and cursorline_default_bg or mode_color_blended) or "none",
          fg = color,
        })
      end
    end
  end

  -- Visual needs special treatment: Neovim does not use the namespace-specific
  -- hl group for the built-in Visual group.
  hl(
    ---@diagnostic disable-next-line: undefined-field
    M.ns_visual,
    "Visual",
    { bg = M.options.hl_blended.visual }
  )

  -- A plain normal-mode cursorline in the global namespace, for callers that
  -- just want a moody cursorline without mode switching.
  hl(0, "MoodyNormal", { bg = M.options.hl_blended.normal })
end

---@class Highlight
---@field fg? string: foreground colour, "#rrggbb"
---@field bg? string: background colour, "#rrggbb"

---@class Extend
---@field line_number boolean: extend the cursorline colour into the line-number column
---@field signs boolean: extend the cursorline colour into the sign column
---@field folds boolean: extend the cursorline colour into the fold column

---@class Disabled
---@field filetypes string[]: filetypes moody leaves alone (e.g. "TelescopePrompt")
---@field buftypes string[]: buftypes moody leaves alone (e.g. "nofile")

---@class Recording
---@field enabled boolean: show a macro-recording indicator at the end of the cursorline
---@field icon string: icon shown next to the recording register
---@field prefix string: text shown before the register character
---@field suffix string: text shown after the register character
---@field right_padding integer: cells of right padding (shifts the indicator left)

---@class ColumnSeparator
---@field char string: character drawn between the moody column and the code
---@field highlight Highlight: separator highlight; defaults to the CursorLine background

---@class ColumnFolds
---@field enabled boolean: render folds in the moody column
---@field start_color string: gradient start colour for fold levels, "#rrggbb"
---@field end_color string: gradient end colour for fold levels, "#rrggbb"

---@class ColumnMarks
---@field enabled boolean: render marks in the moody column
---@field alphabetic boolean: show alphabetic (a-z) marks
---@field other boolean: show non-alphabetic marks

---@class Column
---@field enabled boolean: replace the statuscolumn with moody's own
---@field numbers boolean: render line numbers
---@field signs boolean: render signs
---@field folds ColumnFolds: fold rendering + gradient
---@field marks ColumnMarks: mark rendering
---@field highlight Highlight: base highlight for the column (typically just a bg)
---@field separator ColumnSeparator: separator between the column and the code

---@class Config
---@field colors Colors: per-mode base colour (a `*Moody` highlight group overrides it)
---@field blends Blends|number: per-mode blend amount toward the background, or one number for all
---@field bold_line_number boolean: bold the cursor-line number
---@field line_number_only boolean: colour only the line number, leaving the default cursorline
---@field extend Extend: extend the cursorline colour into adjacent columns
---@field disabled Disabled: filetypes/buftypes to leave alone
---@field recording Recording: macro-recording indicator
---@field column Column: moody's own statuscolumn
M.options = {}

---@type Config
---@diagnostic disable-next-line: missing-fields
M.defaults = {
  ---@class Colors
  ---@field normal string
  ---@field insert string
  ---@field visual string
  ---@field command string
  ---@field operator string
  ---@field replace string
  ---@field select string
  ---@field terminal string
  ---@field terminal_n string
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
  ---@class Blends
  ---@field normal number
  ---@field insert number
  ---@field visual number
  ---@field command number
  ---@field operator number
  ---@field replace number
  ---@field select number
  ---@field terminal number
  ---@field terminal_n number
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
  bold_line_number = true,
  line_number_only = false,
  extend = {
    line_number = false,
    signs = false,
    folds = false,
  },
  disabled = {
    filetypes = {},
    buftypes = {
      "nofile",
      "prompt",
      "snacks_picker_input",
      "snacks_picker_preview",
      "snacks_picker_list",
    },
  },
  recording = {
    enabled = false,
    icon = "󰑋",
    prefix = "[",
    suffix = "]",
    right_padding = 2,
  },
  column = {
    enabled = false,
    numbers = true,
    signs = true,
    folds = {
      enabled = true,
      start_color = "#C1C1C1",
      end_color = "#2F2F2F",
    },
    marks = {
      enabled = true,
      alphabetic = true,
      other = false,
    },
    highlight = {},
    separator = {
      char = "",
      highlight = {},
    },
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

-- Map a mode (or sub-mode) string to the `M.ns_*` field holding its namespace.
-- Operator-pending has forced-motion variants (`no`, `nov`, `noV`, `no<C-v>`);
-- blockwise visual/select are the raw <C-v>/<C-s> bytes.
local mode_ns = {
  ["n"] = "ns_normal",
  ["i"] = "ns_insert",
  ["ix"] = "ns_insert",
  ["v"] = "ns_visual",
  ["V"] = "ns_visual",
  ["\22"] = "ns_visual", -- <C-v> blockwise visual
  ["c"] = "ns_command",
  ["r"] = "ns_replace",
  ["s"] = "ns_select",
  ["S"] = "ns_select",
  ["\19"] = "ns_select", -- <C-s> blockwise select
  ["t"] = "ns_terminal",
  ["tl"] = "ns_terminal_n",
  ["nt"] = "ns_terminal_n",
  ["no"] = "ns_operator",
  ["nov"] = "ns_operator",
  ["noV"] = "ns_operator",
  ["no\22"] = "ns_operator",
}

-- Remember the namespace last applied to each window so we can skip redundant
-- `nvim_win_set_hl_ns` calls (and the redraw they trigger). This also lets the
-- SafeState self-heal run cheaply on every idle without churning highlights.
M._applied_ns = M._applied_ns or {}

--- switches the hl-namespace depending on the mode.
--- Reads the mode from the ModeChanged event when given, otherwise from
--- `nvim_get_mode()` (used by the SafeState self-heal). Sets the window-local
--- namespace only when it actually changes.
---@param event? any
---@param win? integer: window number to trigger for
function M.trigger_mode(event, win)
  local mode
  if event and event.match ~= nil then
    mode = string.match(event.match, ".*:([^:]+)")
  else
    mode = vim.api.nvim_get_mode().mode
  end

  win = win or vim.api.nvim_get_current_win()

  -- Resolve to a concrete namespace id. Unknown modes reset the window to the
  -- global namespace (0) so a stale mode colour is never left behind.
  local ns_key = mode_ns[mode]
  ---@diagnostic disable-next-line: undefined-field
  local target = (ns_key and M[ns_key]) or 0

  if M._applied_ns[win] ~= target then
    vim.api.nvim_win_set_hl_ns(win, target)
    M._applied_ns[win] = target
  end
end

local function setup_statuscolumn()
  if M.options.column.enabled then
    vim.cmd("set statuscolumn=%!v:lua.require('moody.statuscolumn').myStatusColumn()")
  end
end

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
--- Validate user-supplied options before they are merged with the defaults.
--- Only keys the user actually set are checked, so partial configs pass. On the
--- first problem it stops and returns a human-readable message naming the key.
---@param options table? raw options passed to setup()
---@return boolean ok, string? err
function M.validate(options)
  if options == nil then
    return true
  end
  if type(options) ~= "table" then
    return false, ("expected options to be a table, got %s"):format(type(options))
  end

  local expected = {
    colors = "table",
    bold_line_number = "boolean",
    line_number_only = "boolean",
    extend = "table",
    disabled = "table",
    recording = "table",
    column = "table",
  }
  for key, kind in pairs(expected) do
    local value = options[key]
    if value ~= nil and type(value) ~= kind then
      return false, ("`%s` should be %s, got %s"):format(key, kind, type(value))
    end
  end

  -- colors must be "#rrggbb" hex strings
  if options.colors then
    for mode, color in pairs(options.colors) do
      if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
        return false, ('`colors.%s` should be a "#rrggbb" hex string'):format(tostring(mode))
      end
    end
  end

  -- blends is a single number or a table of per-mode numbers, each in [0, 1]
  local function is_blend(value)
    return type(value) == "number" and value >= 0 and value <= 1
  end
  if options.blends ~= nil then
    if type(options.blends) == "table" then
      for mode, amount in pairs(options.blends) do
        if not is_blend(amount) then
          return false, ("`blends.%s` should be a number between 0 and 1"):format(tostring(mode))
        end
      end
    elseif not is_blend(options.blends) then
      return false, "`blends` should be a number between 0 and 1, or a table of them"
    end
  end

  -- disabled.filetypes / disabled.buftypes must be lists
  if options.disabled then
    for _, key in ipairs({ "filetypes", "buftypes" }) do
      local value = options.disabled[key]
      if value ~= nil and type(value) ~= "table" then
        return false, ("`disabled.%s` should be a table"):format(key)
      end
    end
  end

  return true
end

function M.__setup(options)
  local ok, err = M.validate(options)
  if not ok then
    vim.notify("[moody] invalid config: " .. err, vim.log.levels.ERROR)
    return
  end

  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})

  -- Internal book-keeping (not user-facing): windows moody has been manually
  -- disabled for via M.reset(). Initialised here rather than in the defaults.
  M.options.disabled_list = {}

  local mode_group = vim.api.nvim_create_augroup("MoodyModeGroup", { clear = true })
  local rec_group = vim.api.nvim_create_augroup("MoodyRecordingGroup", { clear = true })

  -- load up the "colour caches" and setup highlights with it
  setup_ns_and_hlgroups()

  if M.options.column.enabled then
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

  -- Self-heal: some mode transitions never emit a ModeChanged we can catch
  -- (notably aborting operator-pending with <Esc>, which can leave the
  -- cursorline stuck on the operator colour). SafeState fires whenever Neovim
  -- finishes processing and is about to wait for input, so it is the ideal
  -- point to re-sync the window to its real mode. trigger_mode() is a no-op
  -- when the namespace is already correct, so this stays cheap.
  vim.api.nvim_create_autocmd("SafeState", {
    desc = "re-sync cursorline to the actual mode when Neovim goes idle",
    group = mode_group,
    callback = function()
      if M.is_disabled(vim.bo.buftype, vim.bo.filetype) then
        return
      end

      M.trigger_mode(nil)
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
