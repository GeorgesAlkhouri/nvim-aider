local M = {}

---Gets the git root directory
---@return string|nil
local function get_git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  if result then
    -- Trim whitespace and newlines
    return result:gsub("^%s*(.-)%s*$", "%1")
  end
  return nil
end

---Gets the path relative to git root directory
---@return string|nil path The path relative to git root, or nil if:
---                      - The buffer is empty
---                      - The buffer has a special type (like terminal or help)
---                      - Not in a git repository
function M.get_relative_path()
  local buftype = vim.bo.buftype
  local filepath = vim.fn.expand("%:p")  -- Get absolute path

  -- Check if buffer is empty or has special buftype
  if filepath == "" or buftype ~= "" then
    return nil
  end

  local git_root = get_git_root()
  if not git_root then
    return nil
  end

  -- Remove git root prefix and any leading slashes
  local rel_path = filepath:gsub("^" .. vim.pesc(git_root) .. "/*", "")
  return rel_path
end

return M
