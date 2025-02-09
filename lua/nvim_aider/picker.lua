---@class nvim_aider.picker
local M = {}
local config = require("nvim_aider.config")

---@param opts? nvim_aider.Config
---@param confirm? fun(picker: snacks.Picker, item: table)
function M.create(opts, confirm)
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  -- Build items from commands
  local items = {}
  local longest_cmd = 0
  for cmd_name, cmd_data in pairs(require("nvim_aider.commands")) do
    table.insert(items, {
      text = cmd_data.value,
      description = cmd_data.description,
      category = cmd_data.category,
      name = cmd_name,
    })
    longest_cmd = math.max(longest_cmd, #cmd_data.value)
  end
  longest_cmd = longest_cmd + 2

  return require("snacks.picker")({
    items = items,
    layout = opts.picker_cfg,
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { ("%-" .. longest_cmd .. "s"):format(item.text), "Function" }
      ret[#ret + 1] = { " " .. item.description, "Comment" }
      return ret
    end,

    confirm = confirm,
    prompt = "Aider Commands > ",
  })
end

return M
