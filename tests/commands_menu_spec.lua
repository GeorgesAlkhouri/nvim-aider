local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("Commands Menu", function()
  local commands_menu
  local api_mock
  local notify_spy
  local picker_mock
  local mock_picker_instance

  before_each(function()
    package.loaded["nvim_aider.commands_menu"] = nil
    package.loaded["nvim_aider.api"] = nil

    -- Mock API module
    api_mock = {
      health_check = stub.new(),
      toggle_terminal = stub.new(),
      send_to_terminal = stub.new(),
      open_command_picker = stub.new(),
      send_buffer_with_prompt = stub.new(),
      add_current_file = stub.new(),
      add_read_only_file = stub.new(),
      drop_current_file = stub.new(),
    }

    package.loaded["nvim_aider.api"] = api_mock
    commands_menu = require("nvim_aider.commands_menu")

    -- Mock picker and notifications
    picker_mock = mock(require("nvim_aider.picker"), true)
    mock_picker_instance = { close = spy.new() }
    picker_mock.create.returns(mock_picker_instance)
    notify_spy = spy.on(vim, "notify")
  end)

  after_each(function()
    mock.revert(picker_mock)
    package.loaded["nvim_aider.commands_menu"] = nil
    package.loaded["nvim_aider.api"] = nil
  end)

  describe("Command Registration", function()
    it("should have all top-level commands", function()
      local expected = {
        "health",
        "toggle",
        "send",
        "command",
        "buffer",
        "add",
        "drop",
      }
      -- Check that the keys match regardless of order
      local expected_set = {}
      for _, v in ipairs(expected) do
        expected_set[v] = true
      end

      local actual_set = {}
      for _, v in ipairs(vim.tbl_keys(commands_menu.commands)) do
        actual_set[v] = true
      end

      assert.same(expected_set, actual_set)
    end)

    it("should have add subcommands", function()
      assert.truthy(commands_menu.commands.add.subcommands.readonly)
    end)
  end)

  describe("Command Execution", function()
    it("should execute top-level commands", function()
      commands_menu._load_command({ "health" })
      assert.stub(api_mock.health_check).was_called()

      commands_menu._load_command({ "toggle" })
      assert.stub(api_mock.toggle_terminal).was_called()
    end)

    it("should execute subcommands", function()
      commands_menu._load_command({ "add", "readonly" })
      assert.stub(api_mock.add_read_only_file).was_called()
    end)

    it("should handle invalid commands", function()
      commands_menu._load_command({ "invalid_command" })
      assert.spy(notify_spy).was_called_with("Invalid Aider command: invalid_command", vim.log.levels.INFO)
    end)

    it("should handle invalid subcommands", function()
      commands_menu._load_command({ "add", "invalid_sub" })
      assert
        .spy(notify_spy)
        .was_called_with("Invalid Aider subcommand: invalid_sub for command: add", vim.log.levels.INFO)
    end)
  end)

  describe("Input Handling", function()
    it("should handle send command with input", function()
      stub(vim.ui, "input", function(_, cb)
        cb("test input")
      end)

      commands_menu._load_command({ "send", "test input" })
      assert.stub(api_mock.send_to_terminal).was_called_with("test input")
    end)

    it("should handle empty send input", function()
      stub(vim.ui, "input", function(_, cb)
        cb("")
      end)

      commands_menu._load_command({ "send" })
      assert.stub(api_mock.send_to_terminal).was_called_with(nil)
    end)
  end)
end)
