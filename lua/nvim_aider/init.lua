local M = {}

local commands, terminal, config, picker, utils, tree_module

local function safe_require(module_name, error_message)
  local ok, mod = pcall(require, module_name)
  if not ok then
    vim.notify(error_message, vim.log.levels.ERROR)
    return nil
  end
  return mod
end

commands = safe_require("nvim_aider.commands", "Failed to load nvim_aider.commands")
terminal = safe_require("nvim_aider.terminal", "Failed to load nvim_aider.terminal")
config = safe_require("nvim_aider.config", "Failed to load nvim_aider.config")
picker = safe_require("nvim_aider.ui", "Failed to load nvim_aider.ui")
utils = safe_require("nvim_aider.utils", "Failed to load nvim_aider.utils")

if not utils or not commands or not terminal or not config or not picker then
  return
end

local function handle_file_from_tree(cmd_value)
  if vim.bo.filetype ~= "NvimTree" then
    vim.notify("Not in nvim-tree buffer", vim.log.levels.WARN)
    return
  end

  local ok, nvim_tree_api = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("nvim-tree plugin is not installed", vim.log.levels.ERROR)
    return
  end

  if not nvim_tree_api.tree then
    vim.notify("nvim-tree API has changed - please update the plugin", vim.log.levels.ERROR)
    return
  end

  local ok2, node_or_err = pcall(function()
    return nvim_tree_api.tree.get_node_under_cursor()
  end)

  if not ok2 then
    vim.notify("Error getting node: " .. tostring(node_or_err), vim.log.levels.ERROR)
    return
  end

  local node = node_or_err
  if not node then
    vim.notify("No node found under cursor", vim.log.levels.WARN)
    return
  end

  if not node.absolute_path then
    vim.notify("No valid file selected in nvim-tree", vim.log.levels.WARN)
    return
  end

  local relative_path = vim.fn.fnamemodify(node.absolute_path, ":.")
  terminal.command(cmd_value, relative_path)
end

local function add_file_from_tree()
  handle_file_from_tree(commands.add.value)
end

local function drop_file_from_tree()
  handle_file_from_tree(commands.drop.value)
end

local function setup_tree_integration(opts)
  -- Safely require the tree module
  tree_module = safe_require("nvim_aider.tree", "Failed to load nvim_aider.tree")
  if not tree_module then
    return
  end

  local nvim_tree_ok, _ = pcall(require, "nvim-tree")
  if nvim_tree_ok then
    vim.api.nvim_create_user_command("AiderTreeAddFile", add_file_from_tree, {
      desc = "Add file from nvim-tree to Aider chat",
    })

    vim.api.nvim_create_user_command("AiderTreeDropFile", drop_file_from_tree, {
      desc = "Drop file from nvim-tree from Aider chat",
    })
  end
end

---@param opts? nvim_aider.Config
function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_user_command("AiderHealth", function()
    vim.cmd([[checkhealth nvim_aider]])
  end, { desc = "Run :checkhealth nvim_aider" })

  vim.api.nvim_create_user_command("AiderTerminalToggle", function()
    terminal.toggle()
  end, { desc = "Toggle Aider terminal" })

  vim.api.nvim_create_user_command("AiderTerminalSend", function(args)
    local mode = vim.fn.mode()
    if vim.tbl_contains({ "v", "V", "" }, mode) then
      -- Visual mode behavior
      local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
      local selected_text = table.concat(lines, "\n")
      local file_type = vim.bo.filetype
      if file_type == "" then
        file_type = "text"
      end
      vim.ui.input({ prompt = "Add a prompt to your selection (empty to skip):" }, function(input)
        if input ~= nil then
          if input ~= "" then
            selected_text = selected_text .. "\n> " .. input
          end
          terminal.send(selected_text)
        end
      end)
    else
      -- Normal mode behavior
      if args.args == "" then
        vim.ui.input({ prompt = "Send to Aider: " }, function(input)
          if input then
            terminal.send(input)
          end
        end)
      else
        terminal.send(args.args)
      end
    end
  end, { nargs = "?", range = true, desc = "Send text to Aider terminal" })

  vim.api.nvim_create_user_command("AiderQuickSendCommand", function()
    picker(require("telescope.themes").get_dropdown({}), function(selection)
      if selection.category == "input" then
        vim.ui.input({ prompt = "Enter input for `" .. selection.value .. "` (empty to skip):" }, function(input)
          if input then
            terminal.command(selection.value, input)
          end
        end)
      else
        terminal.command(selection.value)
      end
    end)
  end, { desc = "Quickly send a command to Aider" })

  vim.api.nvim_create_user_command("AiderQuickSendBuffer", function()
    local selected_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local file_type = vim.bo.filetype
    if file_type == "" then
      file_type = "text"
    end
    vim.ui.input({ prompt = "Add a prompt to your buffer (empty to skip):" }, function(input)
      if input ~= nil then
        if input ~= "" then
          selected_text = selected_text .. "\n> " .. input
        end
        terminal.send(selected_text)
      end
    end)
  end, { desc = "Quickly send the entire buffer to Aider" })

  vim.api.nvim_create_user_command("AiderQuickAddFile", function()
    local filepath = utils.get_absolute_path()
    if filepath == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    else
      terminal.command(commands.add.value, filepath)
    end
  end, { desc = "Quickly add the current file to Aider" })

  vim.api.nvim_create_user_command("AiderQuickDropFile", function()
    local filepath = utils.get_absolute_path()
    if filepath == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    else
      terminal.command(commands.drop.value, filepath)
    end
  end, { desc = "Quickly drop the current file from Aider" })

  vim.api.nvim_create_user_command("AiderQuickReadOnlyFile", function()
    local filepath = utils.get_absolute_path()
    if filepath == nil then
      vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    else
      terminal.command(commands["read-only"].value, filepath)
    end
  end, { desc = "Quickly add the current file to Aider as read-only" })

  setup_tree_integration(opts)
end

return M
