local M = {}
local health = vim.health or require("health")

function M.check()
  health.start("Plugin Dependencies")
  local options = require("nvim_aider.config").options
  -- Check aider is executable
  local version_output = vim.fn.systemlist(options.aider_cmd .. " --version")
  if version_output and vim.v.shell_error == 0 then
    local version_str = version_output[#version_output]
    -- Handle potential ANSI codes in version string
    version_str = version_str:gsub("\x1b%[.-m", "")
    -- Try parsing version (might fail if format is unexpected)
    local ok, version = pcall(vim.version.parse, version_str)
    if ok and version then
      health.ok(string.format("aider v%d.%d.%d found", version.major, version.minor, version.patch))
    else
      health.warn("Could not parse aider version from output: " .. version_str)
    end
  else
    health.error("Could not determine aider version for '" .. options.aider_cmd .. "'.")
  end

  -- Snacks plugin check
  local has_snacks = pcall(require, "snacks")
  if has_snacks then
    health.ok("snacks.nvim plugin found")
  else
    health.error("snacks.nvim plugin not found", {
      "Install folke/snacks.nvim using your plugin manager",
    })
  end

  health.start("Optional Features")

  -- Auto Reload checks
  if options.auto_reload then
    if not vim.o.autoread then
      health.warn("auto_reload enabled, but 'autoread' is off.", {
        "nvim-aider's auto_reload requires Neovim's 'autoread' option.",
        "Run ':set autoread' or add 'vim.o.autoread = true' to your config.",
        "Alternatively, disable auto_reload: require('nvim_aider').setup({ auto_reload = false })",
      })
    else
      health.ok("auto_reload enabled and 'autoread' is set.")
    end

    -- Check focus events needed for auto_reload
    -- FocusGained exists and not in tmux OR in tmux and ttymouse is set
    local ok_focus = (vim.fn.exists("#FocusGained") == 1 and vim.fn.exists("$TMUX") == 0)
      or (os.getenv("TMUX") and vim.fn.exists("&ttymouse") == 1 and vim.o.ttymouse ~= "")
    if not ok_focus then
      health.warn("auto_reload enabled, but focus events may not be detected.", {
        "Focus events trigger ':checktime' for auto_reload.",
        "If using tmux, ensure 'set -g focus-events on' is in tmux.conf and 'ttymouse' is set in Neovim.",
        "If not using tmux, ensure your terminal supports FocusGained/FocusLost events.",
        "See ':checkhealth provider' and search for 'clipboard' section which discusses focus.",
        "Auto-reload might be unreliable without focus events.",
      })
    else
      health.ok("Focus events seem configured correctly for auto_reload.")
    end
  else
    health.info("auto_reload disabled.")
  end

  -- Check clipboard support
  if vim.fn.has("clipboard") == 1 then
    health.ok("System clipboard support (optional)")
  else
    health.info("No system clipboard support (optional)")
  end

  -- Catppuccin plugin check
  local has_catppuccin = pcall(require, "catppuccin")
  if has_catppuccin then
    health.ok("catppuccin plugin found (optional theme integration)")
  else
    health.info("catppuccin plugin not found (optional)")
  end

  -- nvim-tree plugin check
  local has_nvim_tree = pcall(require, "nvim-tree")
  if has_nvim_tree then
    health.ok("nvim-tree plugin found (optional integration)")
  else
    health.info("nvim-tree plugin not found (optional)")
  end

  -- neo-tree plugin check
  local has_neo_tree = pcall(require, "neo-tree")
  if has_neo_tree then
    health.ok("neo-tree plugin found (optional integration)")
  else
    health.info("neo-tree plugin not found (optional)")
  end
end

return M
