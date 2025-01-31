local mock = require("luassert.mock")
local nvim_aider = require("nvim_aider")
local spy = require("luassert.spy")

describe("Read-only Commands", function()
  local original_terminal
  local mock_terminal

  before_each(function()
    original_terminal = require("nvim_aider.terminal")
    mock_terminal = mock(original_terminal, true)
    nvim_aider.setup()
  end)

  after_each(function()
    mock.revert(mock_terminal)
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
    vim.cmd("AiderQuickReadOnlyFile")
    -- Give a small delay for the command to execute
    vim.wait(100)

    -- Get and verify the relative path
    local rel_path = "some/file.lua" -- This is what we expect based on our mock setup

    -- Verify the terminal command was called correctly
    assert.equals(1, #mock_terminal.command_calls, "Expected one terminal command call")
    assert.equals(commands["read-only"].value, mock_terminal.command_calls[1].cmd)
    assert.equals(
      rel_path,
      mock_terminal.command_calls[1].arg,
      string.format("Expected arg '%s' but got '%s'", rel_path, mock_terminal.command_calls[1].arg)
    )
  end)

  it("shows notification for invalid buffer", function()
    -- Create a terminal buffer
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)

    -- Set buffer type safely
    pcall(function()
      vim.api.nvim_buf_set_option(bufnr, "buftype", "terminal")
    end)

    local notify_spy = spy.on(vim, "notify")

    -- Set up the plugin
    nvim_aider.setup()

    -- Execute the command
    local ok, _ = pcall(vim.api.nvim_command, "AiderQuickReadOnlyFile")
    assert(ok, "Command should execute without error")

    local ok, _ = pcall(vim.api.nvim_command, "AiderQuickReadOnlyFile")
    assert(ok, "Command should execute without error")

    -- Verify notifications
    assert.spy(notify_spy).was_called_with("No valid file in current buffer", vim.log.levels.INFO)
    assert.is_nil(mock_terminal.command_calls, "Expected no terminal commands to be called")
  end)
end)
