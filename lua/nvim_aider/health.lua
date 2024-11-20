local M = {}
local health = vim.health or require("health")

function M.check()
  health.start("Plugin Dependencies")

  -- Check aider executable
  local aider_exists = vim.fn.executable("aider") == 1
  if aider_exists then
    local version_output = vim.fn.system("aider --version")
    if version_output then
      local version = vim.version.parse(version_output)
      if version then
        health.ok(string.format("aider v%d.%d.%d found", version.major, version.minor, version.patch))
      else
        health.error("Failed to parse aider version")
      end
    else
      health.error("Could not determine aider version")
    end
  else
    health.error("aider executable not found in PATH", {
      "Install with: python -m pip install -U aider-chat",
    })
  end

  -- Snacks plugin check
  local has_snacks = pcall(require, "snacks")
  if has_snacks then
    health.ok("snacks.nvim plugin found")
  else
    health.error("snacks.nvim plugin not found", {
      "Install folke/snacks.nvim using your plugin manager",
    })
  end
end

return M
