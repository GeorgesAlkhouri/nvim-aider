local M = {}

local commands = require("nvim_aider.commands")
local terminal = require("nvim_aider.terminal")

local function add_file_from_tree()
  -- Check if we're in a nvim-tree buffer
  if vim.bo.filetype ~= "NvimTree" then
    vim.notify("Not in nvim-tree buffer", vim.log.levels.WARN)
    return
  end

  local ok, nvim_tree = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("nvim-tree plugin is not installed", vim.log.levels.ERROR)
    return
  end

  if not nvim_tree.tree then
    vim.notify("nvim-tree API has changed - please update the plugin", vim.log.levels.ERROR)
    return
  end

  -- Get the node under cursor safely
  local node
  local ok2, result = pcall(function()
    if not nvim_tree.tree then
      error("nvim-tree API has changed - tree field is missing")
    end
    return nvim_tree.tree.get_node_under_cursor()
  end)

  if not ok2 then
    vim.notify("Error getting node: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  node = result
  if not node then
    vim.notify("No node found under cursor", vim.log.levels.WARN)
    return
  end
  if node and node.absolute_path then
    local relative_path = vim.fn.fnamemodify(node.absolute_path, ":.")
    terminal.command(commands.add.value, relative_path)
  else
    vim.notify("No valid file selected in nvim-tree", vim.log.levels.WARN)
  end
end

local function drop_file_from_tree()
  -- Check if we're in a nvim-tree buffer
  if vim.bo.filetype ~= "NvimTree" then
    vim.notify("Not in nvim-tree buffer", vim.log.levels.WARN)
    return
  end

  local ok, nvim_tree = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("nvim-tree plugin is not installed", vim.log.levels.ERROR)
    return
  end

  if not nvim_tree.tree then
    vim.notify("nvim-tree API has changed - please update the plugin", vim.log.levels.ERROR)
    return
  end

  -- Get the node under cursor safely
  local node
  local ok2, result = pcall(function()
    if not nvim_tree.tree then
      error("nvim-tree API has changed - tree field is missing")
    end
    return nvim_tree.tree.get_node_under_cursor()
  end)

  if not ok2 then
    vim.notify("Error getting node: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  node = result
  if not node then
    vim.notify("No node found under cursor", vim.log.levels.WARN)
    return
  end
  if node and node.absolute_path then
    local relative_path = vim.fn.fnamemodify(node.absolute_path, ":.")
    terminal.command(commands.drop.value, relative_path)
  else
    vim.notify("No valid file selected in nvim-tree", vim.log.levels.WARN)
  end
end

function M.setup()
  -- Setup nvim-tree commands
  vim.api.nvim_create_user_command("AiderTreeAddFile", add_file_from_tree, {
    desc = "Add file from nvim-tree to Aider chat",
  })

  vim.api.nvim_create_user_command("AiderTreeDropFile", drop_file_from_tree, {
    desc = "Drop file from nvim-tree from Aider chat",
  })

  -- Set up nvim-tree keymaps if available
  local ok, _ = pcall(require, "nvim-tree")
  if ok then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        vim.keymap.set("n", "<leader>a+", "<cmd>AiderTreeAddFile<cr>", {
          buffer = true,
          desc = "Add file from tree to Aider",
        })
        vim.keymap.set("n", "<leader>a-", "<cmd>AiderTreeDropFile<cr>", {
          buffer = true,
          desc = "Drop file from tree from Aider",
        })
      end,
    })
  end
end

return M
