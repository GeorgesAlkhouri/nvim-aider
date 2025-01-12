# [![aider](https://avatars.githubusercontent.com/u/172139148?s=20&v=4)](https://aider.chat) nvim-aider

🤖 Seamlessly integrate Aider with Neovim for an enhanced AI-assisted coding experience!

![screenshot_1](https://github.com/user-attachments/assets/5d779f73-5441-4d24-8cce-e6dfdc5bf787)
![scrennshot_2](https://github.com/user-attachments/assets/6e8c3ed4-84d8-49bb-9aba-7d81323864d8)

> 🚧 This plugin is in initial development. Expect breaking changes and rough edges.  
> _October 17, 2024_

## 🌟 Features

- [x] 🖥️ Aider terminal integration within Neovim
- [x] 🎨 Color theme configuration support with auto Catppuccin flavor synchronization
      if available
- [x] 📤 Quick commands to add/drop current buffer files
- [x] 📤 Send buffers or selections to Aider
- [x] 💬 Optional user prompt for buffer and selection sends
- [x] 🔍 Aider command selection UI with fuzzy search and input prompt

## 🎮 Commands

- ⌨️ `AiderTerminalToggle` - Toggle the Aider terminal window
- 📤 `AiderTerminalSend [text]` - Send text to Aider
  - Without arguments: Opens input prompt
  - With arguments: Sends provided text directly
  - In visual mode: Sends selected text with an optional prompt
- 🔍 `AiderQuickSendCommand` - List all Aider commands in telescope picker
  with option to add prompt after selection
- 📁 `AiderQuickAddFile` - Add current buffer file to Aider session
- 🗑️ `AiderQuickDropFile` - Remove current buffer file from Aider session
- 📋 `AiderQuickSendBuffer` - Send entire buffer content to Aider
  with an optional prompt

### 🔭 Telescope Integration

The plugin provides telescope extensions for file management:

```lua
-- Add files to Aider session (use <C-a> to select)
:Telescope aider_add

-- Drop files from Aider session (use <C-d> to select)
:Telescope aider_drop
```

## 🔗 Requirements

🐍 Python: Install `aider-chat`  
📋 System: **Neovim** >= 0.9.4, ~~Working clipboard~~ thanks to @milanglacier  
🌙 Lua: `folke/snacks.nvim`, `nvim-telescope/telescope.nvim`,
_optionals_ `catppuccin/nvim`

## 📦 Installation

Using lazy.nvim:

```lua
{
    "GeorgesAlkhouri/nvim-aider",
    cmd = {
      "AiderTerminalToggle",
    },
    keys = {
      { "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
      { "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
      { "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
      { "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
      { "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
    },
    dependencies = {
      "folke/snacks.nvim",
      "nvim-telescope/telescope.nvim",
      --- The below dependencies are optional
      "catppuccin/nvim",
    },
    config = true,
  }
```

## ⚙️ Configuration

There is no need to call setup if you don't want to change the default options.

### Basic Setup
```lua
require("nvim_aider").setup({
  -- Command line arguments passed to aider
  args = {
    "--no-auto-commits",
    "--pretty",
    "--stream",
  },

  -- Theme colors (automatically uses Catppuccin flavor if available)
  theme = {
    user_input_color = "#a6da95",
    tool_output_color = "#8aadf4",
    tool_error_color = "#ed8796",
    tool_warning_color = "#eed49f",
    assistant_output_color = "#c6a0f6",
    completion_menu_color = "#cad3f5",
    completion_menu_bg_color = "#24273a",
    completion_menu_current_color = "#181926",
    completion_menu_current_bg_color = "#f4dbd6",
  },

  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },

  win = {
    style = "nvim_aider",
    position = "bottom",
  },
})

-- Enable telescope integration (optional)
require("telescope").load_extension("aider")
```

### Telescope Integration

To use the telescope integration:

1. Make sure telescope.nvim is installed as a dependency
2. Add `require("telescope").load_extension("aider")` to your config
3. Use the commands:
   - `:Telescope aider_add` - Add files to Aider session
   - `:Telescope aider_drop` - Remove files from Aider session

The telescope pickers support multi-selection with `<C-a>` for add and `<C-d>` for drop.

---

<div align="center">
Made with 🤖 using <a href="https://github.com/paul-gauthier/aider">Aider</a>
</div>
