-- nvim_aider/snacks_ext.lua  ----------------------------------------------
--
-- Runtime extension of snacks.terminal: adds
--   • term:send_with_timer(payload)
--   • vim.b[buf].aider_busy flag
--   • Processing / Done notifications
-- without touching snacks.nvim’s source.

local Base = require("snacks.terminal")
local Snacks = require("snacks")
local uv = vim.uv or vim.loop

-- forward‑declarations so we can reuse them in both toggle() and get()
local function open_override(cmd, opts) end

-- ----------------------------------------------------------------------- --
-- create a table that proxies every unknown key to the original module    --
local M = setmetatable({}, {
  __index = Base, -- standard single‑inheritance idiom :contentReference[oaicite:3]{index=3}
  __call = function(_, ...)
    return M.toggle(...)
  end,
})

-- ----------------------------------------------------------------------- --
-- Public helpers                                                          --
function M.is_running(term)
  return term and term.job_id and vim.fn.jobwait({ term.job_id }, 0)[1] == -1
end

-- ----------------------------------------------------------------------- --
-- wrap Base.toggle / Base.get so the override is always injected --------- --
function M.toggle(cmd, opts)
  opts = vim.tbl_deep_extend("force", opts or {}, { override = open_override })
  return Base.toggle(cmd, opts)
end

function M.get(cmd, opts)
  opts = vim.tbl_deep_extend("force", opts or {}, { override = open_override })
  return Base.get(cmd, opts)
end

