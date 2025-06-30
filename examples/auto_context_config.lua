-- Example configuration for nvim-aider with auto context management
-- This shows how to set up automatic buffer management similar to joshuavial/aider.nvim
--
-- NOTE: Auto context management is DISABLED by default.
-- Set auto_manage_context = true to enable it.

require('nvim_aider').setup({
  -- Enable automatic buffer management (disabled by default)
  auto_manage_context = true,

  -- Enable auto-reload of buffers when aider changes files
  auto_reload = true,

  -- Aider command and arguments
  aider_cmd = "aider",
  args = {
    "--no-auto-commits",
    "--pretty",
    "--stream",
    "--watch-files",
  },

  -- Patterns for buffers to ignore when auto-managing context
  ignore_buffers = {
    "^term://",           -- Terminal buffers
    "NeogitConsole",      -- Neogit console
    "NvimTree_",          -- NvimTree buffers
    "neo-tree filesystem", -- Neo-tree buffers
    "^fugitive://",       -- Fugitive buffers
    "^oil://",            -- Oil.nvim buffers
    "%.git/",             -- Git files
    "node_modules/",      -- Node modules
    "%.min%.js$",         -- Minified JS files
    "%.min%.css$",        -- Minified CSS files
  },

  -- Terminal window configuration
  win = {
    wo = { winbar = "Aider" },
    style = "nvim_aider",
    position = "right",
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
})

-- Example keybindings using modern Lua syntax
local api = require('nvim_aider').api

-- Basic aider commands
vim.keymap.set('n', '<leader>ao', api.toggle_terminal, { desc = 'Toggle Aider' })
vim.keymap.set('n', '<leader>aO', api.toggle_with_all_buffers, { desc = 'Toggle Aider with all buffers' })
vim.keymap.set('n', '<leader>ac', api.add_current_file, { desc = 'Add current file to Aider' })
vim.keymap.set('n', '<leader>aA', api.add_all_buffers, { desc = 'Add all buffers to Aider' })
vim.keymap.set('n', '<leader>ad', api.drop_current_file, { desc = 'Remove current file from Aider' })
vim.keymap.set('n', '<leader>ar', api.reset_session, { desc = 'Reset Aider session' })

-- Send content to aider
vim.keymap.set('n', '<leader>as', api.send_to_terminal, { desc = 'Send to Aider' })
vim.keymap.set('v', '<leader>as', api.send_to_terminal, { desc = 'Send selection to Aider' })
vim.keymap.set('n', '<leader>ab', api.send_buffer_with_prompt, { desc = 'Send buffer to Aider' })
vim.keymap.set('n', '<leader>ae', api.send_diagnostics_with_prompt, { desc = 'Send diagnostics to Aider' })

-- Command picker
vim.keymap.set('n', '<leader>ap', api.open_command_picker, { desc = 'Open Aider command picker' })

-- Example autocmd to add files when opening them (if auto_manage_context is disabled)
-- vim.api.nvim_create_autocmd('BufReadPost', {
--   callback = function()
--     -- Only add if aider is running and file is valid
--     local filepath = vim.fn.expand('%:p')
--     if filepath ~= '' and vim.fn.filereadable(filepath) == 1 then
--       api.add_current_file()
--     end
--   end,
-- })

-- Example function to toggle auto context management at runtime
local function toggle_auto_context()
  local config = require('nvim_aider.config')
  config.options.auto_manage_context = not config.options.auto_manage_context
  vim.notify(
    'Auto context management: ' .. (config.options.auto_manage_context and 'enabled' or 'disabled'),
    vim.log.levels.INFO
  )
end

vim.keymap.set('n', '<leader>at', toggle_auto_context, { desc = 'Toggle auto context management' })

-- Example of how to customize ignore patterns at runtime
local function add_ignore_pattern()
  vim.ui.input({ prompt = 'Enter pattern to ignore: ' }, function(pattern)
    if pattern and pattern ~= '' then
      local config = require('nvim_aider.config')
      table.insert(config.options.ignore_buffers, pattern)
      vim.notify('Added ignore pattern: ' .. pattern, vim.log.levels.INFO)
    end
  end)
end

vim.keymap.set('n', '<leader>ai', add_ignore_pattern, { desc = 'Add ignore pattern' })
