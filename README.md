<h1 align="center">✨ moody ✨</h1>

<p align="center">Colour your Neovim cursorline (and an optional status column) by the current mode.</p>

Moody recolours `CursorLine` and `CursorLineNr` as you switch modes, so a glance
tells you whether you're in normal, insert, visual, … — no looking down at the
statusline. Optionally it can extend the colour into the number/sign/fold columns,
draw its own status column (folds, marks, signs), and show a macro-recording
indicator on the cursorline.

- [Why?](#-why)
- [Video](#-video)
- [Requirements](#-requirements)
- [Install](#-install)
- [Configuration](#-configuration)
- [Colours: two ways](#-colours-two-ways)
- [The moody column](#-the-moody-column)
- [Recording indicator](#-recording-indicator)
- [Highlight groups](#-highlight-groups)
- [API](#-api)
- [Health](#-health)
- [Acknowledgments](#-acknowledgments)
- [Similar plugins](#-similar-plugins)

## ❓ Why?

If you look down at the statusline to check your mode, you might miss a stray
insert from your caffeine-fuelled fingers. Moody puts the mode where your eyes
already are — on the current line.

## 🎥 Video

#### Different modes, different CursorLine colours
<https://github.com/svampkorg/moody.nvim/assets/99117038/792b37a0-dfc7-46cb-8e9a-146ed360a265>

#### Recording-macro indicator in the CursorLine
<https://github.com/user-attachments/assets/ebec6153-5aee-48af-a1dc-c53ca225503e>

## 📋 Requirements

- Neovim **0.9+** (uses per-window highlight namespaces).
- Optional: [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo) for moody's take
  on folds in the status column.
- A colorscheme is **not** required — set colours in `opts.colors` (below). If you
  do use one, moody can pick up `*Moody` highlight groups it defines.

Run `:checkhealth moody` after installing to verify your setup.

## 💾 Install

With [lazy.nvim](https://github.com/folke/lazy.nvim) — minimal:

```lua
{ "svampkorg/moody.nvim", opts = {} }
```

Moody works out of the box; `opts` only overrides defaults. A fuller example:

```lua
{
  "svampkorg/moody.nvim",
  event = { "ModeChanged", "BufWinEnter", "WinEnter" },
  opts = {
    -- one blend for every mode, or a per-mode table (see Configuration)
    blends = 0.2,
    colors = {
      normal = "#00BFFF",
      insert = "#70CF67",
      visual = "#AD6FF7",
    },
    disabled = {
      filetypes = { "TelescopePrompt" },
    },
    extend = {
      line_number = true, -- colour the line-number column too
    },
    recording = { enabled = true },
  },
}
```

## ⚙️ Configuration

These are **all** the options, with their defaults:

```lua
{
  -- Base colour per mode. Overridden by a matching `*Moody` highlight group if
  -- your colorscheme defines one (see "Colours: two ways").
  colors = {
    normal     = "#00BFFF",
    insert     = "#70CF67",
    visual     = "#AD6FF7",
    command    = "#EB788B",
    operator   = "#FF8F40",
    replace    = "#E66767",
    select     = "#AD6FF7",
    terminal   = "#4CD4BD",
    terminal_n = "#00BBCC",
  },

  -- How far to blend each mode colour toward the editor background for the
  -- cursorline. Higher = more subtle. Either a single number applied to every
  -- mode, or a per-mode table like `colors` above.
  blends = 0.2,

  -- Bold the number on the cursor line.
  bold_line_number = true,

  -- Colour only the line number, leaving Neovim's default cursorline untouched.
  line_number_only = false,

  -- Extend the mode colour out of the cursorline into adjacent columns.
  extend = {
    line_number = false, -- the number column
    signs       = false, -- the sign column
    folds       = false, -- the fold column
  },

  -- Filetypes / buftypes moody leaves completely alone.
  disabled = {
    filetypes = {},
    buftypes  = {
      "nofile",
      "prompt",
      "snacks_picker_input",
      "snacks_picker_preview",
      "snacks_picker_list",
    },
  },

  -- Macro-recording indicator drawn at the end of the cursorline.
  recording = {
    enabled      = false,
    icon         = "󰑋",
    prefix       = "[",  -- text before the register char
    suffix       = "]",  -- text after the register char
    right_padding = 2,   -- cells of right padding (shifts it left)
  },

  -- Moody's own status column: a different take on folds, plus marks/signs.
  column = {
    enabled = false,     -- replace 'statuscolumn' with moody's
    numbers = true,      -- show line numbers
    signs   = true,      -- show the sign column
    folds = {
      enabled     = true,
      start_color = "#C1C1C1", -- gradient start across fold levels
      end_color   = "#2F2F2F", -- gradient end
    },
    marks = {
      enabled    = true,
      alphabetic = true,  -- a-z / A-Z marks
      other      = false, -- non-alphabetic marks
    },
    highlight = {},       -- base highlight for the column, e.g. { bg = "#101010" }
    separator = {
      char      = "",     -- drawn between the column and the code
      highlight = {},     -- e.g. { fg = "#333333" }; defaults to CursorLine bg
    },
  },
}
```

Bad values are reported with a clear message via `vim.notify` instead of failing
somewhere deep later — e.g. `` `colors.normal` should be a "#rrggbb" hex string ``.

## 🎨 Colours: two ways

You can set the per-mode colours in **either** place; a highlight group wins over
`opts.colors`:

1. **`opts.colors`** — as shown above.
2. **`*Moody` highlight groups** — define these in your colorscheme (here in
   catppuccin's `highlight_overrides`):

```lua
{
  NormalMoody         = { fg = C.blue },
  InsertMoody         = { fg = C.green },
  VisualMoody         = { fg = C.pink },
  CommandMoody        = { fg = C.maroon },
  OperatorMoody       = { fg = C.maroon },
  ReplaceMoody        = { fg = C.red },
  SelectMoody         = { fg = C.pink },
  TerminalMoody       = { fg = C.mauve },
  TerminalNormalMoody = { fg = C.mauve },
}
```

Moody reads each group's **foreground** as that mode's colour. Anything you don't
define falls back to `opts.colors`.

## 🪟 The moody column

Set `column.enabled = true` to replace Neovim's `'statuscolumn'` with moody's,
which renders (each toggleable): line numbers, the sign column, marks
(alphabetic and/or other), and a fold column with a colour gradient across fold
levels. A `separator` character can sit between the column and your code.

## ⏺ Recording indicator

With `recording.enabled = true`, recording a macro (e.g. `qq`) shows the `icon`
and the register at the end of the cursorline, wrapped in `prefix`/`suffix`.
For example `prefix = "󰑋 "`, `suffix = ""` recording to `q` reads `󰑋 q`. Use
`right_padding` to shift it left when another plugin occupies the right edge.

## 🖍 Highlight groups

Besides recolouring `CursorLine`/`CursorLineNr`, moody exposes groups you can use
elsewhere — handy for a statusline mode indicator that matches the cursorline:

- `StatusLineMoody` / `StatusLineMoodyInverted`
- `MoodyNormal` — a plain moody cursorline background in the global namespace

These live in the per-mode namespaces, so they track the active mode.

## 🧩 API

### Trigger moody for a window

```lua
---@param win integer: window handle
require("moody").trigger(win)
```

Enables moody for `win`, removing it from the manually-disabled list if present.

### Disable moody for a window

```lua
---@param win integer: window handle
require("moody").disable(win)
```

Adds `win` to the manually-disabled list. With no/invalid argument the current
window is used, and it re-enables on the next `ModeChanged`.

## 🩺 Health

```vim
:checkhealth moody
```

Reports your Neovim version, whether `setup()` ran, whether the config is valid,
whether `Normal` has a background to blend against, and your disabled lists.

## ⭐ Acknowledgments

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) — plugin structure.
- [S1M0N38/my-awesome-plugin.nvim](https://github.com/S1M0N38/my-awesome-plugin.nvim) — plugin structure. Thanks S1M0N38! ❤️
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) — tests, lint, docs generation.
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) — colour blend maths. ❤️
- [Wansmer/nvim-config](https://github.com/Wansmer/nvim-config) — line numbers & visual selection in the status column. ❤️

## 🫶 Similar plugins

- [modes.nvim](https://github.com/mvllow/modes.nvim)
- [line-number-change-mode.nvim](https://github.com/sethen/line-number-change-mode.nvim)
- [modicator.nvim](https://github.com/mawkler/modicator.nvim)
