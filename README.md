<h1 align="center">✨ moody ✨</h1>

Don't look down! 🚠

- [Why?](#-Why?)
- [Video](#-Video)
- [Install](#-Install)
- [Setup](#-Setup)
- [Acknowledgments](#-Acknowledgments)
- [Similar plugins](#-Similar)
- [Known issues](#-Issues)

## ❓Why?

If you look down, you might miss out on some code getting inserted by your quick caffeine induced coding fingers!
I would be a real shame if that happens when you are not in the mode for it. 🤦

I made this plugin so I could see which mode Neovim is in just by the color of CursorLine and CursorLineNr.

## 🎥 Video

#### Different modes, different CursorLine colours
<https://github.com/svampkorg/moody.nvim/assets/99117038/792b37a0-dfc7-46cb-8e9a-146ed360a265>

#### Recording macro indicator in CursorLine
<https://github.com/user-attachments/assets/ebec6153-5aee-48af-a1dc-c53ca225503e>


## 💾 Install

- Install with Lazy like this
```lua
{
    "svampkorg/moody.nvim",
    event = { "ModeChanged", "BufWinEnter", "WinEnter" },
    dependencies = {
        -- or whatever "colorscheme" you use to setup your HL groups :)
        -- Colours can also be set within setup, in which case this is redundant.
        "catppuccin/nvim",
        -- for seeing Moody's take on folds
        "kevinhwang91/nvim-ufo"
    },
    opts = {
        -- you can set different blend values for your different modes.
        -- Some colours might look better more dark, so set a higher value
        -- will result in a darker shade.
        blends = {
            normal = 0.2,
            insert = 0.2,
            visual = 0.25,
            command = 0.2,
            operator = 0.2,
            replace = 0.2,
            select = 0.2,
            terminal = 0.2,
            terminal_n = 0.2,
        },
        -- there are two ways to define colours for the different modes.
        -- one way is to define theme here in colors. Another way is to
        -- set them up with highlight groups. Any highlight group set takes
        -- precedence over any colours defined here.
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
        -- disable filetypes here. Add for example "TelescopePrompt" to
        -- not have any coloured cursorline for the telescope prompt.
        disabled_filetypes = { "TelescopePrompt" },
        -- disabled buftypes here
        disabled_buftypes = { },
        -- you can turn on or off bold characters for the line numbers
        bold_nr = true,
        -- you can turn on and off a feature which shows a little icon and
        -- registry number at the end of the CursorLine, for when you are
        -- recording a macro! Default is false.
        recording = {
            enabled = false,
            icon = "󰑋",
            -- you can set some text to surround the recording registry char with
            -- or just set one to empty to maybe have just one letter, an arrow
            -- perhaps! For example recording to q, you could have! "󰑋    q" :D
            pre_registry_text = "[",
            post_registry_text = "]",
            -- if you have some other plugin showing up on the right you can pad
            -- the recording indicator on the right side, to shift it to the left.
            -- For example if you use Satellite you have to shift recording to the left.
            -- using right padding.
            right_padding = 2,
        },
        -- Set *default_cursorline* to true if you want to have just the linenr highlighted with normal CursorLine
		default_cursorline = false,
        -- Set *extend_to_linenr* to true to extend the CursorLine into line numbers
		extend_to_linenr = true,
        -- Set *extend_to_signs* to true to extend the CursorLine into signs
		extend_to_signs = true,
        -- Set *extend_to_folds* to true to extend the CursorLine into folds
		extend_to_folds = true,
        -- Moody has it's own statuscolumn implementatin. With it, you can have a different
        -- way of visualising folds. There's also the addition of a better view of visually
        -- selected lines.
		moody_column = {
            -- Set to true to enable Moody column
			enabled = false,
            -- these are two colors you can specifiy which will be used to generate a gradient
            -- with one step for each fold level, specified by vim.o.foldnestmax
			folds_start_color = tokyonight_moon.fg,
			folds_end_color = tokyonight_moon.bg_highlight,
            separator = {
            -- Additionally you can provide a separator char between moody column and
            -- your editor area. Personally I just go with a space here, to create some distance
            -- between the line numbers and the folds.
            char = "▕",
            -- The default color of the separator will be whatever your theme normally
            -- use for the CursorColumn. Or you can set your own color here.
            color = "#2F334D",
            },
		},
    },
  }
```

## 💺 Setup

- Define your HL groups within your colorscheme. For example like this, in catppuccin highlight_overrides
- Or set the colours in opts passed to setup
```lua
{
    NormalMoody = { fg = C.blue },
    InsertMoody = { fg = C.green },
    VisualMoody = { fg = C.pink },
    CommandMoody = { fg = C.maroon },
    OperatorMoody = { fg = C.maroon },
    ReplaceMoody = { fg = C.red },
    SelectMoody = { fg = C.pink },
    TerminalMoody = { fg = C.mauve },
    TerminalNormalMoody = { fg = C.mauve },
}
```

- Theres not a lot of values to set, but these are the defaults:
```lua
{
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
    -- will be overruled if HL groups are set
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
    disabled_filetypes = {},
    disabled_buftypes = {},
    bold_nr = true,
    extend_to_linenr = true,
    extend_to_linenr_visual = false,
    fold_options = {
        enabled = false,
        start_color = "#C1C1C1",
        end_color = "#2F2F2F",
    },
    recording = {
        enabled = false,
        icon = "󰑋",
        pre_registry_text = "[",
        post_registry_text = "]",
        right_padding = 2,
    },
}
```
## 🧾 API

### Trigger Moody manually
- You can trigger Moody for a certain window with
```lua
---@param win integer: The window to trigger Moody for
require("moody").trigger(win)
```
- This will enable Moody for the provided window.
    If the window id `integer` is part of a list of disabled windows, it will be removed from there. More on that below.

### Disable Moody manually
- Apart from providing *filetype* and/or *buftype* to disable Moody for, you can also manually disable Moody for specific windows
```lua
---@param win integer: The window to disable Moody for
require("moody").reset(win)
```
- This will effectively disable Moody by adding the window id `integer` into a list of disabled windows.
    If an invalid value is provided, Moody will only briefly get disabled until another ModeChanged is detected. If no value is provided, current window will be used.

## 🤯 Issues

- There are no known issues at the moment.

## 🤔 Todo

- ✅ Make moody ignore certain buffers, or filetypes.

## ⭐ Acknowledgments

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure*
- [S1M0N38/my-awesome-plugin.nvim](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure* I used this to generate the structure of this plugin. Thanks S1M0N38! ❤️
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - *Tests, lint, docs generation*
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) - *Colour calculations* Borrowed some colour calculation methods from here ❤️
- [Wansmer/nvim-config](https://github.com/Wansmer/nvim-config) - *Line numbers & visual selection* Borrowed some code from this guys neovim config (/lua/modules/status/components) ❤️

## 🫶 Similar

- Plugins that do the same thing!
- [modes](https://github.com/mvllow/modes.nvim)
- [line-number-change-mode](https://github.com/sethen/line-number-change-mode.nvim)
- [modicator](https://github.com/mawkler/modicator.nvim)
