local M = {}

---Gets the absolute path of the current buffer
---@return string|nil path The absolute path of the current buffer, or nil if:
---                      - The buffer is empty
---                      - The buffer has a special type (like terminal or help)
function M.get_absolute_path()
  local buftype = vim.bo.buftype
  local filepath = vim.fn.expand("%")

  -- Check if the buffer is empty or has a special buftype
  if filepath == "" or buftype ~= "" then
    return nil
  end

  -- Return the absolute path
  return vim.fn.fnamemodify(filepath, ":p")
end

return M
