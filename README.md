<h1 align="center">✨ moody ✨</h1>

<p align="center">
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/actions/workflows/test.yml">
    <img alt="Tests" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/my-awesome-plugin.nvim/test.yml?style=for-the-badge&label=Tests"/>
  </a>
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/actions/workflows/docs.yml">
    <img alt="Docs" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/my-awesome-plugin.nvim/docs.yml?style=for-the-badge&label=Docs"/>
  </a>
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/releases">
    <img alt="Release" src="https://img.shields.io/github/v/release/S1M0N38/my-awesome-plugin.nvim?style=for-the-badge"/>
  </a>
</p>

______________________________________________________________________

Don't look down! 🚠

- [Why?](#-Why?)
- [Install](#-Install)
- [Setup](#-Setup)
- [Acknowledgments](#-Acknowledgments)

## ❓Why?

If you look down, you might miss out on some code getting inserted by your quick caffeine induced coding fingers!
I'd be a real shame if that happend when you are in the wrong mode 🤦

I made this plugin so I could see which mode Neovim is in just by the color of CursorColumn.

## 💾 Install

- Install with Lazy like this
```lua
{
    "svampkorg/moody.nvim",
    event = { "VimEnter", "ModeChanged" },
    dependencies = {
        -- or wherever you setup your HL groups :)
        "catppuccin/nvim",
    },
    opts = {
        -- you can set different blend modes for your different modes. Some colours might look better more dark.
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

## 🫣 Setup

- Define your HL groups within your colorscheme. For example like this, for catppuccin
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

## ⭐ Acknowledgments

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure*
- [S1M0N38/my-awesome-plugin.nvim](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure* I used this to generate the structure of this plugin. Thanks S1M0N38! ❤️
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - *Tests, lint, docs generation*
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) - *Colour calculations* Borrowed some color calculation methods from here ❤️
