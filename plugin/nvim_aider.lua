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

    -- Complete subcommands when typing main command
    if line:match("^Aider%s+%w*$") then
      return vim
        .iter(vim.tbl_keys(cmds))
        :filter(function(key)
          return key:find(arg_lead) == 1
        end)
        :totable()
    end

    return {}
  end,
})

vim.api.nvim_create_user_command("AiderHealth", function()
  require("nvim_aider.api").health_check()
end, { desc = "Run :checkhealth nvim_aider" })

vim.api.nvim_create_user_command("AiderTerminalToggle", function()
  require("nvim_aider.api").toggle_terminal()
end, {})

vim.api.nvim_create_user_command("AiderTerminalSend", function(args)
  require("nvim_aider.api").send_to_terminal(args.args)
end, { nargs = "?", range = true, desc = "Send text to Aider terminal" })

vim.api.nvim_create_user_command("AiderQuickSendCommand", function()
  require("nvim_aider.api").open_command_picker()
end, { desc = "Quick send Aider command" })

vim.api.nvim_create_user_command("AiderQuickSendBuffer", function()
  require("nvim_aider.api").send_buffer_with_prompt()
end, {})

vim.api.nvim_create_user_command("AiderQuickAddFile", function()
  require("nvim_aider.api").add_current_file()
end, {})

vim.api.nvim_create_user_command("AiderQuickDropFile", function()
  require("nvim_aider.api").drop_current_file()
end, {})

vim.api.nvim_create_user_command("AiderQuickReadOnlyFile", function()
  require("nvim_aider.api").add_read_only_file()
end, {})

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
