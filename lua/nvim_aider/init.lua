local M = {}

M.config = require("nvim_aider.config")
M.terminal = require("nvim_aider.terminal")

local commands = require("nvim_aider.commands")
local picker = require("nvim_aider.picker")
local utils = require("nvim_aider.utils")

---@param filepath? string Optional filepath to add, if nil will use current buffer
---@return nil
function M.add_file(filepath)
  local path = filepath
  if path == nil then
    path = utils.get_absolute_path()
    if path == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
      return
    end
  end
  M.terminal.command(commands.add.value, path)
end

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)

  vim.api.nvim_create_user_command("AiderHealth", function()
    vim.cmd([[checkhealth nvim_aider]])
  end, { desc = "Run :checkhealth nvim_aider" })

  vim.api.nvim_create_user_command("AiderTerminalToggle", function()
    M.terminal.toggle()
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
          M.terminal.send(selected_text)
        end
      end)
    else
      -- Normal mode behavior
      if args.args == "" then
        vim.ui.input({ prompt = "Send to Aider: " }, function(input)
          if input then
            M.terminal.send(input)
          end
        end)
      else
        M.terminal.send(args.args)
      end
    end
  end, { nargs = "?", range = true, desc = "Send text to Aider terminal" })

  vim.api.nvim_create_user_command("AiderQuickSendCommand", function()
    picker.create(opts, function(picker_instance, item)
      if item.category == "input" then
        vim.ui.input({ prompt = "Enter input for `" .. item.text .. "` (empty to skip):" }, function(input)
          if input then
            M.terminal.command(item.text, input)
          end
        end)
      else
        M.terminal.command(item.text)
      end
      picker_instance:close()
    end)
  end, { desc = "Quick send Aider command" })

  vim.api.nvim_create_user_command("AiderQuickSendBuffer", function()
    local selected_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local file_type = vim.bo.filetype
    if file_type == "" then
      file_type = "text"
    end
    vim.ui.input({ prompt = "Add a prompt to your buffer (empty to skip):" }, function(input)
      if input ~= nil then
        if input ~= "" then
          selected_text = selected_text .. "\n> " .. input
        end
        M.terminal.send(selected_text)
      end
    end)
  end, {})

  vim.api.nvim_create_user_command("AiderQuickAddFile", function()
    M.add_file()
  end, {})

  vim.api.nvim_create_user_command("AiderQuickDropFile", function()
    local filepath = utils.get_absolute_path()
    if filepath == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    else
      M.terminal.command(commands.drop.value, filepath)
    end
  end, {})

  vim.api.nvim_create_user_command("AiderQuickReadOnlyFile", function()
    local filepath = utils.get_absolute_path()
    if filepath == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    else
      M.terminal.command(commands["read-only"].value, filepath)
    end
  end, {})

  require("nvim_aider.tree").setup(opts)
end

return M
