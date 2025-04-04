local M = {}
local commands = require("nvim_aider.commands")
local config = require("nvim_aider.config")
local picker = require("nvim_aider.picker")
local terminal = require("nvim_aider.terminal")
local utils = require("nvim_aider.utils")

---Run health check
function M.health_check()
  vim.cmd([[checkhealth nvim_aider]])
end

---Toggle aider terminal
---@param opts? table Optional configuration override
function M.toggle_terminal(opts)
  terminal.toggle(opts or {})
end

---Send text to aider terminal
---@param text? string Optional text to send (nil for visual selection/mode-based handling)
---@param opts? table Optional configuration override
function M.send_to_terminal(text, opts)
  local mode = vim.fn.mode()
  local selected_text = text or ""
  vim.notify("Selected text: " .. selected_text, vim.log.levels.DEBUG)
  -- Visual mode handling
  if vim.tbl_contains({ "v", "V", "" }, mode) then
    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    selected_text = table.concat(lines, "\n")

    vim.ui.input({ prompt = "Add a prompt to your selection (empty to skip):" }, function(input)
      if input ~= nil then
        if input ~= "" then
          selected_text = selected_text .. "\n> " .. input
        end
        terminal.send(selected_text, opts or {}, true)
      end
    end)
  else
    -- Normal mode handling
    if selected_text == "" then
      vim.ui.input({ prompt = "Send to Aider: " }, function(input)
        if input then
          terminal.send(input, opts or {})
        end
      end)
    else
      terminal.send(selected_text, opts or {})
    end
  end
end

---Send command to aider terminal
---@param command string Aider command to execute
---@param input? string Additional input for the command
---@param opts? table Optional configuration override
function M.send_command(command, input, opts)
  terminal.command(command, input, opts or {})
end

---Send buffer contents with optional prompt
---@param opts? table Optional configuration override
function M.send_buffer_with_prompt(opts)
  local selected_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local file_type = vim.bo.filetype
  file_type = file_type == "" and "text" or file_type

  vim.ui.input({ prompt = "Add a prompt to your buffer (empty to skip):" }, function(input)
    if input ~= nil then
      if input ~= "" then
        selected_text = selected_text .. "\n> " .. input
      end
      terminal.send(selected_text, opts or {}, true)
    end
  end)
end

---Add specific file to session
---@param filepath string Path to file to add
---@param opts? table Optional configuration override
function M.add_file(filepath, opts)
  if filepath then
    terminal.command(commands.add.value, filepath, opts or {})
  else
    vim.notify("No file path provided", vim.log.levels.ERROR)
  end
end

---Add current file to session
---@param opts? table Optional configuration override
function M.add_current_file(opts)
  local filepath = utils.get_absolute_path()
  if filepath then
    M.add_file(filepath, opts)
  else
    vim.notify("No valid file in current buffer", vim.log.levels.INFO)
  end
end

---Remove specific file from session
---@param filepath string Path to file to remove
---@param opts? table Optional configuration override
function M.drop_file(filepath, opts)
  if filepath then
    terminal.command(commands.drop.value, filepath, opts or {})
  else
    vim.notify("No file path provided", vim.log.levels.ERROR)
  end
end

---Remove current file from session
---@param opts? table Optional configuration override
function M.drop_current_file(opts)
  local filepath = utils.get_absolute_path()
  if filepath then
    M.drop_file(filepath, opts)
  else
    vim.notify("No valid file in current buffer", vim.log.levels.INFO)
  end
end

---Add current file as read-only
---@param opts? table Optional configuration override
function M.add_read_only_file(opts)
  local filepath = utils.get_absolute_path()
  if filepath then
    terminal.command(commands["read-only"].value, filepath, opts)
  else
    vim.notify("No valid file in current buffer", vim.log.levels.INFO)
  end
end

---Open command picker
---@param opts? table Optional configuration override
---@param callback? function Custom callback handler
function M.open_command_picker(opts, callback)
  picker.create(opts, callback or function(picker_instance, item)
    if item.category == "input" then
      vim.ui.input({ prompt = "Enter input for `" .. item.text .. "` (empty to skip):" }, function(input)
        if input then
          terminal.command(item.text, input, opts)
        end
      end)
    else
      terminal.command(item.text, nil, opts)
    end
    picker_instance:close()
  end)
end

return M
