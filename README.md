<h1 align="center">✨ moody ✨</h1>

Don't look down! 🚠

- [Why?](#-Why?)
- [Video](#-Video)
- [Install](#-Install)
- [Setup](#-Setup)
- [Acknowledgments](#-Acknowledgments)
- [Similar plugins](#-Similar)

## ❓Why?

If you look down, you might miss out on some code getting inserted by your quick caffeine induced coding fingers!
I would be a real shame if that happens when you are not in the mode for it. 🤦

I made this plugin so I could see which mode Neovim is in just by the color of CursorLine and CursorLineNr.

## 🎥 Video

<https://github.com/svampkorg/moody.nvim/assets/99117038/792b37a0-dfc7-46cb-8e9a-146ed360a265>

## 💾 Install

- Install with Lazy like this
```lua
{
    "svampkorg/moody.nvim",
    event = { "ModeChanged" },
    dependencies = {
        -- or wherever you setup your HL groups :)
        "catppuccin/nvim",
    },
    opts = {
        -- you can set different blend values for your different modes.
        -- Some colours might look better more dark.
        blend = {
            normal = 0.2,
            insert = 0.2,
            visual = 0.3,
            command = 0.2,
            replace = 0.2,
            select = 0.3,
            terminal = 0.2,
            terminal_n = 0.2,
        },
    },
  }
```

## 💺 Setup

- Define your HL groups within your colorscheme. For example like this, in catppuccin highlight_overrides
```lua
{
    NormalMoody = { fg = C.blue },
    InsertMoody = { fg = C.green },
    VisualMoody = { fg = C.pink },
    CommandMoody = { fg = C.maroon },
    ReplaceMoody = { fg = C.red },
    SelectMoody = { fg = C.pink },
    TerminalMoody = { fg = C.mauve },
    TerminalNormalMoody = { fg = C.mauve },
}
```

- Theres not a lot of values to set, but these are the defaults:
```lua
{
  blend = {
    normal = 0.2,
    insert = 0.2,
    visual = 0.2,
    command = 0.2,
    replace = 0.2,
    select = 0.2,
    terminal = 0.2,
    terminal_n = 0.2,
  },
  disabled_buffers = {},
  bold_nr = true,
}
```

## 🤔 Todo

- Make moody ignore certain buffers, or filetypes. (It already ignores nvim.dapui files)

## ⭐ Acknowledgments

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure*
- [S1M0N38/my-awesome-plugin.nvim](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure* I used this to generate the structure of this plugin. Thanks S1M0N38! ❤️
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - *Tests, lint, docs generation*
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) - *Colour calculations* Borrowed some colour calculation methods from here ❤️

## 🫶 Similar

- Plugins that do the same thing!
- [modes](https://github.com/mvllow/modes.nvim)
