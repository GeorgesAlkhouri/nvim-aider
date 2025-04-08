local M = {}

M.config = require("nvim_aider.config")
M.terminal = setmetatable({}, {
  __index = function(_, key)
    vim.notify(
      '[nvim_aider] require("nvim_aider").terminal is deprecated and will be removed soon.',
      vim.log.levels.WARN
    )
    return require("nvim_aider.terminal")[key]
  end,
})
M.api = require("nvim_aider.api")

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)
end

return M
