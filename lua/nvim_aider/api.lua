local M = {}
local commands = require("nvim_aider.commands_slash")
local diagnostics = require("nvim_aider.diagnostics")
local picker = require("nvim_aider.picker")
local session = require("nvim_aider.session")
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

---Send diagnostics content with optional prompt
---@param opts? table Optional configuration override
function M.send_diagnostics_with_prompt(opts)
  local current_diagnostics = vim.diagnostic.get(0) -- Get diagnostics for the current buffer (bufnr 0)

  if not current_diagnostics or #current_diagnostics == 0 then
    vim.notify("No diagnostics found in the current buffer.", vim.log.levels.INFO)
    return
  end

  local formatted_diagnostics = diagnostics.format_diagnostics(current_diagnostics)
  local buf_name = vim.fn.bufname("%")

  vim.ui.input({
    prompt = "Add a prompt for the diagnostics:",
    default = "Here are the diagnostics for " .. buf_name .. ":",
  }, function(input)
    if input ~= nil then
      local final_output = formatted_diagnostics
      if input ~= "" then
        final_output = input .. "\n" .. final_output
      end
      terminal.send(final_output, opts or {}, true)
    end
  end)
end

---Add specific file to session
---@param filepath string Path to file to add
---@param opts? table Optional configuration override
function M.add_file(filepath, opts)
  if filepath then
    terminal.command(commands.add.value, filepath, opts or {})
    session.add_file(filepath)
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

---Add all valid buffers to session
---@param opts? table Optional configuration override
function M.add_all_buffers(opts)
  local config = require("nvim_aider.config")
  local ignore_patterns = config.options.ignore_buffers or {}
  local filepaths = utils.get_valid_buffers(ignore_patterns)

  if #filepaths == 0 then
    vim.notify("No valid buffers found to add", vim.log.levels.INFO)
    return
  end

  for _, filepath in ipairs(filepaths) do
    M.add_file(filepath, opts)
  end

  vim.notify(string.format("Added %d buffers to aider session", #filepaths), vim.log.levels.INFO)
end

---Remove specific file from session
---@param filepath string Path to file to remove
---@param opts? table Optional configuration override
function M.drop_file(filepath, opts)
  if filepath then
    terminal.command(commands.drop.value, filepath, opts or {})
    session.remove_file(filepath)
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

---Reset the Aider session (drop all files and clear history)
---@param opts? table Optional configuration override
function M.reset_session(opts)
  terminal.command(commands.reset.value, nil, opts or {})
  session.clear_session()
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

---Toggle aider terminal and auto-add all buffers
---@param opts? table Optional configuration override
function M.toggle_with_all_buffers(opts)
  local config = require("nvim_aider.config")
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  opts.auto_manage_context = true  -- Force auto-add for this call

  return M.toggle_terminal(opts)
end

return M
