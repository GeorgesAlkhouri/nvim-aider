local M = {}

local config = require("nvim_aider.config")

---Create command string list from options
---@param opts nvim_aider.Config
---@return string[]
local function create_cmd(opts)
  local cmd = { "aider" }
  vim.list_extend(cmd, opts.args or {})

  if opts.theme then
    for key, value in pairs(opts.theme) do
      table.insert(cmd, "--" .. key:gsub("_", "-"))
      table.insert(cmd, value)
    end
  end

  return cmd
end

---Toggle terminal visibility
---@param opts? nvim_aider.Config
---@return snacks.win?
function M.toggle(opts)
  if vim.fn.executable("aider") == 0 then
    vim.notify("aider executable not found in PATH", vim.log.levels.ERROR)
    return
  end
  local snacks = require("snacks.terminal")

  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  return snacks.toggle(cmd, opts)
end

---Send text to terminal
---@param text string Text to send
---@param opts? nvim_aider.Config
---@param multi_line? boolean
function M.send(text, opts, multi_line)
  if vim.fn.executable("aider") == 0 then
    vim.notify("aider executable not found in PATH", vim.log.levels.ERROR)
    return
  end

  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = require("snacks.terminal").get(cmd, opts)
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

---@param command string Aidar command
---@param text? string Text to send
---@param opts? nvim_aider.Config
function M.command(command, text, opts)
  text = text or ""

  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  -- NOTE: For Aider commands that shouldn't get a newline (e.g. `/add file`)
  M.send(command .. " " .. text, opts, false)
end

return M
