local M = {}

local config = require("nvim_aider.config")

---@param opts nvim_aider.Config
---@return string
local function create_cmd(opts)
  local cmd = { opts.aider_cmd }
  vim.list_extend(cmd, opts.args or {})

  if opts.theme then
    for k, v in pairs(opts.theme) do
      table.insert(cmd, "--" .. k:gsub("_", "-") .. "=" .. tostring(v))
    end
  end
  return table.concat(cmd, " ")
end
-- --------------------------------------------------------------------- --

---Toggle terminal visibility
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@return snacks.win?
function M.toggle(opts)
  local snacks = require("nvim_aider.snacks_ext") -- << the wrapper >>
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  local cmd = create_cmd(opts)
  local term = snacks.toggle(cmd, opts)

  if term and not snacks.is_running(term) then
    term:close()
    term = snacks.toggle(cmd, opts)
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

  local snacks = require("nvim_aider.snacks_ext")
  local cmd = create_cmd(opts)
  local term = snacks.get(cmd, opts)

  -- guards ---------------------------------------------------------------
  if not (term and term:buf_valid()) then
    vim.notify("Open an Aider terminal first ( :Aider toggle ).", vim.log.levels.INFO, { title = "nvim-aider" })
    return
  end
  if not snacks.is_running(term) then
    vim.notify("Aider process is not running – reopen the terminal.", vim.log.levels.ERROR, { title = "nvim-aider" })
    return
  end
  if vim.b[term.buf].aider_busy then
    vim.notify("Aider is still processing the previous command…", vim.log.levels.WARN, { title = "nvim-aider" })
    return
  end

  -- payload --------------------------------------------------------------
  local payload
  if multi_line then
    local bs, be = "\27[200~", "\27[201~"
    payload = bs .. text .. be
  else
    payload = text:gsub("\n", " ") .. "\n"
  end

  -- fire via wrapper helper ----------------------------------------------
  if term.send_with_timer then
    term:send_with_timer(payload)
  else -- very old snacks build: fall back
    vim.api.nvim_chan_send(term.job_id, payload)
  end
end

---Send an Aider slash‑command (convenience)
function M.command(cmd, text, opts)
  M.send((cmd or "") .. " " .. (text or ""), opts, false)
end

return M
