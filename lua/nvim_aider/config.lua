---@alias nvim_aider.Color string

---@class nvim_aider.Theme: table<string, nvim_aider.Color>
---@field user_input_color nvim_aider.Color
---@field tool_output_color nvim_aider.Color
---@field tool_error_color nvim_aider.Color
---@field tool_warning_color nvim_aider.Color
---@field assistant_output_color nvim_aider.Color
---@field completion_menu_color nvim_aider.Color
---@field completion_menu_bg_color nvim_aider.Color
---@field completion_menu_current_color nvim_aider.Color
---@field completion_menu_current_bg_color nvim_aider.Color

---@class nvim_aider.Config: snacks.terminal.Opts
---@field args? string[]
---@field theme? nvim_aider.Theme
---@field win? snacks.win.Config
---@field picker_cfg? snacks.picker.layout.Config
local M = {}

M.defaults = {
  args = {
    "--no-auto-commits",
    "--pretty",
    "--stream",
  },
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  theme = {
    user_input_color = "#a6da95",
    tool_output_color = "#8aadf4",
    tool_error_color = "#ed8796",
    tool_warning_color = "#eed49f",
    assistant_output_color = "#c6a0f6",
    completion_menu_color = "#cad3f5",
    completion_menu_bg_color = "#24273a",
    completion_menu_current_color = "#181926",
    completion_menu_current_bg_color = "#f4dbd6",
  },
  win = {
    wo = { winbar = "Aider" },
    style = "nvim_aider",
    position = "bottom",
  },
  picker_cfg = {
    preset = "vscode",
  },
}

---@type nvim_aider.Config
M.options = vim.deepcopy(M.defaults)

---@param colors table
local function set_catppuccin_colors(colors)
  M.options.theme = {
    user_input_color = colors.green,
    tool_output_color = colors.blue,
    tool_error_color = colors.red,
    tool_warning_color = colors.yellow,
    assistant_output_color = colors.mauve,
    completion_menu_color = colors.text,
    completion_menu_bg_color = colors.base,
    completion_menu_current_color = colors.crust,
    completion_menu_current_bg_color = colors.pink,
  }
end

---@param opts? nvim_aider.Config
function M.setup(opts)
  local ok, _ = pcall(require, "catppuccin.palettes")
  if ok then
    local current_color = vim.g.colors_name
    local flavour = require("catppuccin").flavour or vim.g.catppuccin_flavour

    if current_color and current_color:match("^catppuccin") and flavour then
      local colors = require("catppuccin.palettes").get_palette()
      set_catppuccin_colors(colors)
    end
    -- Store opts in closure for autocmd to access
    local user_opts = opts
    -- NOTE: the new colors are only applied when aider is restarted
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function(args)
        if args.match:match("^catppuccin") then
          local colors = require("catppuccin.palettes").get_palette()
          set_catppuccin_colors(colors)
          -- Apply user options after setting Catppuccin colors
          M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
        end
      end,
    })
  end

  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
  Snacks.config.style("nvim_aider", {})
  return M.options
end

return M
