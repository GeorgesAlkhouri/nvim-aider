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
      "AiderQuickReadOnlyFile",
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

    -- Mock vim.fn.expand and git root handling
    vim.fn = setmetatable({
      expand = function(path)
        local expanded = "/fake/git/root/some/file.lua"
        print(string.format("Mock expand(%s) => %s", path, expanded))
        return expanded
      end,
    }, {
      __index = original_vim_fn,
    })

    -- Override git root function to return consistent path
    utils.get_git_root = function()
      return "/fake/git/root"
    end

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

describe("read-only command", function()
  local original_terminal = require("nvim_aider.terminal")
  local commands = require("nvim_aider.commands")
  local mock_terminal = {
    command_calls = {},
    command = function(self, cmd, arg)
      table.insert(self.command_calls, { cmd = cmd, arg = arg })
    end,
  }

  before_each(function()
    -- Reset the mock calls
    mock_terminal.command_calls = {}
    -- Replace terminal with our mock
    package.loaded["nvim_aider.terminal"] = mock_terminal
  end)

  after_each(function()
    -- Restore original terminal
    package.loaded["nvim_aider.terminal"] = original_terminal
  end)

  it("sends read-only command with correct filepath", function()
    -- Create a test buffer and set it as current
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)
    
    -- Mock the buffer name and ensure it's a normal buffer
    vim.api.nvim_buf_set_name(bufnr, "/fake/git/root/some/file.lua")
    vim.bo[bufnr].buftype = ""
    
    -- Set up the plugin
    nvim_aider.setup()
    
    -- Execute the command directly
    vim.cmd('AiderQuickReadOnlyFile')
    -- Give a small delay for the command to execute
    vim.wait(100)

    -- Get and verify the relative path
    local rel_path = "some/file.lua"  -- This is what we expect based on our mock setup
    
    -- Verify the terminal command was called correctly
    assert.equals(1, #mock_terminal.command_calls, "Expected one terminal command call")
    assert.equals(commands["read-only"].value, mock_terminal.command_calls[1].cmd)
    assert.equals(rel_path, mock_terminal.command_calls[1].arg, 
        string.format("Expected arg '%s' but got '%s'", rel_path, mock_terminal.command_calls[1].arg))
  end)

  it("shows notification for invalid buffer", function()
    -- Create a terminal buffer
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)
    
    -- Set buffer type safely
    pcall(function()
      vim.api.nvim_buf_set_option(bufnr, 'buftype', 'terminal')
    end)
    
    local notifications = {}
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end
    
    -- Set up the plugin
    nvim_aider.setup()
    
    -- Execute the command
    local ok, _ = pcall(vim.api.nvim_command, 'AiderQuickReadOnlyFile')
    assert(ok, "Command should execute without error")

    -- Verify notifications
    assert.equals(1, #notifications)
    assert.equals("No valid file in current buffer", notifications[1].msg)
    assert.equals(vim.log.levels.INFO, notifications[1].level)
    assert.equals(0, #mock_terminal.command_calls)
  end)
end)
