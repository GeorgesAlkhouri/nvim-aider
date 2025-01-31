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

  it("registers required commands", function()
    nvim_aider.setup()

    local registered = vim.api.nvim_get_commands({})
    local expected = {
      "AiderHealth",
      "AiderTerminalToggle",
      "AiderTerminalSend",
      "AiderQuickSendCommand",
      "AiderQuickSendBuffer",
      "AiderQuickAddFile",
      "AiderQuickDropFile",
      "AiderQuickReadOnlyFile",
      "AiderTreeAddFile",
      "AiderTreeDropFile",
    }

    for _, cmd in ipairs(expected) do
      assert(registered[cmd], "Missing command: " .. cmd)
    end
  end)

  it("executes AiderHealth command without error", function()
    nvim_aider.setup()
    local health_cmd_ok = pcall(vim.cmd, "AiderHealth")
    assert(health_cmd_ok, "AiderHealth command should execute without error")
  end)
end)
