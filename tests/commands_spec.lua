local _, nvim_aider = pcall(require, "nvim_aider")

describe("Command Setup", function()
  before_each(function()
    package.loaded["nvim_aider"] = nil
    nvim_aider = require("nvim_aider")
  end)

  after_each(function()
    for cmd in pairs(vim.api.nvim_get_commands({})) do
      vim.api.nvim_del_user_command(cmd)
    end
  end)


  it("executes health check without error", function()
    nvim_aider.setup()
    local health_check_ok = pcall(function() nvim_aider.api.health_check() end)
    assert(health_check_ok, "health_check() should execute without error")
  end)
end)
