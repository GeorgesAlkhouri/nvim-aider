local M = {}

M.config = require("nvim_aider.config")
M.api = require("nvim_aider.api")

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
end

return M
