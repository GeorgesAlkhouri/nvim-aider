# [![aider](https://avatars.githubusercontent.com/u/172139148?s=20&v=4)](https://aider.chat) nvim-aider

🤖 Seamlessly integrate Aider with Neovim for an enhanced AI-assisted coding experience!

<img width="1280" alt="screenshot_1" src="https://github.com/user-attachments/assets/5d779f73-5441-4d24-8cce-e6dfdc5bf787" />
<img width="1280" alt="screenshot_2" src="https://github.com/user-attachments/assets/3c122846-ca27-42d3-8cbf-f6e5f9b10f69" />

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
- [x] 🌲➕ [Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim)
      integration also with multi-file/directory selection with visual mode support
- [x] 🌳 Integration with [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
      for adding or dropping files directly from the tree interface

## 🎮 Commands

- 🩺 `AiderHealth` - Check if everything is working correctly
- ⌨️ `AiderTerminalToggle` - Toggle the Aider terminal window
- 📤 `AiderTerminalSend [text]` - Send text to Aider
  - Without arguments: Opens input prompt
  - With arguments: Sends provided text directly
  - In visual mode: Sends selected text with an optional prompt
- 🔍 `AiderQuickSendCommand` - List all Aider commands from 🍿 Snacks picker
  with option to add prompt after selection
- 📁 `AiderQuickAddFile` - Add current buffer file to Aider session
- 🗑️ `AiderQuickDropFile` - Remove current buffer file from Aider session
- 📋 `AiderQuickSendBuffer` - Send entire buffer content to Aider
  with an optional prompt
- 📚 `AiderQuickReadOnlyFile` - Add current buffer as read-only reference file
- 🌳 `AiderTreeAddReadOnlyFile` - Add a read-only file from nvim-tree to Aider chat

## 🔗 Requirements

🐍 Python: Install `aider-chat`  
📋 System: **Neovim** >= 0.9.4, ~~Working clipboard~~ thanks to @milanglacier  
🌙 Lua: `folke/snacks.nvim`,  
_optionals_ `catppuccin/nvim`, `nvim-neo-tree/neo-tree.nvim`, `nvim-tree.lua`

## 📦 Installation

Using lazy.nvim:

```lua
{
    "GeorgesAlkhouri/nvim-aider",
    cmd = {
      "AiderTerminalToggle", "AiderHealth",
    },
    keys = {
      { "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
      { "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
      { "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
      { "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
      { "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
      { "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
      -- Example nvim-tree.lua integration if needed
      { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
      { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
    },
    dependencies = {
      "folke/snacks.nvim",
      --- The below dependencies are optional
      "catppuccin/nvim",
      "nvim-tree/nvim-tree.lua",
      --- Neo-tree integration
      {
        "nvim-neo-tree/neo-tree.nvim",
        opts = function(_, opts)
          -- Example mapping configuration (already set by default)
          -- opts.window = {
          --   mappings = {
          --     ["+"] = { "nvim_aider_add", desc = "add to aider" },
          --     ["-"] = { "nvim_aider_drop", desc = "drop from aider" }
          --   }
          -- }
          require("nvim_aider.neo_tree").setup(opts)
        end,
      },
    },
    config = true,
  }
```

## ⚙️ Configuration

There is no need to call setup if you don't want to change the default options.

```lua
require("nvim_aider").setup({
  -- Command that executes Aider
  aider_cmd = "aider",
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
  -- snacks.picker.layout.Config configuration
  picker_cfg = {
    preset = "vscode",
  },
  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "Aider" },
    style = "nvim_aider",
    position = "bottom",
  },
})
```

## 🎮 Terminal Keymaps

The plugin emits a `User` event `AiderTerminalOpen` when the terminal is created, allowing you to set up buffer-local keymaps. For example, to make `<Esc>` close the terminal in normal mode:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "AiderTerminalOpen",
  callback = function(args)
    local buf = args.data.buf
    vim.keymap.set("n", "<Esc>", function()
      require("nvim_aider.terminal").toggle()
    end, { buffer = buf, silent = true })
  end,
})
```

---

<div align="center">
Made with 🤖 using <a href="https://github.com/paul-gauthier/aider">Aider</a>
</div>
