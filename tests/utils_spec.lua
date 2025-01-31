describe("Utility Functions", function()
  local utils = require("nvim_aider.utils")
  local original_popen
  local original_expand

  before_each(function()
    original_popen = io.popen
    original_expand = vim.fn.expand

    io.popen = function(cmd)
      return cmd:find("git")
          and {
            read = function()
              return "/fake/git/root\n"
            end,
            close = function() end,
          }
        or original_popen(cmd)
    end

    vim.fn.expand = function()
      return "/fake/git/root/some/file.lua"
    end
  end)

  after_each(function()
    io.popen = original_popen
    vim.fn.expand = original_expand

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end)

  it("gets absolute path correctly", function()
    local abs_path = utils.get_absolute_path()
    assert.equals("/fake/git/root/some/file.lua", abs_path)
  end)

  it("returns nil for special buffer types", function()
    -- Create an unlisted terminal buffer for testing
    -- We need a real terminal buffer since 'buftype=terminal' can't be set manually
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.fn.termopen("echo 'test'")
    vim.api.nvim_set_current_buf(bufnr)
    local abs_path = utils.get_absolute_path()
    assert.is_nil(abs_path)
  end)

  it("returns nil for empty buffer", function()
    -- Override the mock to simulate empty buffer
    vim.fn = setmetatable({
      expand = function(path)
        return ""
      end,
    }, {
      __index = original_vim_fn,
    })
    local abs_path = utils.get_absolute_path()
    assert.is_nil(abs_path)
  end)
end)
