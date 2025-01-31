local mock = require("luassert.mock")
local nvim_aider = require("nvim_aider")
local spy = require("luassert.spy")

describe("nvim-tree Integration", function()
  local mock_tree_api = {
    tree = {
      get_node_under_cursor = function()
        return {
          absolute_path = "/path/to/test/file.lua",
        }
      end,
    },
  }

  local terminal_mock
  local notify_spy

  before_each(function()
    package.loaded["nvim-tree.api"] = mock_tree_api
    terminal_mock = mock(require("nvim_aider.terminal"), true)
    notify_spy = spy.on(vim, "notify")
  end)

  after_each(function()
    mock.revert(terminal_mock)
    notify_spy:revert()
    package.loaded["nvim-tree.api"] = nil
  end)

  it("should add file from tree when valid node selected", function()
    nvim_aider.setup()
    -- Set filetype to NvimTree
    vim.bo.filetype = "NvimTree"

    -- Mock vim.fn.fnamemodify to return relative path
    local orig_fnamemodify = vim.fn.fnamemodify
    vim.fn.fnamemodify = function(path, mod)
      if mod == ":." then
        return "path/to/test/file.lua"
      end
      return orig_fnamemodify(path, mod)
    end

    -- Call the add file command
    vim.cmd("AiderTreeAddFile")

    -- Verify terminal command was called with correct path
    assert.stub(terminal_mock.command).was_called_with("/add", "path/to/test/file.lua")

    -- Restore original fnamemodify
    vim.fn.fnamemodify = orig_fnamemodify
  end)

  it("should drop file from tree when valid node selected", function()
    nvim_aider.setup()
    -- Set filetype to NvimTree
    vim.bo.filetype = "NvimTree"

    -- Mock vim.fn.fnamemodify to return relative path
    local orig_fnamemodify = vim.fn.fnamemodify
    vim.fn.fnamemodify = function(path, mod)
      if mod == ":." then
        return "path/to/test/file.lua"
      end
      return orig_fnamemodify(path, mod)
    end

    -- Call the drop file command
    vim.cmd("AiderTreeDropFile")

    -- Verify terminal command was called with correct path
    assert.stub(terminal_mock.command).was_called_with("/drop", "path/to/test/file.lua")

    -- Restore original fnamemodify
    vim.fn.fnamemodify = orig_fnamemodify
  end)

  it("should show warning when not in nvim-tree buffer", function()
    nvim_aider.setup()
    -- Set filetype to something else
    vim.bo.filetype = "lua"

    -- Spy on vim.notify
    local notify_spy = spy.on(vim, "notify")

    -- Call commands
    vim.cmd("AiderTreeAddFile")
    vim.cmd("AiderTreeDropFile")

    -- Verify warnings were shown
    assert.spy(notify_spy).was_called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
    assert.spy(notify_spy).was_called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
  end)

  it("should handle invalid nodes gracefully", function()
    nvim_aider.setup()

    -- Set filetype to NvimTree
    vim.bo.filetype = "NvimTree"

    -- Mock node under cursor to return nil
    mock_tree_api.tree.get_node_under_cursor = function()
      return nil
    end

    -- Spy on vim.notify
    local notify_spy = spy.on(vim, "notify")

    -- Call commands
    vim.cmd("AiderTreeAddFile")
    vim.cmd("AiderTreeDropFile")

    -- Verify warnings were shown
    assert.spy(notify_spy).was_called_with("No node found under cursor", vim.log.levels.WARN)
  end)
end)
