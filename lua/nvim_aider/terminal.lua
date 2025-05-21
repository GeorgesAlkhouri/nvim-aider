local M = {}

local config = require("nvim_aider.config")

-- Terminal state (for nvim term)
local state = {
  buf = nil, -- Terminal buffer
  win = nil, -- Terminal window
  chan = nil, -- Terminal channel ID
}

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

-- Create a new Neovim terminal
local function create_nvim_terminal(cmd, opts)
  -- Create a vertical split
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options for persistence
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")

  -- Set the buffer in the window
  vim.api.nvim_win_set_buf(win, buf)

  -- Start terminal with the command
  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      state.buf = nil
      state.win = nil
      state.chan = nil
    end,
  })

  -- Store state
  state.buf = buf
  state.win = win
  state.chan = vim.api.nvim_buf_get_var(buf, "terminal_job_id")

  -- Enter insert mode
  vim.cmd("startinsert")

  return { buf = buf, win = win }
end

---Toggle terminal visibility
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@return snacks.win?
function M.toggle(opts)
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  local cmd = create_cmd(opts)

  if opts.terminal_emulator == "snacks" then
    local snacks = require("snacks.terminal")
    return snacks.toggle(cmd, opts)
  else
    -- Handle native terminal toggle
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      -- Terminal window exists, hide it
      vim.api.nvim_win_hide(state.win)
    elseif state.buf and vim.api.nvim_buf_is_valid(state.buf) then
      -- Buffer exists but not shown, show it in a new window
      vim.cmd("vsplit")
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, state.buf)
      state.win = win
      vim.cmd("startinsert")
    else
      -- Create new terminal
      return create_nvim_terminal(cmd, opts)
    end
  end
end

---Send text to terminal
---@param text string Text to send
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@param multi_line? boolean Whether to send as multi-line text (default: true)
function M.send(text, opts, multi_line)
  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  if opts.terminal_emulator == "snacks" then
    -- Use existing snacks implementation
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
    end
  else
    -- Use native terminal implementation
    if not state.chan then
      vim.notify("Please open an Aider terminal first.", vim.log.levels.INFO)
      return
    end

    if multi_line then
      local bracket_start = "\27[200~"
      local bracket_end = "\27[201~\r"
      local bracketed_text = bracket_start .. text .. bracket_end
      vim.api.nvim_chan_send(state.chan, bracketed_text)
    else
      text = text:gsub("\n", " ") .. "\n"
      vim.api.nvim_chan_send(state.chan, text)
    end
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
