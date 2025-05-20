---@class nvim_aider.picker
local M = {}
local config = require("nvim_aider.config")

---Create a generic picker
---@param items table The list of items to display in the picker
---@param longest_text_len number The length of the longest item text for formatting
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@param confirm? fun(picker: any, item: table) Callback function when an item is selected (any because it could be snacks or telescope picker)
function M.create_generic(items, longest_text_len, opts, confirm)
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  if opts.picker == "telescope" then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    return pickers.new(opts, {
      prompt_title = "Aider Picker", -- Generic title
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          -- Assuming items have 'text' and 'description' fields
          local display_text = entry.text
          -- Adjust display for subcommands if needed, similar to snacks format
          if entry.parent then
             display_text = " > " .. display_text:sub(#entry.parent + 2)
          end
          return {
            value = entry, -- Store the original item data
            display = string.format("%-" .. longest_text_len .. "s %s", display_text, entry.description or ""), -- Use description if available
            ordinal = entry.text, -- Use item text for sorting
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if confirm then
            -- Pass the original item data to the confirm callback
            -- Pass nil for picker_instance as Telescope closing is handled by actions.close
            confirm(nil, selection.value)
          end
        end)
        return true
      end,
    }):find()
  else -- Default to snacks
    return require("snacks.picker")({
      items = items,
      layout = opts.picker_cfg,
      format = function(item)
        local ret = {}
        local display_text = item.text
        if item.parent then
          display_text = " > " .. display_text:sub(#item.parent + 2)
        end
        ret[#ret + 1] = { ("%-" .. longest_text_len .. "s"):format(display_text), "Function" }
        ret[#ret + 1] = { " " .. (item.description or ""), "Comment" } -- Use description if available
        return ret
      end,
      prompt = "Aider Picker > ", -- Generic prompt
      confirm = confirm,
    })
  end
end

---Create and open the slash command picker
---@param opts? nvim_aider.Config Optional config that will override the base config for this call only
---@param callback? fun(picker: any, item: table) Custom callback handler
function M.open_slash_command_picker(opts, callback)
    local commands_slash = require("nvim_aider.commands_slash")
    local items = {}
    local longest_cmd = 0
    for cmd_name, cmd_data in pairs(commands_slash) do
      table.insert(items, {
        text = cmd_data.value,
        description = cmd_data.description,
        category = cmd_data.category,
        name = cmd_name,
        cmd_data = cmd_data, -- Store original data
      })
      longest_cmd = math.max(longest_cmd, #cmd_data.value)
    end
    longest_cmd = longest_cmd + 2

    local confirm_callback = callback or function(picker_instance, item)
      local terminal = require("nvim_aider.terminal") -- Require here to avoid circular dependency
      local api = require("nvim_aider.api") -- Require here to avoid circular dependency

      if item.category == "input" then
        vim.ui.input({ prompt = "Enter input for `" .. item.text .. "` (empty to skip):" }, function(input)
          if input then
            terminal.command(item.text, input, opts)
          end
        end)
      else
        terminal.command(item.text, nil, opts)
      end
      -- For snacks, picker_instance is provided and needs closing.
      -- For Telescope, picker_instance is nil, and closing is handled by actions.close in create_generic's attach_mappings.
      if picker_instance and picker_instance.close then
          picker_instance:close()
      end
    end

    return M.create_generic(items, longest_cmd, opts, confirm_callback)
end


return M
