describe("Terminal bracketed paste tests", function()
  local terminal = require("nvim_aider.terminal")

  -- Save the real reference to vim.api
  local original_api = vim.api
  local sent_messages = {}

  before_each(function()
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
    -- Restore the original vim.api
    vim.api = original_api
  end)

  it("uses bracketed pasting for multi-line text", function()
    local input_text = "Hello\nmultiline\nSample"
    terminal.send(input_text, {}, true)

    local expected = "\27[200~" .. input_text .. "\27[201~\r"
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
