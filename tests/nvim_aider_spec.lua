local status, nvim_aider = pcall(require, "nvim_aider")
local utils = require("nvim_aider.utils")

describe("nvim_aider", function()
  it("imports successfully", function()
    assert(status, "nvim_aider module should load")
  end)
  it("calls setup without arguments", function()
    -- Ensure that calling setup without arguments does not error
    local ok, err = pcall(function()
      nvim_aider.setup()
    end)
    assert(ok, "Expected setup() without arguments to not raise an error, but got: " .. (err or ""))

    -- Check that the user commands were created
    local user_commands = vim.api.nvim_get_commands({})
    local expected_commands = {
      "AiderTerminalToggle",
      "AiderTerminalSend",
      "AiderQuickSendCommand",
      "AiderQuickSendBuffer",
      "AiderQuickAddFile",
      "AiderQuickDropFile",
    }
    for _, cmd in ipairs(expected_commands) do
      assert(user_commands[cmd], "Expected command '" .. cmd .. "' to be registered after setup()")
    end
  end)
end)

describe("utils", function()
  local original_io_popen = io.popen
  local original_vim_fn = vim.fn
  local original_vim_bo = vim.bo

  before_each(function()
    -- Mock io.popen for git root tests
    io.popen = function(cmd)
      if cmd == "git rev-parse --show-toplevel 2>/dev/null" then
        return {
          read = function()
            return "/fake/git/root\n"
          end,
          close = function() end,
        }
      end
      return original_io_popen(cmd)
    end

    -- Mock vim.fn.expand
    vim.fn = setmetatable({
      expand = function(path)
        return "/fake/git/root/some/file.lua"
      end,
    }, {
      __index = original_vim_fn,
    })

    -- Mock vim.bo
    vim.bo = setmetatable({
      buftype = "",
    }, {
      __index = original_vim_bo,
    })
  end)

  after_each(function()
    io.popen = original_io_popen
    vim.fn = original_vim_fn
    vim.bo = original_vim_bo
  end)

  it("gets relative path correctly", function()
    local rel_path = utils.get_relative_path()
    assert.equals("some/file.lua", rel_path)
  end)

  it("returns nil for special buffer types", function()
    vim.bo.buftype = "terminal"
    local rel_path = utils.get_relative_path()
    assert.is_nil(rel_path)
  end)

  it("returns nil when not in git repo", function()
    io.popen = function()
      return {
        read = function()
          return nil
        end,
        close = function() end,
      }
    end
    local rel_path = utils.get_relative_path()
    assert.is_nil(rel_path)
  end)
end)
