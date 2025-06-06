describe("Terminal bracketed paste tests", function()
  local terminal

  -- Save the real reference to vim.api
  local original_api = vim.api
  local sent_messages = {}

  before_each(function()
    -- Reset modules to ensure clean state
    package.loaded["nvim_aider.terminal"] = nil
    package.loaded["nvim_aider.snacks_ext"] = nil
    package.loaded["snacks.terminal"] = nil
    terminal = require("nvim_aider.terminal")

    sent_messages = {}

    -- Create a "proxy" for vim.api:
    --    * unmocked methods go to original_api
    --    * mocked methods override
    vim.api = setmetatable({}, {
      __index = function(_, key)
        return original_api[key]
      end,
      __newindex = function(_, key, value)
        rawset(original_api, key, value)
      end,
    })

    -- Now override only the two methods we need to mock
    vim.api.nvim_buf_get_var = function(_, _)
      -- Return a fake channel job ID
      return 1234
    end

    vim.api.nvim_chan_send = function(_, data)
      -- Capture the data being sent
      table.insert(sent_messages, data)
    end
  end)

  after_each(function()
    -- 1. Close all windows first to break buffer-window associations
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local success = pcall(vim.api.nvim_win_close, win, true)
      if not success then
        vim.schedule(function()
          pcall(vim.api.nvim_win_close, win, true)
        end)
      end
    end

    -- 2. Special handling for terminal buffers
    vim.api.nvim_create_autocmd("TermClose", {
      callback = function(args)
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.schedule(function()
            pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
          end)
        end
      end,
      nested = true,
    })

    -- 3. Buffer cleanup with validation
    vim.schedule(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
          if buftype ~= "terminal" then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end
      end
    end)

    vim.api = original_api
  end)

  it("uses bracketed pasting for multi-line text", function()
    local input_text = "Hello\nmultiline\nSample"
    terminal.send(input_text, {}, true)

    local expected = "\27[200~" .. input_text .. "\27[201~"
    assert.equals(1, #sent_messages, "Should send exactly one message")
    assert.equals(expected, sent_messages[1], "Bracketed paste sequences should wrap the input")
  end)

  it("does NOT use bracketed pasting for single-line text", function()
    local input_text = "Single line text"
    terminal.send(input_text, {}, false)

    local expected = input_text:gsub("\n", " ") .. "\n"
    assert.equals(1, #sent_messages, "Should send exactly one message")
    assert.equals(expected, sent_messages[1], "Single-line text should be sent without bracketed paste")
  end)
end)

describe("Snacks.nvim compatibility tests", function()
  local snacks_ext
  local win_spy
  local spy

  before_each(function()
    spy = require("luassert.spy")
    -- Reset modules
    package.loaded["nvim_aider.snacks_ext"] = nil
    package.loaded["snacks"] = nil
    package.loaded["snacks.terminal"] = nil

    -- Mock snacks
    win_spy = spy.new(function()
      local buf = vim.api.nvim_create_buf(false, true)
      return {
        on = function() end,
        show = function() end,
        close = function() end,
        buf = buf,
      }
    end)
    win_spy.resolve = spy.new(function()
      return { wo = {} }
    end)

    package.loaded["snacks"] = {
      win = win_spy,
    }

    -- Mock snacks.terminal as well, since snacks_ext requires it
    package.loaded["snacks.terminal"] = {
      parse = function(s)
        return { s }
      end,
      toggle = function(cmd, opts)
        if opts.override then
          return opts.override(cmd, opts)
        end
      end,
      get = function(cmd, opts)
        if opts.override then
          return opts.override(cmd, opts)
        end
      end,
    }

    snacks_ext = require("nvim_aider.snacks_ext")
  end)

  after_each(function()
    if spy and spy.revert_all then
      spy.revert_all()
    end
  end)

  it("should call Snacks.win.resolve with correct parameters", function()
    snacks_ext.toggle("my_cmd", {})
    assert.spy(win_spy.resolve).was_called_with("terminal", { position = "float" }, nil, { show = false })
  end)

  it("should call Snacks.win constructor to create a terminal window", function()
    snacks_ext.toggle("my_cmd", {})
    assert.spy(win_spy).was_called()
  end)
end)

describe("Terminal notifications and guards", function()
  local terminal
  local snacks_ext_mock
  local notify_spy
  local spy

  before_each(function()
    spy = require("luassert.spy")
    package.loaded["nvim_aider.terminal"] = nil
    package.loaded["nvim_aider.snacks_ext"] = nil

    snacks_ext_mock = {
      get = function() end,
      is_running = function()
        return true
      end,
    }
    package.loaded["nvim_aider.snacks_ext"] = snacks_ext_mock

    terminal = require("nvim_aider.terminal")
    notify_spy = spy.on(vim, "notify")
  end)

  after_each(function()
    if spy and spy.revert_all then
      spy.revert_all()
    end
    package.loaded["nvim_aider.snacks_ext"] = nil
    package.loaded["nvim_aider.terminal"] = nil
  end)

  it("should notify if terminal is not open", function()
    snacks_ext_mock.get = function()
      return nil
    end
    terminal.send("test")
    assert
      .spy(notify_spy)
      .was_called_with("Open an Aider terminal first ( :Aider toggle ).", vim.log.levels.INFO, { title = "nvim-aider" })
  end)

  it("should notify if process is not running", function()
    local term_mock = {
      buf_valid = function()
        return true
      end,
      job_id = 1,
    }
    snacks_ext_mock.get = function()
      return term_mock
    end
    snacks_ext_mock.is_running = function()
      return false
    end
    terminal.send("test")
    assert
      .spy(notify_spy)
      .was_called_with("Aider process is not running – reopen the terminal.", vim.log.levels.ERROR, { title = "nvim-aider" })
  end)

  it("should notify if terminal is busy", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local term_mock = {
      buf_valid = function()
        return true
      end,
      job_id = 1,
      buf = buf,
    }
    vim.api.nvim_buf_set_var(buf, "aider_busy", true)
    snacks_ext_mock.get = function()
      return term_mock
    end
    snacks_ext_mock.is_running = function()
      return true
    end
    terminal.send("test")
    assert
      .spy(notify_spy)
      .was_called_with("Aider is still processing the previous command…", vim.log.levels.WARN, { title = "nvim-aider" })
    pcall(vim.api.nvim_buf_del_var, buf, "aider_busy")
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end)
