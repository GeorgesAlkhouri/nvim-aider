local M = {}

local config = require("nvim_aider.config")

---@param opts nvim_aider.Config
---@return string
local function create_cmd(opts)
  local cmd = { opts.aider_cmd }
  vim.list_extend(cmd, opts.args or {})

  if opts.theme then
    for key, value in pairs(opts.theme) do
      table.insert(cmd, "--" .. key:gsub("_", "-") .. "=" .. tostring(value))
    end
  end

  return table.concat(cmd, " ")
end

---Get the current aider command string using default config
---@return string
function M.get_current_cmd()
  return create_cmd(config.options)
end

---Check if aider terminal is currently running
---@return boolean
function M.is_running()
  local snacks = require("snacks.terminal")
  local cmd = M.get_current_cmd()
  local term = snacks.get(cmd, config.options)
  return term and term:buf_valid()
end

---Toggle terminal visibility
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@return snacks.win?
function M.toggle(opts)
  local snacks = require("snacks.terminal")

  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = snacks.toggle(cmd, opts)

  -- Auto-add all buffers if auto_manage_context is enabled and terminal was just created
  if opts.auto_manage_context and term and term.buf then
    -- Use a timer to ensure aider is ready to receive commands
    vim.defer_fn(function()
      local api = require("nvim_aider.api")
      api.add_all_buffers(opts)
    end, 1000)
  end

  return term
end

---Send text to terminal
---@param text string Text to send
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@param multi_line? boolean Whether to send as multi-line text (default: true)
function M.send(text, opts, multi_line)
  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  -- Always use the default command to ensure we connect to the same terminal instance
  local cmd = M.get_current_cmd()
  local term = require("snacks.terminal").get(cmd, config.options)
  if not term then
    vim.notify("Please open an Aider terminal first.", vim.log.levels.INFO)
    return
  end

  if term and term:buf_valid() then
    local chan = vim.api.nvim_buf_get_var(term.buf, "terminal_job_id")
    if chan then
      if multi_line then
        -- Use bracketed paste sequences
        local bracket_start = "\27[200~"
        local bracket_end = "\27[201~\r"
        local bracketed_text = bracket_start .. text .. bracket_end
        vim.api.nvim_chan_send(chan, bracketed_text)
      else
        text = text:gsub("\n", " ") .. "\n"
        vim.api.nvim_chan_send(chan, text)
      end
    else
      vim.notify("No Aider terminal job found!", vim.log.levels.ERROR)
    end
  else
    vim.notify("Please open an Aider terminal first.", vim.log.levels.INFO)
  end
end

---Send a command to the terminal
---@param command string Aider command (e.g. "/add")
---@param text? string Text to send after the command
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
function M.command(command, text, opts)
  text = text or ""

  -- NOTE: For Aider commands that shouldn't get a newline (e.g. `/add file`)
  M.send(command .. " " .. text, opts, false)
end

return M