-- ----------------------------------------------------------------------- --
-- Implementation of the override: timers + notifications -----------------
function open_override(cmd, opts)
  local id = vim.v.count1
  opts.win = Snacks.win.resolve("terminal", { position = cmd and "float" or "bottom" }, opts.win, { show = false })
  opts = vim.deepcopy(opts)
  opts.win.wo.winbar = opts.win.wo.winbar
    or (opts.win.position == "float" and "" or (id .. ": %{get(b:, 'term_title', '')}"))

  local interactive = opts.interactive ~= false
  local auto_insert = opts.auto_insert or (opts.auto_insert == nil and interactive)
  local start_insert = opts.start_insert or (opts.start_insert == nil and interactive)
  local auto_close = opts.auto_close or (opts.auto_close == nil and interactive)

  local on_buf = opts.win and opts.win.on_buf
  opts.win.on_buf = function(self)
    self.cmd = cmd
    vim.b[self.buf].snacks_terminal = { cmd = cmd, id = id }
    if on_buf then
      on_buf(self)
    end
  end
  local on_win = opts.win and opts.win.on_win
  opts.win.on_win = function(self)
    if start_insert and vim.api.nvim_get_current_buf() == self.buf then
      vim.cmd.startinsert()
    end
    if on_win then
      on_win(self)
    end
  end

  local term = Snacks.win(opts.win)

  if auto_insert then
    term:on("BufEnter", function()
      vim.cmd.startinsert()
    end, { buf = true })
  end

  if auto_close then
    term:on("TermClose", function()
      if type(vim.v.event) == "table" and vim.v.event.status ~= 0 then
        vim.notify(
          "Terminal exited with code " .. vim.v.event.status .. ".\nCheck for any errors.",
          vim.log.levels.ERROR,
          { title = "nvim-aider" }
        )
        return
      end
      term:close()
      vim.cmd.checktime()
    end, { buf = true })
  end

  term:on("ExitPre", function()
    term:close()
  end)
  term:on("BufWipeout", function()
    vim.schedule(function()
      term:close()
    end)
  end, { buf = true })

  term:show()

  --------------------------------------------------------------------------
  -- TIMER STATE                                                           --
  --------------------------------------------------------------------------
  local response_timeout = opts.response_timeout or 30000
  local uv = vim.uv or vim.loop
  local idle_timer = uv.new_timer()
  local response_timer = uv.new_timer()
  local got_first_chunk = false

  --------------------------------------------------------------------------
  -- notification state per buffer                                         --
  --------------------------------------------------------------------------
  vim.b[term.buf].aider_notif = nil

  local function get_effective_opts()
    local send_opts = vim.b[term.buf] and vim.b[term.buf].aider_send_opts or {}
    return vim.tbl_deep_extend("force", {}, opts, send_opts)
  end

  local function notify(msg, level, icon, prev)
    local n_opts = { title = "nvim-aider", icon = icon or "", replace = prev }
    return vim.notify(msg, level, n_opts)
  end

  local function set_processing()
    if get_effective_opts().notifications then
      vim.b[term.buf].aider_notif = notify("Processing…", vim.log.levels.INFO, "", vim.b[term.buf].aider_notif)
    end
  end
  local function set_still_waiting()
    if get_effective_opts().notifications then
      vim.b[term.buf].aider_notif = notify("Still waiting…", vim.log.levels.WARN, "", vim.b[term.buf].aider_notif)
    end
  end
  local function set_done()
    if get_effective_opts().notifications then
      vim.b[term.buf].aider_notif = notify("Done ✔", vim.log.levels.INFO, "", vim.b[term.buf].aider_notif)
    end
  end
  local function set_error(code)
    if get_effective_opts().notifications then
      vim.b[term.buf].aider_notif =
        notify("Exited (" .. code .. ")", vim.log.levels.ERROR, "", vim.b[term.buf].aider_notif)
    end
  end

  --------------------------------------------------------------------------
  -- helpers                                                               --
  --------------------------------------------------------------------------
  local function reset_idle_timer()
    local effective_opts = get_effective_opts()
    local current_idle_timeout = effective_opts.idle_timeout or 5000
    idle_timer:stop()
    idle_timer:start(
      current_idle_timeout,
      0,
      vim.schedule_wrap(function()
        idle_timer:stop()
        if vim.b[term.buf] and vim.b[term.buf].aider_busy then
          vim.b[term.buf].aider_busy = false
          set_done()
          vim.b[term.buf].aider_send_opts = nil
          vim.api.nvim_exec_autocmds("User", { pattern = "AiderDone" })
        end
      end)
    )
  end
  local function start_response_timer()
    response_timer:stop()
    response_timer:start(
      response_timeout,
      0,
      vim.schedule_wrap(function()
        response_timer:stop()
        set_still_waiting()
      end)
    )
  end

  local function user_trigger_processing()
    if not vim.b[term.buf].aider_busy then
      vim.b[term.buf].aider_busy = true
      got_first_chunk = false
      idle_timer:stop()
      start_response_timer()
      set_processing()
    end
  end

  vim.keymap.set("t", "<CR>", function()
    user_trigger_processing()
    return "<CR>"
  end, { buffer = term.buf, expr = true, silent = true })

  --------------------------------------------------------------------------
  -- jobstart callbacks                                                    --
  --------------------------------------------------------------------------
  local job_opts = {
    cwd = opts.cwd,
    env = opts.env,
    term = true,

    on_stdout = function(job_id, data, _)
      if data[1] and data[1] ~= "" then
        if not got_first_chunk then
          got_first_chunk = true
          response_timer:stop()
        end
        reset_idle_timer()
      end
      if opts.on_stdout then
        opts.on_stdout(job_id, data, "stdout")
      end
    end,

    on_stderr = function(job_id, data, _)
      if data[1] and data[1] ~= "" then
        if not got_first_chunk then
          got_first_chunk = true
          response_timer:stop()
        end
        reset_idle_timer()
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR, { title = "nvim-aider" })
      end
      if opts.on_stderr then
        opts.on_stderr(job_id, data, "stderr")
      end
    end,

    on_exit = function(job_id, code, _)
      idle_timer:stop()
      response_timer:stop()
      if term and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        -- vim.api.nvim_buf_set_var(term.buf, "aider_alive", false)
        vim.b[term.buf].aider_alive = false
        if code ~= 0 then
          set_error(code)
        else
          set_done()
        end
        vim.b[term.buf].aider_send_opts = nil
      end
      vim.api.nvim_exec_autocmds("User", { pattern = "AiderExit", data = { code = code } })
      if opts.on_exit then
        opts.on_exit(job_id, code, "exit")
      end
    end,
  }

  vim.api.nvim_buf_set_var(term.buf, "aider_alive", true)
  vim.api.nvim_buf_set_var(term.buf, "aider_busy", false)

  local function jobstart(cmd, jopts)
    local fn = vim.fn.jobstart
    if vim.fn.termopen then
      jopts.term = nil
      fn = vim.fn.termopen
    end
    return fn(cmd, vim.tbl_isempty(jopts) and vim.empty_dict() or jopts)
  end

  vim.api.nvim_buf_call(term.buf, function()
    term.job_id = jobstart(cmd or Base.parse(opts.shell or vim.o.shell), job_opts)
  end)

  --------------------------------------------------------------------------
  -- public helper: send_with_timer                                        --
  --------------------------------------------------------------------------
  function term:send_with_timer(payload, send_opts)
    if not M.is_running(self) then
      vim.notify(
        "Aider process is not running – reopen the terminal.",
        vim.log.levels.ERROR,
        { title = "nvim-aider" }
      )
      return
    end
    vim.b[self.buf].aider_busy = true
    vim.b[self.buf].aider_send_opts = send_opts
    set_processing()
    got_first_chunk = false
    idle_timer:stop()
    start_response_timer()
    vim.api.nvim_chan_send(self.job_id, payload)
  end

  vim.cmd("noh")
  return term
end

return M
