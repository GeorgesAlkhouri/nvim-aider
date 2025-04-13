local M = {}

local commands = {
  health = {
    doc = "Run nvim-aider health check",
    impl = function()
      require("nvim_aider.api").health_check()
    end,
  },
  toggle = {
    doc = "Toggle Aider terminal",
    impl = function()
      require("nvim_aider.api").toggle_terminal()
    end,
  },
  send = {
    doc = "Send text to Aider terminal",
    impl = function(input)
      require("nvim_aider.api").send_to_terminal(input)
    end,
  },
  command = {
    doc = "Send Aider slash command to Aider terminal",
    impl = function()
      require("nvim_aider.api").open_command_picker()
    end,
  },
  buffer = {
    doc = "Send buffer to Aider terminal",
    impl = function()
      require("nvim_aider.api").send_buffer_with_prompt()
    end,
    subcommands = {
      diagnostics = {
        doc = "Send current buffer diagnostics to Aider terminal",
        impl = function()
          require("nvim_aider.api").send_diagnostics_with_prompt()
        end,
      },
    },
  },
  add = {
    doc = "Add current file to Aider session",
    impl = function()
      require("nvim_aider.api").add_current_file()
    end,
    subcommands = {
      readonly = {
        doc = "Add current file as read-only to Aider session",
        impl = function()
          require("nvim_aider.api").add_read_only_file()
        end,
      },
    },
  },
  drop = {
    doc = "Remove current file from Aider session",
    impl = function()
      require("nvim_aider.api").drop_current_file()
    end,
  },
}

function M._load_command(args)
  local cmd = args[1]
  if commands[cmd] then
    if commands[cmd].subcommands then
      local subcmd = args[2]
      if subcmd and commands[cmd].subcommands[subcmd] then
        table.remove(args, 1)
        table.remove(args, 1)
        commands[cmd].subcommands[subcmd].impl(unpack(args))
        return
      elseif subcmd then
        vim.notify("Invalid Aider subcommand: " .. subcmd .. " for command: " .. cmd, vim.log.levels.INFO)
        return
      end
    end
    table.remove(args, 1)
    commands[cmd].impl(unpack(args))
  else
    vim.notify("Invalid Aider command: " .. (cmd or ""), vim.log.levels.INFO)
  end
end

function M._menu()
  local items = {}
  local longest_cmd = 0
  -- Capture the original buffer before creating the picker
  -- This is critical because the picker will change the active buffer context
  local original_buf = vim.api.nvim_get_current_buf()

  -- Create wrapped command table to preserve buffer context
  -- This wrapping is necessary because:
  -- 1. The picker interface creates its own buffer
  -- 2. Commands executed from the picker would otherwise use the picker's buffer
  -- 3. File operations need to reference the user's original editing buffer
  local wrapped_commands = {}
  for name, cmd in pairs(commands) do
    local new_cmd = vim.deepcopy(cmd)
    -- Wrap the command implementation to restore original buffer context
    new_cmd.impl = function()
      -- Switch back to the original buffer before execution
      vim.api.nvim_set_current_buf(original_buf)
      -- Execute the original command implementation
      cmd.impl()
    end

    -- Wrap subcommands using the same buffer preservation logic
    if new_cmd.subcommands then
      for subname, subcmd in pairs(new_cmd.subcommands) do
        subcmd.impl = function()
          vim.api.nvim_set_current_buf(original_buf)
          cmd.subcommands[subname].impl()
        end
      end
    end

    wrapped_commands[name] = new_cmd
  end

  -- Build picker items and calculate longest command name
  for name, cmd in pairs(wrapped_commands) do
    -- For commands with subcommands, show them as parent items
    table.insert(items, {
      text = name,
      description = cmd.doc,
      category = "command",
      name = name,
      subcommands = cmd.subcommands,
    })
    longest_cmd = math.max(longest_cmd, #name)

    -- Add subcommands if they exist
    if cmd.subcommands then
      for subname, subcmd in pairs(cmd.subcommands) do
        local full_name = name .. " " .. subname
        table.insert(items, {
          text = full_name,
          description = subcmd.doc,
          category = "command",
          name = name,
          subname = subname,
          parent = name,
        })
        longest_cmd = math.max(longest_cmd, #full_name)
      end
    end
  end

  longest_cmd = longest_cmd + 2 -- Add padding

  -- Create and show the snacks picker
  require("snacks.picker")({
    items = items,
    layout = require("nvim_aider.config").options.picker_cfg,
    format = function(item)
      local display_text = item.text
      if item.parent then
        display_text = " > " .. display_text:sub(#item.parent + 2)
      end
      return {
        { ("%-" .. longest_cmd .. "s"):format(display_text), "Function" },
        { " " .. item.description, "Comment" },
      }
    end,
    prompt = "Aider Commands > ",
    confirm = function(picker_instance, item)
      if item then
        if item.subname then
          -- Execute subcommand
          wrapped_commands[item.name].subcommands[item.subname].impl()
        elseif wrapped_commands[item.name] then
          -- Execute main command
          wrapped_commands[item.name].impl()
        end
      end
      picker_instance:close()
    end,
  })
end

M.commands = commands

return M
