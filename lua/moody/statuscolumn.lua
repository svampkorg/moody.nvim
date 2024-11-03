local ffi = require("ffidef")
local C = ffi.C
local error = ffi.new("Error")

local statuscolumn = {}

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

  local range = {}

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

-- local user_config = {
--   -- modes = require("config").modes,
--   -- modes = {
--   --   "normal",
--   --   "insert",
--   --   "visual",
--   --   "command",
--   --   "operator",
--   --   "replace",
--   --   "select",
--   --   "terminal",
--   --   "terminal_n",
--   -- },
--   -- colors = require("moody.config").fold_colors,
--
--   -- colors = {
--   --   "#33a8c7",
--   --   "#ffadad",
--   --   "#52e3e1",
--   --   "#a0e426",
--   --   "#ffd6a5",
--   --   "#fdf148",
--   --   "#caffbf",
--   --   "#ffab00",
--   --   "#9bf6ff",
--   --   "#f77976",
--   --   "#bdb2ff",
--   --   "#f050ae",
--   --   "#d883ff",
--   --   "#fdffb6",
--   --   "#9336fd",
--   --   "#ffc6ff",
--   --   "#a0c4ff",
--   -- },
-- }

statuscolumn.number = function()
  local uncolored_text = "%#LineNr#"
  local colored_text = "%#CursorLineNr#"

  local mode = vim.fn.strtrans(vim.fn.mode()):lower():gsub("%W", "")

  local width = #tostring(vim.api.nvim_buf_line_count(0))

  -- local nu = vim.opt.number:get()
  -- local rnu = vim.opt.relativenumber:get()
  -- local cur_line = vim.fn.line(".") == vim.v.lnum and vim.v.lnum or vim.v.relnum

  -- Repeats the behavior for `vim.opt.numberwidth`
  -- local width = vim.opt.numberwidth:get()
  local l_count_width = #tostring(vim.api.nvim_buf_line_count(0))
  -- If buffer have more lines than `vim.opt.numberwidth` then use width of line count
  width = width >= l_count_width and width or l_count_width

  local function pad_start(n)
    local len = width - #tostring(n)
    return len < 1 and " " .. n or (" "):rep(len + 1) .. n
  end

  -- local function pad_start(n)
  --   local len = width - #tostring(n)
  --   return len < 1 and " " or (" "):rep(len)
  -- end

  -- if mode == "v" then
  --   local v_range = statuscolumn.get_visual_range()
  --   local is_in_range = vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
  --   return is_in_range and colored_text .. pad_start(width) .. vim.v.lnum
  --     or uncolored_text .. pad_start(width) .. vim.v.relnum
  -- end

  if mode == "v" then
    local v_range = statuscolumn.get_visual_range()
    local is_in_range = vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
    return is_in_range and colored_text .. pad_start(vim.v.lnum) or uncolored_text .. pad_start(vim.v.relnum)
  end

  -- if nu and rnu then
  --   return v_hl .. pad_start(cur_line)
  -- elseif nu then
  --   return v_hl .. pad_start(vim.v.lnum)
  -- elseif rnu then
  --   return v_hl .. pad_start(vim.v.relnum)
  -- end

  return vim.v.relnum == 0 and colored_text .. pad_start(vim.v.lnum) or uncolored_text .. pad_start(vim.v.relnum)
  -- return vim.v.relnum == 0 and colored_text .. " " .. vim.v.lnum or uncolored_text .. " " .. vim.v.relnum
end

statuscolumn.sign = function()
  local uncolored_text = "%#CursorLine#"
  local colored_text = "%#CursorLineSign#"
  return vim.v.relnum == 0 and colored_text .. "%s" or uncolored_text .. "%s"
end

statuscolumn.myStatusColumn = function()
  --statuscolumn.generate_colors()
  local text = ""

  local win = vim.g.statusline_winid
  if vim.api.nvim_get_current_win() ~= win then
    return text
  end

  text = table.concat({
    "%s",
    -- " ",
    "%=",
    statuscolumn.number(),
    " ",
    statuscolumn.folds(),
  })

  return text
end

local moody_config = require("moody.config")

-- options for extending cursorline to linenumbers and also using moody's statuscolumn
local extend_and_folds = moody_config.options.enable_statuscolumn and moody_config.options.extend_cursorline

-- local function pad_start(n, width)
--   local len = width - #tostring(n)
--   return len < 1 and n or (" "):rep(len) .. n
-- end

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

  -- if level == 0 and is_visual_and_range and extend_and_folds then
  --   return string .. ("%#FoldLevelVisual_" .. " #"):rep(width) .. "%*"
  -- elseif level == 0 then
  --   return string .. (" "):rep(width) .. "%*"
  -- end

  -- if level == 0 then
  --   return string .. (" "):rep(width) .. "%*"
  -- end

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
