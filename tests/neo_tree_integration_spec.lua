local mock = require("luassert.mock")
local spy = require("luassert.spy")

describe("neo-tree Integration", function()
  local neo_tree_commands = {
    nvim_aider_add = function(_) end,
    nvim_aider_add_visual = function(_) end,
    nvim_aider_drop = function(_) end,
    nvim_aider_drop_visual = function(_) end,
    nvim_aider_add_read_only = function(_) end,
    nvim_aider_add_read_only_visual = function(_) end,
  }

  local mock_state = {
    tree = {
      get_node = function() end,
    },
  }

  local terminal_mock
  local notify_spy

  before_each(function()
    package.loaded["neo-tree.sources.filesystem.commands"] = neo_tree_commands
    terminal_mock = mock(require("nvim_aider.terminal"), true)
    notify_spy = spy.on(vim, "notify")

    -- Initialize the plugin's Neo-tree integration
    local neo_tree = require("nvim_aider.neo_tree")
    neo_tree.setup({
      window = {
        mappings = {},
      },
      filesystem = {},
    })
    -- Initialize the main plugin
    require("nvim_aider").setup()
  end)

  after_each(function()
    mock.revert(terminal_mock)
    notify_spy:revert()
    package.loaded["neo-tree.sources.filesystem.commands"] = nil
  end)

  describe("single file operations", function()
    it("should add file from neo-tree when valid node selected", function()
      mock_state.tree.get_node = function()
        return { path = "/absolute/path/to/test/file.lua" }
      end

      neo_tree_commands.nvim_aider_add(mock_state)
      assert.stub(terminal_mock.command).was_called_with("/add", "/absolute/path/to/test/file.lua")
    end)

    it("should drop file from neo-tree when valid node selected", function()
      mock_state.tree.get_node = function()
        return { path = "/path/to/test/file.lua" }
      end

      neo_tree_commands.nvim_aider_drop(mock_state)
      assert.stub(terminal_mock.command).was_called_with("/drop", "/path/to/test/file.lua")
    end)

    it("should add read-only file from neo-tree when valid node selected", function()
      mock_state.tree.get_node = function()
        return { path = "/path/to/readonly/file.lua" }
      end

      neo_tree_commands.nvim_aider_add_read_only(mock_state)
      assert.stub(terminal_mock.command).was_called_with("/read-only", "/path/to/readonly/file.lua")
    end)
  end)

  describe("multi-file operations (visual mode)", function()
    it("should add multiple files from neo-tree selection", function()
      local mock_nodes = {
        { name = "file1.lua", path = "/path/to/file1.lua" },
        { name = "file2.lua", path = "/path/to/file2.lua" },
      }

      neo_tree_commands.nvim_aider_add_visual(nil, mock_nodes)
      assert.stub(terminal_mock.command).was_called_with("/add", "/path/to/file1.lua /path/to/file2.lua")
    end)

    it("should drop multiple files from neo-tree selection", function()
      local mock_nodes = {
        { name = "file1.lua", path = "/path/to/file1.lua" },
        { name = "file2.lua", path = "/path/to/file2.lua" },
      }

      neo_tree_commands.nvim_aider_drop_visual(nil, mock_nodes)
      assert.stub(terminal_mock.command).was_called_with("/drop", "/path/to/file1.lua /path/to/file2.lua")
    end)

    it("should add multiple read-only files from neo-tree selection", function()
      local mock_nodes = {
        { name = "readonly1.lua", path = "/path/to/readonly1.lua" },
        { name = "readonly2.lua", path = "/path/to/readonly2.lua" },
      }

      neo_tree_commands.nvim_aider_add_read_only_visual(nil, mock_nodes)
      assert
        .stub(terminal_mock.command)
        .was_called_with("/read-only", "/path/to/readonly1.lua /path/to/readonly2.lua")
    end)
  end)

  describe("error handling", function()
    -- it("should handle missing node path", function()
    --   mock_state.tree.get_node = function()
    --     return { name = "invalid_node" }
    --   end
    --
    --   -- Should check for notification title
    --   neo_tree_commands.nvim_aider_add(mock_state)
    --   assert
    --     .spy(notify_spy)
    --     .was_called_with("No valid file selected in neo-tree", vim.log.levels.WARN, { title = "nvim-aider" })
    -- end)

    it("should handle API changes gracefully", function()
      package.loaded["neo-tree.sources.filesystem.commands"] = nil
      local neo_tree_setup = require("nvim_aider.neo_tree").setup
      neo_tree_setup({ window = { mappings = {} } })
      assert.spy(notify_spy).was_called_with(
        "[nvim-aider] Neo-tree integration requires neo-tree.nvim version 3.30+.\n"
          .. "Please update Neo-tree or check compatibility if using a custom setup.\n"
          .. "GitHub: https://github.com/nvim-neo-tree/neo-tree.nvim",
        vim.log.levels.ERROR,
        { title = "nvim-aider dependency error" }
      )
    end)

    it("should handle empty visual selection", function()
      neo_tree_commands.nvim_aider_add_visual(nil, {})
      assert.stub(terminal_mock.command).was_not_called()
    end)

    -- it("should handle node retrieval errors", function()
    --   mock_state.tree.get_node = function()
    --     error("test error")
    --   end
    --
    --   neo_tree_commands.nvim_aider_add(mock_state)
    --   assert.spy(notify_spy).was_called()
    --   local call_args = notify_spy.calls[1]
    --   assert.truthy(call_args.vals[1]:match("Error getting node:"))
    --   assert.equals(vim.log.levels.ERROR, call_args.vals[2])
    --   assert.equals("nvim-aider", call_args.vals[3].title)
    -- end)
  end)
end)
