local M = {}

M.config = require("nvim_aider.config")
M.terminal = setmetatable({}, {
  __index = function(_, key)
    vim.notify(
      '[nvim_aider] require("nvim_aider").terminal is deprecated and will be removed soon.',
      vim.log.levels.WARN
    )
    return require("nvim_aider.terminal")[key]
  end,
})
M.api = require("nvim_aider.api")

local commands = require("nvim_aider.commands")
local picker = require("nvim_aider.picker")
local utils = require("nvim_aider.utils")

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)

  vim.api.nvim_create_user_command("AiderHealth", function()
    M.api.health_check()
  end, { desc = "Run :checkhealth nvim_aider" })

  vim.api.nvim_create_user_command("AiderTerminalToggle", function()
    M.api.toggle_terminal()
  end, {})

  vim.api.nvim_create_user_command("AiderTerminalSend", function(args)
    local mode = vim.fn.mode()
    if vim.tbl_contains({ "v", "V", "" }, mode) then
      -- Visual mode behavior
      local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
      local selected_text = table.concat(lines, "\n")
      local file_type = vim.bo.filetype
      if file_type == "" then
        file_type = "text"
      end
      vim.ui.input({ prompt = "Add a prompt to your selection (empty to skip):" }, function(input)
        if input ~= nil then
          if input ~= "" then
            selected_text = selected_text .. "\n> " .. input
          end
          M.api.send_to_terminal(selected_text)
        end
      end)
    else
      -- Normal mode behavior
      if args.args == "" then
        vim.ui.input({ prompt = "Send to Aider: " }, function(input)
          if input then
            M.api.send_to_terminal(input)
          end
        end)
      else
        M.api.send_to_terminal(args.args)
      end
    end
  end, { nargs = "?", range = true, desc = "Send text to Aider terminal" })

  vim.api.nvim_create_user_command("AiderQuickSendCommand", function()
    M.api.open_command_picker(opts)
  end, { desc = "Quick send Aider command" })

  vim.api.nvim_create_user_command("AiderQuickSendBuffer", function()
    M.api.send_buffer_with_prompt()
  end, {})

  vim.api.nvim_create_user_command("AiderQuickAddFile", function()
    M.api.add_current_file()
  end, {})

  vim.api.nvim_create_user_command("AiderQuickDropFile", function()
    M.api.drop_current_file()
  end, {})

  vim.api.nvim_create_user_command("AiderQuickReadOnlyFile", function()
    M.api.add_read_only_file()
  end, {})

  require("nvim_aider.tree").setup(opts)
end

return M
