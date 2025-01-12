local stub = require("luassert.stub")

describe("nvim-tree integration", function()
  local nvim_aider
  local nvim_tree_mock
  local notify_stub

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
    -- Stub vim.notify
    notify_stub = stub(vim, "notify")
  end)

  after_each(function()
    -- Remove mock module and restore stubs
    package.loaded["nvim-tree.api"] = nil
    notify_stub:revert()
  end)

  describe("add_file_from_tree", function()
    it("should check if in nvim-tree buffer", function()
      vim.bo.filetype = "not-nvim-tree"
      -- Execute the command directly
      vim.api.nvim_exec2("AiderTreeAddFile", {})

      -- Should show warning
      assert.stub(notify_stub).was.called_with("Not in nvim-tree buffer", vim.log.levels.WARN)
    end)

    it("should handle missing nvim-tree.tree field", function()
      vim.bo.filetype = "NvimTree"
      nvim_tree_mock.tree = nil
      -- Execute the command directly
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

    -- Add other similar tests as needed
  end)
end)
