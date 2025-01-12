local mock = require("luassert.mock")
local stub = require("luassert.stub")

describe("telescope integration", function()
  local nvim_aider
  local telescope_mock
  local actions_mock
  local action_state_mock
  local builtin_mock
  local terminal_stub

  before_each(function()
    -- Create mock modules
    actions_mock = mock({
      close = function() end,
    })
    package.loaded["telescope.actions"] = actions_mock

    action_state_mock = mock({
      get_current_picker = function() end,
      get_selected_entry = function() end,
    })
    package.loaded["telescope.actions.state"] = action_state_mock

    builtin_mock = mock({
      find_files = function() end,
    })
    package.loaded["telescope.builtin"] = builtin_mock

    telescope_mock = mock({
      register_extension = function() end,
    })
    package.loaded["telescope"] = telescope_mock

    -- Load nvim_aider after mocks are in place
    nvim_aider = require("nvim_aider")
    terminal_stub = stub(require("nvim_aider.terminal"), "command")

    nvim_aider.setup()
  end)

  after_each(function()
    -- Clean up mocks and stubs
    mock.revert(actions_mock)
    mock.revert(action_state_mock)
    mock.revert(builtin_mock)
    mock.revert(telescope_mock)
    package.loaded["telescope.actions"] = nil
    package.loaded["telescope.actions.state"] = nil
    package.loaded["telescope.builtin"] = nil
    package.loaded["telescope"] = nil
    terminal_stub:revert()
  end)

  describe("aider_add", function()
    it("should handle single file selection", function()
      -- Mock picker and entry
      local picker = {
        get_multi_selection = function()
          return {}
        end,
      }

      -- Setup mocks to return our test data
      stub(action_state_mock, "get_current_picker", function()
        return picker
      end)
      stub(action_state_mock, "get_selected_entry", function()
        return { path = "/test/file.txt" }
      end)

      -- Get the extension
      local extension = require("nvim_aider.telescope").setup_extension()

      -- Call the add function with default options
      extension.exports.aider_add({})

      -- Get the mapping function
      local opts = builtin_mock.find_files.calls[1].vals[1]
      local map = {
        i = {},
        n = {},
      }
      opts.attach_mappings(nil, map)

      -- Actually call the mapped function
      map.i["<CR>"]()

      -- Verify terminal command was called correctly
      assert.stub(terminal_stub).was.called_with(require("nvim_aider.commands").add.value, "file.txt")
    end)

    it("should handle multiple file selection", function()
      -- Mock picker with multiple selections
      local picker = {
        get_multi_selection = function()
          return {
            { path = "/test/file1.txt" },
            { path = "/test/file2.txt" },
          }
        end,
      }

      stub(action_state_mock, "get_current_picker", function()
        return picker
      end)

      -- Get the extension
      local extension = require("nvim_aider.telescope").setup_extension()

      -- Call the add function
      extension.exports.aider_add({})

      -- Get the mapping function
      local opts = builtin_mock.find_files.calls[1].vals[1]
      local map = {
        i = {},
        n = {},
      }
      opts.attach_mappings(nil, map)

      -- Actually call the mapped function
      map.i["<CR>"]()

      -- Verify terminal command was called with multiple files
      assert.stub(terminal_stub).was.called_with(require("nvim_aider.commands").add.value, "file1.txt file2.txt")
    end)
  end)

  describe("aider_drop", function()
    it("should handle single file drop", function()
      -- Mock picker and entry
      local picker = {
        get_multi_selection = function()
          return {}
        end,
      }

      stub(action_state_mock, "get_current_picker", function()
        return picker
      end)
      stub(action_state_mock, "get_selected_entry", function()
        return { path = "/test/file.txt" }
      end)

      -- Get the extension
      local extension = require("nvim_aider.telescope").setup_extension()

      -- Call the drop function
      extension.exports.aider_drop({})

      -- Get the mapping function
      local opts = builtin_mock.find_files.calls[1].vals[1]
      local map = {
        i = {},
        n = {},
      }
      opts.attach_mappings(nil, map)

      -- Actually call the mapped function
      map.i["<CR>"]()

      -- Verify terminal command was called correctly
      assert.stub(terminal_stub).was.called_with(require("nvim_aider.commands").drop.value, "file.txt")
    end)
  end)
end)
