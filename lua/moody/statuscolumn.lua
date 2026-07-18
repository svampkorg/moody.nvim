local ffi = require("ffidef")
local C = ffi.C
local error = ffi.new("Error")

-- local statuscolumn = {}

local M = {}

--- Live view of the moody config. Read through this rather than caching a
--- reference at module load: __setup() reassigns options on every setup() call,
--- so a captured table would go stale on re-configuration.
local function options()
  return require("moody.config").options
end

---@return boolean: to disable or not to disable. That is the question.
local function is_disabled(...)
  return require("moody.config").is_disabled(...)
end

M.global_markslist = {}
M.local_markslist = {}
M.markslist = {}
M.marks_timestamp = 0

local function is_real_line()
  return vim.v.virtnum == 0
end

local function is_in_cursorline()
  return vim.v.relnum == 0 and vim.v.virtnum == 0
end

local function char_on_pos(pos)
  pos = pos or vim.fn.getpos(".")
  ---@diagnostic disable-next-line: undefined-global, undefined-field
  return tostring(vim.fn.getline(pos[1])):sub(pos[2], pos[2])
end

local function pad_start(n)
  ---@diagnostic disable-next-line: undefined-field
  local width = vim.opt.numberwidth:get()

  local l_count_width = #tostring(vim.api.nvim_buf_line_count(0))

  width = width >= l_count_width and width or l_count_width
  local len = width - #tostring(n)

  local d = is_real_line() and n or ""
  return (len < 1 and " " .. d) or (" "):rep(len + 1) .. d
end

-- borrowed from https://github.com/Wansmer/nvim-config/blob/main/lua/utils.lua#L83
-- From: https://neovim.discourse.group/t/how-do-you-work-with-return_strings-with-multibyte-characters-in-lua/2437/4
local function char_byte_count(s, i)
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

local function get_visual_range()
  local sr, sc = unpack(vim.fn.getpos("v"), 2, 3)
  local er, ec = unpack(vim.fn.getpos("."), 2, 3)

  -- To correct work with non-single byte chars
  local byte_c = char_byte_count(char_on_pos({ er, ec }))
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

---@diagnostic disable-next-line: unused-local
local function visual_connects()
  local v_range = get_visual_range()
  return 1 == v_range[4] and not is_in_cursorline()
end

local function is_visual_mode()
  local mode = vim.api.nvim_get_mode().mode

  if mode == "v" or mode == "V" then
    return true
  end
  return false
end

local function is_in_visual_range()
  if vim.v.virtnum ~= 0 then
    return false
  end

  if is_visual_mode() then
    local v_range = get_visual_range()
    return vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
  end
  return false
end

-- The separator always renders uncoloured for now.
-- TODO: colour it with the mode (MoodySeparatorMode) when the cursor or a
-- visual selection is on the line, i.e. is_in_cursorline() or is_in_visual_range().
local function separator()
  local sep_char = options().moody_column.separator.char
  return "%#MoodySeparator#" .. sep_char .. "%*"
end

local function numbers()
  return (
    (is_in_cursorline() or is_in_visual_range()) and "%#CursorLineNr#" .. pad_start(vim.v.lnum)
    or "%#LineNr#" .. pad_start(vim.v.relnum)
  )
end

local function sign()
  if not is_real_line() then
    return "%#SignColumn#"
  end

  -- if is_visual_mode() and is_in_cursorline() then
  --   return "%#MoodySignColumnMode#"
  -- elseif is_in_cursorline() then
  --   return "%#MoodySignColumnMode#%s"
  -- elseif is_in_visual_range() then
  --   return "%#SignColumn#"
  -- else
  --   return "%#SignColumn#%s"
  -- end

  -- return "%#SignColumn#%s"
  return (is_in_cursorline() or is_in_visual_range()) and "%#MoodySignColumnMode#%s" or "%#SignColumn#%s"

  -- return (is_in_cursorline() or is_in_visual_range()) and "%#MoodySignColumnMode#%s" or "%#MoodySignColumn#%s"
end

-- ---@diagnostic disable-next-line: unused-function
-- local function get_marks()
--   local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
--   local signs = {}
--   -- Add marks
--   local marks = vim.fn.getmarklist(buf)
--   vim.list_extend(marks, vim.fn.getmarklist())
--   for _, mark in ipairs(marks) do
--     if mark.pos[1] == buf and mark.mark:match("[a-zA-Z]") then
--       local lnum = mark.pos[2]
--       signs[lnum] = signs[lnum] or {}
--       table.insert(signs[lnum], { text = mark.mark:sub(2), texthl = "SnacksStatusColumnMark", type = "mark" })
--     end
--   end
--   return signs
-- end

