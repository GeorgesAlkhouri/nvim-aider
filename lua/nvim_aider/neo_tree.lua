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
  opts.window = opts.window or {}
  opts.window.mappings = opts.window.mappings or {}

  opts.window.mappings = vim.tbl_deep_extend("keep", opts.window.mappings, M.defaults.window.mappings)

  local ok, neo_tree_commands = pcall(require, "neo-tree.sources.filesystem.commands")
  if ok then
    local nvim_aider_add = function(state)
      local node = state.tree:get_node()
      terminal.command(commands.add.value, node.path)
    end

    local nvim_aider_add_visual = function(_, selected_nodes)
      local nodeNames = {}
      for _, node in pairs(selected_nodes) do
        table.insert(nodeNames, node.name)
      end
      terminal.command(commands.add.value, table.concat(nodeNames, " "))
    end

    local nvim_aider_drop = function(state)
      local node = state.tree:get_node()
      terminal.command(commands.drop.value, node.path)
    end

    local nvim_aider_drop_visual = function(_, selected_nodes)
      local nodeNames = {}
      for _, node in pairs(selected_nodes) do
        table.insert(nodeNames, node.name)
      end
      terminal.command(commands.drop.value, table.concat(nodeNames, " "))
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
