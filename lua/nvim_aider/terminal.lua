local M = {}

local commands = require("nvim_aider.commands")
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
---@return snacks.win
function M.toggle(opts)
  local snacks = require("snacks.terminal")

  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = snacks.toggle(cmd, opts)
  
  -- Emit event when terminal is created/toggled on
  if term and term:buf_valid() then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "AiderTerminalOpen",
      data = { buf = term.buf }
    })
  end
  
  return term
end

---Send text to terminal
---@param text string Text to send
---@param opts? nvim_aider.Config
---@param multi_line? boolean
function M.send(text, opts, multi_line)
  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = require("snacks.terminal").get(cmd, opts)
  if not term then
    vim.notify("Please open an Aider terminal fist.", vim.log.levels.INFO)
    return
  end

  if term and term:buf_valid() then
    local chan = vim.api.nvim_buf_get_var(term.buf, "terminal_job_id")
    if chan then
      if multi_line then
        vim.fn.setreg("+", text)
        vim.api.nvim_chan_send(chan, commands.paste.value .. "\n")
      else
        text = text.gsub(text, "\n", " ") .. "\n"
        vim.api.nvim_chan_send(chan, text)
      end
    else
      vim.notify("No Aider terminal job found!", vim.log.levels.ERROR)
    end
  else
    vim.notify("Please open an Aider terminal fist.", vim.log.levels.INFO)
  end
end

---@param command string Aidar command
---@param text? string Text to send
---@param opts? nvim_aider.Config
function M.command(command, text, opts)
  text = text or ""

  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  -- NOTE: commands like `/add file` should be send to aider without a newline
  M.send(command .. " " .. text, opts, false)
end

return M
