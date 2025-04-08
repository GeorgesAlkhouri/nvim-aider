local M = {}

local commands = require("nvim_aider.commands_slash")
local terminal = require("nvim_aider.terminal")

local function handle_file_from_tree(cmd_value)
  -- Ensure we're in a nvim-tree buffer
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

  -- Safely get node under cursor
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

function M.add_read_only_file_from_tree()
  handle_file_from_tree(commands["read-only"].value)
end

function M.add_file_from_tree()
  handle_file_from_tree(commands.add.value)
end

function M.drop_file_from_tree()
  handle_file_from_tree(commands.drop.value)
end

return M
