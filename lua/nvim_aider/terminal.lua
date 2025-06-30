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
  -- Instead of using snacks.get which might create a terminal,
  -- let's check for existing terminal buffers manually
  local cmd = M.get_current_cmd()

  -- Look through all buffers to find an existing aider terminal
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buf_name = vim.api.nvim_buf_get_name(bufnr)
      -- Check if this is a terminal buffer with our aider command
      if vim.bo[bufnr].buftype == "terminal" and buf_name:find("aider", 1, true) then
        -- Check if the terminal job is still running
        local ok, chan = pcall(vim.api.nvim_buf_get_var, bufnr, "terminal_job_id")
        if ok and chan and chan > 0 then
          -- Verify the job is actually running
          local job_info = vim.fn.jobwait({chan}, 0)
          if job_info[1] == -1 then -- -1 means job is still running
            return true
          end
        end
      end
    end
  end

  return false
end

---Toggle terminal visibility
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@return snacks.win?
function M.toggle(opts)
  local snacks = require("snacks.terminal")

  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)

  -- Check if terminal was already running before toggle
  local was_running = M.is_running()

  local term = snacks.toggle(cmd, opts)

  -- Auto-add all buffers if auto_manage_context is enabled and we're starting a new aider process
  -- This happens when:
  -- 1. Terminal wasn't running before (no existing aider process)
  -- 2. Now we have a valid terminal with a running job (new process started)
  if opts.auto_manage_context and term and term.buf and not was_running then
    -- Double check that we actually have a new running process
    vim.defer_fn(function()
      -- Verify the terminal has a running job before adding buffers
      local ok, chan = pcall(vim.api.nvim_buf_get_var, term.buf, "terminal_job_id")
      if ok and chan and chan > 0 then
        -- Check if the job is actually running (not finished)
        local job_info = vim.fn.jobwait({chan}, 0)
        if job_info[1] == -1 then -- -1 means job is still running
          local api = require("nvim_aider.api")
          api.add_all_buffers(opts)
        end
      end
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
