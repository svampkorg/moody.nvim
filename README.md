<h1 align="center">✨ moody.nvim ✨</h1>

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

- [Why](#-Why?)
- [Setup](#-Setup)
- [Acknowledgments](#-Acknowledgments)

## ❓Why?

- Because sometimes I loose track of which mode I'm in, so I have to look down at the StatusLine to check if the color of it means 'Insert' or 'Command' or 'Normal' etc..
I figured it'd be quicker if the CursorColomn would change colour depending on mode.

## 🫣 Setup

```lua
    {
        todo = 'add some necessary config'
    }
```

## 👏 Acknowledgments

Neovim is growing a nice ecosystem, but some parts of plugin development are sometimes obscure. This template is an attempt to put together best practices by copying:

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure*
- [S1M0N38/my-awesome-plugin.nvim](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure* I used this to generate the structure of this plugin. Thanks S1M0N38! ❤️
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - *Tests, lint, docs generation*
