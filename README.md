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

<https://github.com/svampkorg/moody.nvim/assets/99117038/792b37a0-dfc7-46cb-8e9a-146ed360a265>

## 💾 Install

- Install with Lazy like this
```lua
{
    "svampkorg/moody.nvim",
    event = { "ModeChanged", "BufWinEnter", "WinEnter" },
    dependencies = {
        -- or wherever you setup your HL groups :)
        "catppuccin/nvim",
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
        -- precedence over any colors defined here.
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
        disabled_filetypes = {},
        -- you can turn on or off bold characters for the line numbers
        bold_nr = true,
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
        visual = 0.25,
        command = 0.2,
        operator = 0.2,
        replace = 0.2,
        select = 0.2,
        terminal = 0.2,
        terminal_n = 0.2,
    },
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
    bold_nr = true,
}
```

## 🤯 Issues

- If you use nvim-dap with nvim-dap-ui it will be quite distracting with the
cursorlines in dapui windows changing colors all the time while switching modes.

    This autocommand will turn off cursorline for dapui and also show the dapui window
    title in winbar for dapui windows:
    ```lua
    vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function()
            if string.match(vim.bo.filetype, "dapui") then
                vim.wo.cursorline = false
                vim.wo.winbar = " %t"
            end
        end,
    })
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
