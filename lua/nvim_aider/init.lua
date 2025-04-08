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
end

return M
