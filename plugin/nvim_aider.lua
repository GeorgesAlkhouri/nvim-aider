vim.api.nvim_create_user_command("Aider", function(opts)
  local commands_menu = require("nvim_aider.commands_menu")

  if #opts.fargs == 0 then
    commands_menu._menu()
  else
    commands_menu._load_command(opts.fargs)
  end
end, {
  desc = "Aider command interface",
  nargs = "*",
  complete = function(arg_lead, line)
    local cmds = require("nvim_aider.commands_menu").commands
    local parts = vim.split(line:gsub("%s+", " "), " ")

    -- Complete subcommands when typing after main command
    if #parts >= 2 then
      local main_cmd = parts[2]
      if cmds[main_cmd] and cmds[main_cmd].subcommands then
        return vim
          .iter(vim.tbl_keys(cmds[main_cmd].subcommands))
          :filter(function(key)
            return key:find(arg_lead) == 1
          end)
          :totable()
      end
    end

    -- Complete main commands
    return vim
      .iter(vim.tbl_keys(cmds))
      :filter(function(key)
        return key:find(arg_lead) == 1
      end)
      :totable()
  end,
})

-- Track which deprecation warnings have been shown
local deprecated_shown = {}

-- Create a wrapper function for deprecated commands
local function create_deprecated_handler(cmd, replacement, handler)
  return function(opts)
    if not deprecated_shown[cmd] then
      vim.notify(
        ("`%s` is deprecated and will be removed in future versions - use `%s` instead"):format(cmd, replacement),
        vim.log.levels.WARN,
        { title = "nvim-aider" }
      )
      deprecated_shown[cmd] = true
    end
    handler(opts)
  end
end

vim.api.nvim_create_user_command(
  "AiderHealth",
  create_deprecated_handler("AiderHealth", "Aider health", function()
    require("nvim_aider.api").health_check()
  end),
  { desc = "Run nvim-aider health check" }
)

vim.api.nvim_create_user_command(
  "AiderTerminalToggle",
  create_deprecated_handler("AiderTerminalToggle", "Aider toggle", function()
    require("nvim_aider.api").toggle_terminal()
  end),
  { desc = "Toggle Aider terminal" }
)

vim.api.nvim_create_user_command(
  "AiderTerminalSend",
  create_deprecated_handler("AiderTerminalSend", "Aider send", function(args)
    require("nvim_aider.api").send_to_terminal(args.args)
  end),
  { nargs = "?", range = true, desc = "Send text to Aider terminal" }
)

vim.api.nvim_create_user_command(
  "AiderQuickSendCommand",
  create_deprecated_handler("AiderQuickSendCommand", "Aider command", function()
    require("nvim_aider.api").open_command_picker()
  end),
  { desc = "Send Aider slash command to Aider terminal" }
)

vim.api.nvim_create_user_command(
  "AiderQuickSendBuffer",
  create_deprecated_handler("AiderQuickSendBuffer", "Aider buffer", function()
    require("nvim_aider.api").send_buffer_with_prompt()
  end),
  { desc = "Send buffer to Aider terminal" }
)

vim.api.nvim_create_user_command(
  "AiderQuickAddFile",
  create_deprecated_handler("AiderQuickAddFile", "Aider add", function()
    require("nvim_aider.api").add_current_file()
  end),
  { desc = "Add current file to Aider session" }
)

vim.api.nvim_create_user_command(
  "AiderQuickReadOnlyFile",
  create_deprecated_handler("AiderQuickReadOnlyFile", "Aider add readonly", function()
    require("nvim_aider.api").add_read_only_file()
  end),
  { desc = "Add current file as read-only to Aider session" }
)

-- Add nvim-tree integration commands if available
local ok, _ = pcall(require, "nvim-tree")
if ok then
  vim.api.nvim_create_user_command("AiderTreeAddReadOnlyFile", function()
    require("nvim_aider.tree").add_read_only_file_from_tree()
  end, {
    desc = "Add read-only file from nvim-tree to Aider chat",
  })

  vim.api.nvim_create_user_command("AiderTreeAddFile", function()
    require("nvim_aider.tree").add_file_from_tree()
  end, {
    desc = "Add file from nvim-tree to Aider chat",
  })

  vim.api.nvim_create_user_command("AiderTreeDropFile", function()
    require("nvim_aider.tree").drop_file_from_tree()
  end, {
    desc = "Drop file from nvim-tree from Aider chat",
  })
end
