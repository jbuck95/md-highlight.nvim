MdHighlight
A Neovim plugin to highlight text between == markers in Markdown, text, and Org files. Supports Pywal color integration, custom colors, and toggleable rendering.
Features

Highlights text between == (e.g., ==highlighted text==).
Supports Pywal colors, custom colors, or fallback colors.
Configurable highlight styles (bold, italic, underline).
Auto-rendering with toggle and clear commands.
Keybinds for easy control.
Works with Markdown, text, and Org files.

Installation
Using Lazy.nvim
require("lazy").setup({
  {
    "your-username/md-highlight",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("md-highlight").setup({
        -- Optional configuration
        colors = {
          use_pywal = true, -- Use Pywal colors
          fallback = {
            bg = "#ffff00", -- Yellow
            fg = "#000000", -- Black
          },
          pywal_color_index = {
            bg = 3, -- Pywal color3 (yellow/orange)
            fg = 0, -- Pywal color0 (dark)
          },
        },
        style = {
          bold = true,
          italic = false,
          underline = false,
        },
      })
    end,
    event = "VeryLazy",
  },
})

Using packer.nvim
use {
  "your-username/md-highlight",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("md-highlight").setup()
  end,
}

Configuration
Default configuration:
{
  highlight_group = "MdHighlight",
  pattern = "==[^=]+==", -- Pattern to match text between ==
  filetypes = { "markdown", "text", "org" },
  auto_render = true,
  keybinds = {
    toggle_highlight = "<leader>mh", -- Toggle rendering
    clear_highlights = "<leader>mc", -- Clear highlights
  },
  colors = {
    use_pywal = true,
    fallback = {
      bg = "#ffff00", -- Yellow
      fg = "#000000", -- Black
    },
    pywal_color_index = {
      bg = 3, -- Pywal color3
      fg = 0, -- Pywal color0
    },
    custom = {
      bg = nil, -- Override with custom background color
      fg = nil, -- Override with custom foreground color
    },
  },
  style = {
    bold = true,
    italic = false,
    underline = false,
  },
}

Commands

:MdHighlightToggle - Toggle highlighting on/off.
:MdHighlightClear - Clear all highlights.
:MdHighlightReloadColors - Reload colors (useful after Pywal changes).
:MdHighlightShowColors - Show available Pywal colors.

Keybinds

<leader>mh: Toggle highlighting.
<leader>mc: Clear highlights.

Dependencies

plenary.nvim (required for file operations).


