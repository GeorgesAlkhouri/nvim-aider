local M = {}

local commands = require("nvim_aider.commands")
local terminal = require("nvim_aider.terminal")

---@param opts? nvim_aider.Config
function M.setup(opts)
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
  end
end

return M
