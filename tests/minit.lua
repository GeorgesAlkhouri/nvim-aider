#!/usr/bin/env -S nvim -l

-- setting this env will override all XDG paths
vim.env.LAZY_STDPATH = ".tests"
-- this will install lazy in your stdpath
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Configure plugins
-- local plugins = {
--   "nvim-lua/plenary.nvim",
-- }

-- Setup lazy.nvim
require("lazy.minit").setup({
  -- rocks = {
  --   hererocks = false,
  -- },
  -- -- install = {
  -- --   missing = false,
  -- -- },
  spec = {
    { dir = vim.uv.cwd() },
    "LazyVim/starter",
    {
      "GeorgesAlkhouri/nvim-aider",
      cmd = {
        "AiderTerminalToggle",
      },
      keys = {
        { "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
        { "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
        { "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
        { "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
        { "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
        { "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
      },
      dependencies = {
        "folke/snacks.nvim",
        "nvim-telescope/telescope.nvim",
        --- The below dependencies are optional
        "catppuccin/nvim",
        "nvim-tree/nvim-tree.lua",
      },
      config = true,
    },
  },
})
