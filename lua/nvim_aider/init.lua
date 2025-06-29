local M = {}

M.config = require("nvim_aider.config")
M.api = require("nvim_aider.api")

-- Session tracking for avoiding duplicate operations
local session = require("nvim_aider.session")

local deprecation_shown = false

setmetatable(M, {
  __index = function(tbl, key)
    if key == "terminal" then
      if not deprecation_shown then
        vim.notify(
          "[nvim_aider] 'nvim_aider.terminal' is deprecated and will be removed in a future release. Please use 'nvim_aider.api' instead.",
          vim.log.levels.WARN
        )
        deprecation_shown = true
      end
      return require("nvim_aider.terminal")
    end

    return rawget(tbl, key)
  end,
})

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)

  if M.config.options.auto_reload then
    if not vim.o.autoread then
      vim.notify_once(
        "nvim‑aider: auto‑reload disabled because the 'autoread' option is off.\n"
          .. "Run  :set autoread  (or add it to your init) to enable live‑reload, "
          .. "or set  require('aider').setup{ auto_reload = false }  to silence this notice.",
        vim.log.levels.WARN,
        { title = "nvim‑aider" }
      )
    else
      -- Autocommand group to avoid stacking duplicates on reload
      local grp = vim.api.nvim_create_augroup("AiderAutoRefresh", { clear = true })

      -- Trigger :checktime on the events that matter
      vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" }, {
        group = grp,
        pattern = "*",
        callback = function()
          -- Don’t interfere while editing a command line or in terminal‑insert mode
          if vim.fn.mode():match("[ciR!t]") == nil and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
          end
        end,
        desc = "Reload buffer if the underlying file was changed by Aider or anything else",
      })
    end
  end

  -- Auto-manage context: automatically add/remove buffers from aider session
  if M.config.options.auto_manage_context then
    local context_grp = vim.api.nvim_create_augroup("AiderAutoContext", { clear = true })
    local utils = require("nvim_aider.utils")
    local terminal = require("nvim_aider.terminal")

    -- Add buffer when it's opened/read
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      group = context_grp,
      callback = function(ev)
        local bufnr = ev.buf
        if utils.is_valid_buffer(bufnr, M.config.options.ignore_buffers) then
          -- Check if aider terminal is open
          if terminal.is_running() then
            local filepath = vim.api.nvim_buf_get_name(bufnr)
            if filepath ~= "" and not session.is_file_in_session(filepath) then
              -- Use a small delay to ensure the buffer is fully loaded
              vim.defer_fn(function()
                M.api.add_file(filepath)
                session.add_file(filepath)
              end, 100)
            end
          end
        end
      end,
      desc = "Auto-add new buffers to aider session",
    })

    -- Remove buffer when it's deleted
    vim.api.nvim_create_autocmd("BufDelete", {
      group = context_grp,
      callback = function(ev)
        local bufnr = ev.buf
        if utils.is_valid_buffer(bufnr, M.config.options.ignore_buffers) then
          -- Check if aider terminal is open
          if terminal.is_running() then
            local filepath = vim.api.nvim_buf_get_name(bufnr)
            if filepath ~= "" and session.is_file_in_session(filepath) then
              M.api.drop_file(filepath)
              session.remove_file(filepath)
            end
          end
        end
      end,
      desc = "Auto-remove deleted buffers from aider session",
    })
  end
end

return M