-- Throttles mark updates
local function update_marks_list()
  local current_timestamp = vim.fn.localtime()
  if current_timestamp - 1 < M.marks_timestamp then
    return
  end
  M.local_markslist = vim.fn.getmarklist(vim.api.nvim_win_get_buf(vim.g.statusline_winid))
  -- M.global_markslist = vim.fn.getmarklist()
  M.marks_timestamp = current_timestamp
end

local function marks()
  if not is_real_line() then
    return "%#SignColumn#"
  end
  local mc = options().moody_column
  if not mc.alphabetic_marks and not mc.other_marks then
    return ""
  end
  update_marks_list()

  local marks_table = {
    alphabetic = {},
    other = {},
  }

  local added_othermark = false

  for _, mark in ipairs(M.local_markslist) do
    if mc.alphabetic_marks and mark.pos[2] == vim.v.lnum and mark.mark:match("[a-zA-Z]") then
      table.insert(marks_table.alphabetic, string.sub(mark.mark, 2, 2))
    elseif mc.other_marks and mark.pos[2] == vim.v.lnum and not added_othermark then
      table.insert(marks_table.other, string.sub(mark.mark, 2, 2))
    end
  end

  local alphabetic_marks_return_string =
    table.concat(marks_table.alphabetic, nil, nil, math.min(3, #marks_table.alphabetic))
  local other_marks_return_string = table.concat(marks_table.other, nil, nil, math.min(3, #marks_table.other))

  local return_table = {}

  table.insert(
    return_table,
    (is_in_cursorline() or is_in_visual_range()) and "%#MoodyAlphabeticMarkMode#" .. alphabetic_marks_return_string
      or "%#MoodyAlphabeticMark#" .. alphabetic_marks_return_string
  )
  table.insert(
    return_table,
    (is_in_cursorline() or is_in_visual_range()) and "%#MoodyOtherMarkMode#" .. other_marks_return_string
      or "%#MoodyOtherMark#" .. other_marks_return_string
  )

  return table.concat(return_table)
end

---@diagnostic disable-next-line: unused-local
local function folds()
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
    return "%*"
  end

  local foldinfo = C.fold_info(args.wp, args.lnum)
  local after_foldinfo = C.fold_info(args.wp, args.lnum + 1)

  local level = foldinfo.level

  local is_visual_and_range = is_in_visual_range()

  local fold_hl_string = is_curline and "%#CursorLineFoldLevel_" .. level .. "#"
    or is_visual_and_range and "%#FoldLevelVisual_" .. level .. "#"
    or ("%#FoldLevel_" .. level .. "#")
    or "%#FoldColumn#"

  if level == 0 then
    return fold_hl_string .. (is_visual_and_range and "%#Visual# " or " "):rep(width) .. "%*"
  end

  local after_level = after_foldinfo.level

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
      fold_hl_string = fold_hl_string .. args.fold.sep
    elseif foldclosed and (col == level or col == width) then
      fold_hl_string = fold_hl_string .. args.fold.close
    elseif foldinfo.start == args.lnum and first_level + col > foldinfo.llevel then
      fold_hl_string = fold_hl_string .. args.fold.open
    elseif (level > after_level or is_after_open or after_foldclosed) and not should_be_sep then
      fold_hl_string = fold_hl_string .. args.fold.eofold
    else
      fold_hl_string = fold_hl_string .. args.fold.sep
    end
  end
  if range < width then
    fold_hl_string = fold_hl_string .. (" "):rep(width - range)
  end

  return fold_hl_string
end

function M.myStatusColumn()
  local text = ""

  if is_disabled(vim.bo.buftype, vim.bo.filetype) or (vim.bo.buftype == "terminal") then
    return text
  end

  if vim.api.nvim_get_current_win() ~= vim.g.statusline_winid then
    return text
  end

  local co = options().moody_column.column_options
  text = table.concat({
    co.signs and sign() or "",
    co.marks and marks() or "",
    "%=", -- right align
    co.numbers and numbers() or "", -- numbers
    separator() or "",
    -- co.folds and folds() or "",
  })

  return text
end

return M
