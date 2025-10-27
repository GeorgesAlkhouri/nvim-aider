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

-- forward-declarations so we can reuse them in both toggle() and get()
local function open_override(cmd, opts) end

-- ----------------------------------------------------------------------- --
-- create a table that proxies every unknown key to the original module    --
local M = setmetatable({}, {
  __index = Base, -- standard single-inheritance idiom :contentReference[oaicite:3]{index=3}
  __call = function(_, ...)
    return M.toggle(...)
  end,
})

-- ----------------------------------------------------------------------- --
-- Public helpers                                                          --
function M.is_running(term)
  -- Prefer the terminal buffer's built-in job id; fall back to legacy self.job_id
  if not (term and term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
    return false
  end
  local jid = vim.b[term.buf] and vim.b[term.buf].terminal_job_id or term.job_id
  return jid and vim.fn.jobwait({ jid }, 0)[1] == -1 or false
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
-- IMPORTANT: In newer snacks.nvim, registration of terminals happens
-- inside Base.open(). To stay compatible (and satisfy the new assert in
-- Base.get()), we delegate creation to Base.open() and *decorate* the
-- returned terminal (keymaps, timers, send_with_timer, notifications),
-- instead of constructing the window and job ourselves.
function open_override(cmd, opts)
  -- Keep incoming opts intact for user-level behavior, but avoid recursive override
  -- NOTE: tbl_deep_extend with { override = nil } does NOT delete the key.
  -- Use deepcopy and explicitly clear it so Base.open() won't call us again.
  local opts2 = vim.deepcopy(opts or {})
  opts2.override = false -- prevent Base.open from invoking open_override again

  -- Delegate terminal creation & registration to Snacks (this ensures terminals[tid] is set)
  local term = Base.open(cmd, opts2)

  -- From here on, we decorate the terminal with our UX features
  -- (Processing / Still waiting / Done notifications + timers)

  --------------------------------------------------------------------------
  -- TIMER STATE                                                           --
  --------------------------------------------------------------------------
  local response_timeout = opts2.response_timeout or 30000
  local idle_timeout = opts2.idle_timeout or 5000
  local idle_timer = uv.new_timer()
  local response_timer = uv.new_timer()
  local got_first_chunk = false

  --------------------------------------------------------------------------
  -- notification state per buffer                                         --
  --------------------------------------------------------------------------
  vim.b[term.buf].aider_notif = nil
  vim.b[term.buf].aider_alive = true
  vim.b[term.buf].aider_busy = false

  local function get_effective_opts()
    local send_opts = vim.b[term.buf] and vim.b[term.buf].aider_send_opts or {}
    return vim.tbl_deep_extend("force", {}, opts2, send_opts)
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
  local function stop_all()
    pcall(function()
      idle_timer:stop()
    end)
    pcall(function()
      response_timer:stop()
    end)
  end

  local function reset_idle_timer()
    local effective_opts = get_effective_opts()
    local current_idle_timeout = effective_opts.idle_timeout or idle_timeout
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

  private_start_response_timer = nil
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

  -- Detect terminal output: attach to buffer changes (acts as our stdout signal)
  -- We rely on Base.open() using termopen(), which writes to the terminal buffer.
  vim.api.nvim_buf_attach(term.buf, false, {
    on_lines = function()
      -- First chunk: stop the "still waiting" timer
      if not got_first_chunk then
        got_first_chunk = true
        response_timer:stop()
      end
      -- Any output while busy: reset idle timer
      if vim.b[term.buf].aider_busy then
        reset_idle_timer()
      end
    end,
    on_detach = function()
      stop_all()
    end,
  })

  -- Double safety: also stop timers on close/wipeout and report exit code once
  term:on("TermClose", function()
    stop_all()
    -- If we can read the status, show notification (mirrors original behavior)
    if type(vim.v.event) == "table" and vim.v.event.status ~= nil then
      if vim.v.event.status ~= 0 then
        set_error(vim.v.event.status)
      else
        set_done()
      end
    end
    vim.b[term.buf].aider_send_opts = nil
    vim.api.nvim_exec_autocmds("User", { pattern = "AiderExit", data = { code = vim.v.event and vim.v.event.status } })
  end, { buf = true })

  term:on("BufWipeout", function()
    stop_all()
  end, { buf = true })

  -- Keep the convenient "press <CR> means we're submitting" behavior
  vim.keymap.set("t", "<CR>", function()
    user_trigger_processing()
    return "<CR>"
  end, { buffer = term.buf, expr = true, silent = true })

  --------------------------------------------------------------------------
  -- jobstart callbacks                                                    --
  --------------------------------------------------------------------------
  -- NOTE: We now let Snacks/Base.open() own jobstart/termopen. Instead of
  -- passing on_stdout/on_stderr here, we approximate "output observed"
  -- by listening to terminal buffer changes (see nvim_buf_attach above).
  -- This keeps us compatible with Snacks' new registration & assert logic.

  -- legacy flags (kept for compatibility / tests)
  vim.api.nvim_buf_set_var(term.buf, "aider_alive", true)
  vim.api.nvim_buf_set_var(term.buf, "aider_busy", false)

  --------------------------------------------------------------------------
  -- public helper: send_with_timer                                        --
  --------------------------------------------------------------------------
  function term:send_with_timer(payload, send_opts)
    local jid = vim.b[self.buf] and vim.b[self.buf].terminal_job_id or self.job_id
    if not (jid and vim.fn.jobwait({ jid }, 0)[1] == -1) then
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
    vim.api.nvim_chan_send(jid, payload)
  end

  vim.cmd("noh")
  return term
end

return M
