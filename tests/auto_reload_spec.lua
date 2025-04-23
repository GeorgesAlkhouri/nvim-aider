local config = require("nvim_aider.config")
local nvim_aider = require("nvim_aider")
local spy = require("luassert.spy")

describe("Auto Reload Feature", function()
  local original_autoread
  local cmd_spy
  local notify_once_spy
  local temp_file
  local bufnr

  before_each(function()
    -- Store original autoread setting
    original_autoread = vim.o.autoread

    -- Create spies
    -- FIX: other spec files will fail if activated
    -- cmd_spy = spy.on(vim, "cmd")
    notify_once_spy = spy.on(vim, "notify_once") -- Keep this spy

    -- Create a temporary file and buffer for testing
    temp_file = vim.fn.tempname()
    bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufnr, temp_file)
    vim.api.nvim_set_current_buf(bufnr)
    vim.fn.writefile({ "initial content" }, temp_file) -- Write initial content

    -- Reset config options to defaults before each test
    config.options = vim.deepcopy(config.defaults)
    -- Clear any existing autocommands from previous tests
    pcall(vim.api.nvim_del_augroup_by_name, "AiderAutoRefresh")
  end)

  after_each(function()
    -- Restore original settings and spies
    vim.o.autoread = original_autoread
    -- Use pcall for restore in case spies weren't created due to earlier errors
    -- cmd_spy:revert()
    pcall(spy.restore, notify_once_spy) -- Restore this spy too

    -- Clean up buffer and temporary file
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    vim.fn.delete(temp_file)

    -- Clear the autocommand group again
    pcall(vim.api.nvim_del_augroup_by_name, "AiderAutoRefresh")
    package.loaded["nvim_aider"] = nil -- Force reload if needed
    package.loaded["nvim_aider.config"] = nil -- Force config reload
  end)

  -- it("should trigger checktime when auto_reload and autoread are true", function()
  --   -- Setup with auto_reload enabled and ensure autoread is true
  --   vim.o.autoread = true
  --   nvim_aider.setup({ auto_reload = true })
  --
  --   -- Simulate external file change
  --   vim.fn.writefile({ "modified content" }, temp_file)
  --
  --   -- Trigger an event that should call checktime
  --   vim.api.nvim_command("doautocmd <nomodeline> FocusGained")
  --
  --   -- Allow time for async operations if any (though checktime is sync)
  --   vim.wait(50)
  --
  --   -- Assert checktime was called
  --   assert.spy(cmd_spy).was_called_with("checktime")
  -- end)

  -- it("should NOT trigger checktime when auto_reload is false", function()
  --   -- Setup with auto_reload disabled, but autoread true
  --   vim.o.autoread = true
  --   nvim_aider.setup({ auto_reload = false })
  --
  --   -- Simulate external file change
  --   vim.fn.writefile({ "modified content" }, temp_file)
  --
  --   -- Trigger an event
  --   vim.api.nvim_command("doautocmd <nomodeline> FocusGained")
  --   vim.wait(50)
  --
  --   -- Assert checktime was NOT called
  --   assert.spy(cmd_spy).was_not_called_with("checktime")
  --   -- Verify the autocommand group wasn't created
  --   local groups = vim.api.nvim_get_augroup_by_name("AiderAutoRefresh")
  --   assert.is_nil(groups)
  -- end)

  it("should NOT trigger checktime when autoread is false", function()
    -- Setup with auto_reload enabled, but autoread false
    vim.o.autoread = false
    nvim_aider.setup({ auto_reload = true })

    -- Simulate external file change
    vim.fn.writefile({ "modified content" }, temp_file)

    -- Trigger an event
    vim.api.nvim_command("doautocmd <nomodeline> FocusGained")
    vim.wait(50)

    -- Assert checktime was NOT called by our autocommand
    -- (Note: Other plugins might still call checktime, so we check our group wasn't created effectively)
    local groups = vim.api.nvim_get_augroup_by_name("AiderAutoRefresh")
    assert.is_nil(groups) -- Setup should not create the group if autoread is off
  end)

  it("should show notification if autoread is false but auto_reload is true", function()
    -- Setup with auto_reload enabled and autoread false
    vim.o.autoread = false
    nvim_aider.setup({ auto_reload = true })

    -- Assert notification was shown
    assert.spy(notify_once_spy).was_called()
    -- Check the specific message content
    local calls = notify_once_spy.calls
    assert.is_not_nil(calls[1], "notify_once should have been called")
    assert.is_not_nil(calls[1].vals, "notify_once call should have values")
    assert.is_not_nil(calls[1].vals[1], "notify_once message should not be nil")
    -- Use string.find to match the literal start of the message, including non-breaking hyphens
    local expected_start = "nvim‑aider: auto‑reload disabled" -- NOTE: These are non-breaking hyphens
    assert.truthy(
      string.find(calls[1].vals[1], expected_start, 1, true), -- Use plain find for literal match
      "Notification message did not match expected start. Got: " .. tostring(calls[1].vals[1])
    )
    assert.equals(vim.log.levels.WARN, calls[1].vals[2])
  end)

  it("should NOT show notification if autoread is true and auto_reload is true", function()
    -- Setup with auto_reload enabled and autoread true
    vim.o.autoread = true
    nvim_aider.setup({ auto_reload = true })

    -- Assert notification was NOT shown
    assert.spy(notify_once_spy).was_not_called()
  end)

  it("should NOT show notification if auto_reload is false", function()
    -- Setup with auto_reload disabled (autoread state doesn't matter here)
    vim.o.autoread = false
    nvim_aider.setup({ auto_reload = false })
    assert.spy(notify_once_spy).was_not_called()

    vim.o.autoread = true
    nvim_aider.setup({ auto_reload = false })
    assert.spy(notify_once_spy).was_not_called()
  end)
end)
