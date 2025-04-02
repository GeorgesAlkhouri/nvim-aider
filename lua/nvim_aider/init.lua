local M = {}

M.config = require("nvim_aider.config")
M.terminal = require("nvim_aider.terminal")
M.api = require("nvim_aider.api")

local commands_menu = require("nvim_aider.commands_menu")
local utils = require("nvim_aider.utils")

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)

  -- Replace existing Aider command with this:
  vim.api.nvim_create_user_command("Aider", function(opts)
    if #opts.fargs == 0 then
      commands_menu._menu()
    else
      commands_menu._load_command(opts.fargs)
    end
  end, {
    desc = "Aider command interface",
    nargs = "*",
    complete = function(_, cmd_line)
      local matches = {}
      for name in pairs(commands_menu.commands) do
        if name:match("^" .. cmd_line:sub(-#name)) then
          table.insert(matches, name)
        end
      end
      return matches
    end,
  })

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
