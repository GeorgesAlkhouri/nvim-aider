local M = {}

function M.config()
  -- Load required modules
  local commands = require("nvim_aider.commands")
local terminal = require("nvim_aider.terminal")

-- Helper function to handle file selection and command execution
local function handle_selection(prompt_bufnr, command)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(prompt_bufnr)

  -- Get selected entries
  local selections = {}
  local multi_selections = picker:get_multi_selection()
  for _, entry in ipairs(multi_selections) do
    if entry.path then
      local path = vim.fn.fnamemodify(entry.path, ":t")
      table.insert(selections, path)
    end
  end

  -- If no multi-selection, get the currently selected entry
  if #selections == 0 then
    local entry = action_state.get_selected_entry()
    if entry and entry.path then
      local path = vim.fn.fnamemodify(entry.path, ":t")
      table.insert(selections, path)
    end
  end

  -- Close telescope
  actions.close(prompt_bufnr)

  -- Execute command with selected files
  if #selections > 0 then
    terminal.command(command, table.concat(selections, " "))
  end
end

function M.setup_extension()
  return {
    exports = {
      aider_add = function(opts)
        require("telescope.builtin").find_files(vim.tbl_extend("force", {
          attach_mappings = function(prompt_bufnr, map)
            -- Map both Enter and Ctrl-a to add files
            local add_action = function()
              return handle_selection(prompt_bufnr, "/add")
            end
            -- Use proper telescope mapping convention
            map.i["<CR>"] = add_action
            map.n["<CR>"] = add_action
            map.i["<C-a>"] = add_action
            map.n["<C-a>"] = add_action
            return true
          end,
        }, opts or {}))
      end,
      aider_drop = function(opts)
        require("telescope.builtin").find_files(vim.tbl_extend("force", {
          attach_mappings = function(prompt_bufnr, map)
            -- Map both Enter and Ctrl-d to drop files
            local drop_action = function()
              return handle_selection(prompt_bufnr, "/drop")
            end
            -- Use proper telescope mapping convention
            map.i["<CR>"] = drop_action
            map.n["<CR>"] = drop_action
            map.i["<C-d>"] = drop_action
            map.n["<C-d>"] = drop_action
            return true
          end,
        }, opts or {}))
      end,
    },
  }
end

-- Return the module
return M
