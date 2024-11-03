local ffi = require("ffidef")
local C = ffi.C
local error = ffi.new("Error")

local statuscolumn = {}

local moody_config = require("moody.config")
-- local utils = require("moody.utils")

-- options for extending cursorline to linenumbers and also using moody's statuscolumn
local extend_to_linenr = moody_config.options.extend_to_linenr
local show_folds = moody_config.options.fold_options.enabled
local extend_to_linenr_visual = moody_config.options.extend_to_linenr_visual
local extend_and_folds = extend_to_linenr and show_folds

function statuscolumn.char_on_pos(pos)
  pos = pos or vim.fn.getpos(".")
  return tostring(vim.fn.getline(pos[1])):sub(pos[2], pos[2])
end

-- borrowed from https://github.com/Wansmer/nvim-config/blob/main/lua/utils.lua#L83
-- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
function statuscolumn.char_byte_count(s, i)
  if not s or s == "" then
    return 1
  end

  local char = string.byte(s, i or 1)

  -- Get byte count of unicode character (RFC 3629)
  if char > 0 and char <= 127 then
    return 1
  elseif char >= 194 and char <= 223 then
    return 2
  elseif char >= 224 and char <= 239 then
    return 3
  elseif char >= 240 and char <= 244 then
    return 4
  end
end

function statuscolumn.get_visual_range()
  local sr, sc = unpack(vim.fn.getpos("v"), 2, 3)
  local er, ec = unpack(vim.fn.getpos("."), 2, 3)

  -- To correct work with non-single byte chars
  local byte_c = statuscolumn.char_byte_count(statuscolumn.char_on_pos({ er, ec }))
  ec = ec + (byte_c - 1)

  local range

  if sr == er then
    local cols = sc >= ec and { ec, sc } or { sc, ec }
    range = { sr, cols[1] - 1, er, cols[2] }
  elseif sr > er then
    range = { er, ec - 1, sr, sc }
  else
    range = { sr, sc - 1, er, ec }
  end

  return range
end

statuscolumn.number = function()
  local uncolored_text = "%#LineNr#"
  local colored_text = "%#CursorLineNr#"

  local mode = vim.fn.strtrans(vim.fn.mode()):lower():gsub("%W", "")

  ---@diagnostic disable-next-line: undefined-field
  local width = vim.opt.numberwidth:get()

  local l_count_width = #tostring(vim.api.nvim_buf_line_count(0))

  width = width >= l_count_width and width or l_count_width

  local function pad_start(n)
    local len = width - #tostring(n)
    return len < 1 and " " .. n or (" "):rep(len + 1) .. n
  end

  if mode == "v" and extend_to_linenr_visual then
    local v_range = statuscolumn.get_visual_range()
    local is_in_range = vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
    return is_in_range and colored_text .. pad_start(vim.v.lnum) or uncolored_text .. pad_start(vim.v.relnum)
  end

  return vim.v.relnum == 0 and colored_text .. pad_start(vim.v.lnum) or uncolored_text .. pad_start(vim.v.relnum)
end

statuscolumn.sign = function()
  local uncolored_text = "%#DiagnosticSign#"
  local colored_text = "%#MoodyDiagnosticSign#"
  return vim.v.relnum == 0 and colored_text .. "%s" or uncolored_text .. "%s"
end

-- local diagnostic_lookup = {
--   [1] = "Error",
--   [2] = "Warn",
--   [3] = "Info",
--   [4] = "Hint",
-- }
-- statuscolumn.get_diagnostic_for_line = function()
--   local diagnostic = vim.diagnostic.get(0, { lnum = vim.v.lnum - 1 })
--   local severity = diagnostic["severity"]
--   if severity then
--     utils.P("severity" .. diagnostic_lookup[severity])
--   end
--   -- utils.P(diagnostic.user_data and diagnostic.user_data.lsp.severity or "no diagnostics")
-- end

statuscolumn.myStatusColumn = function()
  local text = ""

  local win = vim.g.statusline_winid
  if vim.api.nvim_get_current_win() ~= win then
    return text
  end

  text = table.concat({
    "%s", -- symbols
    -- statuscolumn.sign(),
    "%=", -- right align
    statuscolumn.number(), -- numbers
    " ", -- extra padding before..
    show_folds and statuscolumn.folds() or "", -- maybe folds, and after that your code! (.. maybe)
  })

  return text
end

statuscolumn.folds = function()
  local win = vim.g.statusline_winid
  local wp = C.find_window_by_handle(win, error)
  local opts = { win = win }
  local culopt = vim.api.nvim_get_option_value("culopt", opts)

  local args = {
    wp = wp,
    relnum = vim.v.relnum,
    virtnum = vim.v.virtnum,
    lnum = vim.v.lnum,
    cul = vim.api.nvim_get_option_value("cul", opts) and (culopt:find("nu") or culopt:find("bo")),
    fold = {
      width = C.compute_foldcolumn(wp, 0),
      open = "╭",
      close = "╶",
      sep = "│",
      eofold = "╰",
    },
  }

  local width = args.fold.width
  local is_curline = args.cul and args.relnum == 0

  -- if no width for foldcolumn, theres nothing to show
  if width == 0 then
    return ""
  end

  local foldinfo = C.fold_info(args.wp, args.lnum)
  local after_foldinfo = C.fold_info(args.wp, args.lnum + 1)

  local level = foldinfo.level

  local mode = vim.fn.strtrans(vim.fn.mode()):lower():gsub("%W", "")

  local is_visual_and_range = false
  if mode == "v" then
    local v_range = statuscolumn.get_visual_range()
    is_visual_and_range = vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
  end

  local string = is_curline and "%#CursorLineFoldLevel_" .. level .. "#"
    or (is_visual_and_range and extend_and_folds and "%#FoldLevelVisual_" .. level .. "#")
    or ("%#FoldLevel_" .. level .. "#")
    or "%#FoldColumn#"
  local after_level = after_foldinfo.level

  if level == 0 then
    return string .. (is_visual_and_range and extend_and_folds and "%#Visual" .. "# " or " "):rep(width) .. "%*"
  end

  local foldclosed = foldinfo.lines > 0
  local first_level = level - width - (foldclosed and 1 or 0) + 1
  if first_level < 1 then
    first_level = 1
  end

  local after_foldclosed = after_foldinfo.lines > 0
  local after_first_level = after_level - width - (after_foldclosed and 1 or 0) + 1
  if after_first_level < 1 then
    after_first_level = 1
  end

  local should_be_sep = after_level > level
  local range = level < width and level or width
  for col = 1, range do
    local is_after_open = after_foldinfo.start == args.lnum + 1 and after_first_level + col > after_foldinfo.llevel
    if args.virtnum ~= 0 then
      string = string .. args.fold.sep
    elseif foldclosed and (col == level or col == width) then
      string = string .. args.fold.close
    elseif foldinfo.start == args.lnum and first_level + col > foldinfo.llevel then
      string = string .. args.fold.open
    elseif (level > after_level or is_after_open or after_foldclosed) and not should_be_sep then
      string = string .. args.fold.eofold
    else
      string = string .. args.fold.sep
    end
  end
  if range < width then
    string = string .. (" "):rep(width - range)
  end

  return string .. "%*"
end

return statuscolumn
