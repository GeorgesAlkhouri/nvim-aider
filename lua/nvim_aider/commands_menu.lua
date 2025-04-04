local M = {}

local commands = {
  health = {
    doc = "Run health check",
    impl = function()
      require("nvim_aider.api").health_check()
    end,
  },
  toggle = {
    doc = "Toggle aider terminal",
    impl = function()
      require("nvim_aider.api").toggle_terminal()
    end,
  },
  send = {
    doc = "Send text to aider terminal",
    impl = function(input)
      require("nvim_aider.api").send_to_terminal(input)
    end,
  },
  command = {
    doc = "Quick send Aider command",
    impl = function()
      require("nvim_aider.api").open_command_picker()
    end,
  },
  buffer = {
    doc = "Send buffer with prompt",
    impl = function()
      require("nvim_aider.api").send_buffer_with_prompt()
    end,
  },
  add = {
    doc = "Add current file to session",
    impl = function()
      require("nvim_aider.api").add_current_file()
    end,
  },
  drop = {
    doc = "Remove current file from session",
    impl = function()
      require("nvim_aider.api").drop_current_file()
    end,
  },
  readonly = {
    doc = "Add current file as read-only",
    impl = function()
      require("nvim_aider.api").add_read_only_file()
    end,
  },
}

function M._load_command(args)
  local cmd = args[1]
  if commands[cmd] then
    table.remove(args, 1)
    commands[cmd].impl(unpack(args))
  else
    vim.notify("Invalid Aider command: " .. (cmd or ""), vim.log.levels.INFO)
  end
end

function M._menu()
  local items = {}
  local longest_cmd = 0

  -- Build picker items and calculate longest command name
  for name, cmd in pairs(commands) do
    table.insert(items, {
      text = name,
      description = cmd.doc,
      category = "command",
      name = name,
    })
    longest_cmd = math.max(longest_cmd, #name)
  end

  longest_cmd = longest_cmd + 2 -- Add padding

  -- Create and show the snacks picker
  require("snacks.picker")({
    items = items,
    layout = require("nvim_aider.config").options.picker_cfg,
    format = function(item)
      return {
        { ("%-" .. longest_cmd .. "s"):format(item.text), "Function" },
        { " " .. item.description, "Comment" },
      }
    end,
    prompt = "Aider Commands > ",
    confirm = function(picker_instance, item)
      if item and commands[item.text] then
        commands[item.text].impl()
      end
      picker_instance:close()
    end,
  })
end

M.commands = commands

return M
