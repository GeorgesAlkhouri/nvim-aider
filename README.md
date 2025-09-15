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
- [x] ♻️ Reset command to clear session
- [x] 💬 Optional user prompt for buffer and selection sends
- [x] 🩺 Send current buffer diagnostics to Aider
- [x] 🔍 Aider command selection UI with fuzzy search and input prompt
- [x] 🔌 Fully documented [Lua API](lua/nvim_aider/api.lua) for
      programmatic interaction and custom integrations
- [x] 🛡️ Command guard with status notifications to prevent interrupting Aider while it's processing
- [x] 🔄 Auto-reload buffers on external changes (requires 'autoread')

## 🧩 Integrations

- [x] 🌲➕ [Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) offers rich context management for Aider, including files, directories, and multi-selection
- [x] 🔖 [bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim) enables adding (optionally as read-only) or dropping files from Aider using saved bookmarks
- [x] 🌳 [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) enables adding or dropping individual files to Aider directly from its tree interface

## 🎮 Commands

- `:Aider` - Open interactive command menu

  ```text
  Commands:
  health         🩺 Check plugin health status
  toggle         🎛️ Toggle Aider terminal window
  send           📤 Send text to Aider (prompt if empty)
  command        ⌨️ Show slash commands
  buffer         📄 Send current buffer
   > diagnostics 🩺 Send current buffer diagnostics
  add            ➕ Add file to session
   > readonly    👀 Add as read-only reference
  drop           🗑️ Remove file from session
  reset          ♻️ Drop all files and clear chat history
  ```

- ⚡ Direct command execution examples:

  ```vim
  :Aider health
  :Aider add readonly
  :Aider send "Fix login validation"
  :Aider reset
  ```

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
    cmd = "Aider",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
      { "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
      { "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
      { "<leader>a+", "<cmd>Aider add<cr>", desc = "Add File" },
      { "<leader>a-", "<cmd>Aider drop<cr>", desc = "Drop File" },
      { "<leader>ar", "<cmd>Aider add readonly<cr>", desc = "Add Read-Only" },
      { "<leader>aR", "<cmd>Aider reset<cr>", desc = "Reset Session" },
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
          --     ["="] = { "nvim_aider_add_read_only", desc = "add read-only to aider" }
          --   }
          -- }
          require("nvim_aider.neo_tree").setup(opts)
        end,
      },
    },
    config = true,
  }
```

After installing, run `:Aider health` to check if everything is set up correctly.

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
  -- Automatically reload buffers changed by Aider (requires vim.o.autoread = true)
  auto_reload = false,
  -- Idle timeout in ms for Aider's output.
  idle_timeout = 5000,
  -- Response timeout in ms for Aider's first output chunk.
  response_timeout = 30000,
  -- Timeout in ms for quick commands.
  quick_idle_timeout = 500,
  -- A list of slash-commands that should have a shorter idle timeout.
  quick_commands = {
    "/add",
    "/drop",
    "/read-only",
    "/ls",
    "/clear",
    "/reset",
    "/undo",
  },
  -- Show 'Processing...' and 'Done' notifications.
  notifications = true,
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
    position = "right",
  },
})
```

## 📚 API Reference

The plugin provides a structured API for programmatic integration. Access via `require("nvim_aider").api`

### Core Functions

```lua
local api = require("nvim_aider").api
```

#### `health_check()`

Verify plugin health status

```lua
api.health_check()
```

#### `toggle_terminal(opts?)`

Toggle Aider terminal window

```lua
api.toggle_terminal()
```

---

### Terminal Operations

#### `send_to_terminal(text, opts?)`

Send raw text directly to Aider

```lua
api.send_to_terminal("Fix the login validation")
```

#### `send_command(command, input?, opts?)`

Execute specific Aider command

```lua
api.send_command("/commit", "Add error handling")
```

#### `reset_session(opts?)`

Drop all files and clear chat history

```lua
api.reset_session()
```

---

### File Management

#### `add_file(filepath)`

Add specific file to session

```lua
api.add_file("/src/utils.lua")
```

#### `drop_file(filepath)`

Remove file from session

```lua
api.drop_file("/outdated/legacy.py")
```

#### `add_current_file()`

Add current buffer's file (uses `add_file` internally)

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    api.add_current_file()
  end
})
```

#### `drop_current_file()`

Remove current buffer's file

```lua
api.drop_current_file()
```

#### `add_read_only_file()`

Add current buffer as read-only reference

```lua
api.add_read_only_file()
```

---

### Buffer Operations

#### `send_buffer_with_prompt(opts?)`

Send entire buffer content with optional prompt

```lua
api.send_buffer_with_prompt()
```

#### `send_diagnostics_with_prompt(opts?)`

Send current buffer's diagnostics with an optional prompt

```lua
api.send_diagnostics_with_prompt()
```

---

### UI Components

#### `open_command_picker(opts?, callback?)`

Interactive command selector with custom handling

```lua
api.open_command_picker(nil, function(picker, item)
  if item.text == "/custom" then
    -- Implement custom command handling
  else
    -- Default behavior
    picker:close()
    api.send_command(item.text)
  end
end)
```

---

## 🧩 Other Aider Neovim plugins

- [aider.nvim](https://github.com/joshuavial/aider.nvim)
- [aider.vim](https://github.com/nekowasabi/aider.vim)

---

<div align="center">
Made with 🤖 using <a href="https://github.com/paul-gauthier/aider">Aider</a>
</div>
