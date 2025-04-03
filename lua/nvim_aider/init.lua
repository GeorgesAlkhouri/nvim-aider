local M = {}

M.config = require("nvim_aider.config")
M.terminal = require("nvim_aider.terminal")
M.api = require("nvim_aider.api")

---@param opts? nvim_aider.Config
function M.setup(opts)
  M.config.setup(opts)
  require("nvim_aider.tree").setup(opts)
end

return M
