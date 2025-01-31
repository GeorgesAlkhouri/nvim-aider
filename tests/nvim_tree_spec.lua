local stub = require("luassert.stub")

describe("nvim-tree integration", function()
  local nvim_aider
  local nvim_tree_mock
  local commands = require("nvim_aider.commands")
  local notify_stub
  local terminal_mock

  -- Create mock nvim-tree.api module
  local function create_mock_nvim_tree()
    -- Create a mock module table
    local mock_module = {
      tree = {
        get_node_under_cursor = function() end,
      },
    }
    -- Add to package.loaded so require finds it
    package.loaded["nvim-tree.api"] = mock_module
    return mock_module
  end

  before_each(function()
    -- Create mock module before loading nvim_aider
    nvim_tree_mock = create_mock_nvim_tree()
    nvim_aider = require("nvim_aider")
    nvim_aider.setup()
    -- Create a mock terminal module
    terminal_mock = stub(require("nvim_aider.terminal"), "command")
    package.loaded["nvim_aider.terminal"] = terminal_mock
    notify_stub = stub(vim, "notify", function() end)
  end)

  describe("add_read_only_file_from_tree", function()
    it("should add read-only file from tree when valid node selected", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree.get_node_under_cursor = function()
        return { absolute_path = "/path/to/test/file.lua" }
      end

      -- Mock vim.fn.fnamemodify to return relative path
      local orig_fnamemodify = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(path, mod)
        if mod == ":." then
          return "path/to/test/file.lua"
        end
        return orig_fnamemodify(path, mod)
      end

      vim.api.nvim_exec2("AiderTreeAddReadOnlyFile", {})

      -- Verify terminal command was called with correct path
      assert.spy(terminal_mock).was.called_with("/read-only", "path/to/test/file.lua")

      -- Restore original fnamemodify
      vim.fn.fnamemodify = orig_fnamemodify
    end)

    it("should show warning when not in nvim-tree buffer", function()
      vim.bo.filetype = "not-nvim-tree"
      vim.api.nvim_exec2("AiderTreeAddReadOnlyFile", {})

      assert.stub(notify_stub).was.called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
    end)

    it("should handle invalid nodes gracefully", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree.get_node_under_cursor = function()
        return nil
      end
      vim.api.nvim_exec2("AiderTreeAddReadOnlyFile", {})

      assert.stub(notify_stub).was.called_with("No node found under cursor", vim.log.levels.WARN)
      local notify_call_count = notify_stub.calls and #notify_stub.calls or 0
      print("Notification call count:", notify_call_count)
      assert.equals(1, notify_call_count)
    end)
  end)

  after_each(function()
    -- Remove mock module and restore stubs
    package.loaded["nvim-tree.api"] = nil
    notify_stub:revert()
  end)

  describe("add_file_from_tree", function()
    it("should check if in nvim-tree buffer", function()
      vim.bo.filetype = "not-nvim-tree"
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      -- Should show warning
      assert.stub(notify_stub).was.called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
    end)

    it("should handle missing nvim-tree.tree field", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree = nil
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      assert
        .stub(notify_stub).was
        .called_with("nvim-tree API has changed - please update the plugin", vim.log.levels.ERROR)
    end)

    it("should handle node retrieval errors", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree.get_node_under_cursor = function()
        error("test error")
      end
      -- Execute the command directly
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      -- The actual error includes the file/line info, so we need to check differently
      assert.stub(notify_stub).was_called(1)
      local call_args = notify_stub.calls[1]
      assert.truthy(call_args.vals[1]:match("^Error getting node: .*test error$"))
      assert.equals(vim.log.levels.ERROR, call_args.vals[2])
    end)

    it("should handle nil node", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree.get_node_under_cursor = function()
        return nil
      end
      -- Execute the command directly
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      assert.stub(notify_stub).was.called_with("No node found under cursor", vim.log.levels.WARN)
    end)

    it("should handle node without absolute_path", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree.get_node_under_cursor = function()
        return { name = "test" }
      end
      -- Execute the command directly
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      assert.stub(notify_stub).was.called_with("No valid file selected in nvim-tree", vim.log.levels.WARN)
    end)
  end)

  -- Similar tests for drop_file_from_tree
  describe("drop_file_from_tree", function()
    it("should check if in nvim-tree buffer", function()
      vim.bo.filetype = "not-nvim-tree"
      -- Execute the command directly
      vim.api.nvim_exec2("AiderTreeDropFile", {})

      assert.stub(notify_stub).was.called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
    end)
  end)
end)
