local M = {}

local commands = require("nvim_aider.commands")
local terminal = require("nvim_aider.terminal")

M.defaults = {
  window = {
    mappings = {
      ["+"] = {
        "nvim_aider_add",
        desc = "add to aider",
      },
      ["-"] = {
        "nvim_aider_drop",
        desc = "drop from aider",
      },
    },
  },
}

local function check_existing_mappings(mappings)
  local has_add, has_drop = false, false
  for _, mapping in pairs(mappings) do
    if type(mapping) == "table" then
      if mapping[1] == "nvim_aider_add" then
        has_add = true
      end
      if mapping[1] == "nvim_aider_drop" then
        has_drop = true
      end
    end
  end
  return has_add, has_drop
end

function M.setup(opts)
  if not opts then
    vim.notify(
      "[nvim-aider] Neo-tree integration requires passing opts.\n"
        .. "Ensure your Neo-tree config calls:\n"
        .. "require('nvim_aider.neo_tree').setup(opts)",
      vim.log.levels.ERROR,
      { title = "nvim-aider configuration error" }
    )
    return
  end

  -- Check for existing command mappings
  local has_add, has_drop = check_existing_mappings(opts.window and opts.window.mappings or {})

  -- Conditional merging
  local merged = vim.tbl_deep_extend("keep", (opts.window and opts.window.mappings) or {}, {})
  if not has_add then
    merged["+"] = M.defaults.window.mappings["+"]
  end
  if not has_drop then
    merged["-"] = M.defaults.window.mappings["-"]
  end

  opts.window = opts.window or {}
  opts.window.mappings = merged

  local ok, neo_tree_commands = pcall(require, "neo-tree.sources.filesystem.commands")
  if ok then
    local nvim_aider_add = function(state)
      local node = state.tree:get_node()
      terminal.command(commands.add.value, node.path)
    end

    local nvim_aider_add_visual = function(_, selected_nodes)
      local nodeNames = {}
      for _, node in pairs(selected_nodes) do
        table.insert(nodeNames, node.path)
      end
      if #nodeNames > 0 then
        terminal.command(commands.add.value, table.concat(nodeNames, " "))
      end
    end

    local nvim_aider_drop = function(state)
      local node = state.tree:get_node()
      terminal.command(commands.drop.value, node.path)
    end

    local nvim_aider_drop_visual = function(_, selected_nodes)
      local nodeNames = {}
      for _, node in pairs(selected_nodes) do
        table.insert(nodeNames, node.path)
      end
      if #nodeNames > 0 then
        terminal.command(commands.drop.value, table.concat(nodeNames, " "))
      end
    end

    neo_tree_commands.nvim_aider_add = nvim_aider_add
    neo_tree_commands.nvim_aider_add_visual = nvim_aider_add_visual
    neo_tree_commands.nvim_aider_drop = nvim_aider_drop
    neo_tree_commands.nvim_aider_drop_visual = nvim_aider_drop_visual
  else
    vim.notify(
      "[nvim-aider] Neo-tree integration requires neo-tree.nvim version 3.30+.\n"
        .. "Please update Neo-tree or check compatibility if using a custom setup.\n"
        .. "GitHub: https://github.com/nvim-neo-tree/neo-tree.nvim",
      vim.log.levels.ERROR,
      { title = "nvim-aider dependency error" }
    )
  end
end

return M
