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

---Check if a buffer is valid for aider context
---@param bufnr number Buffer number
---@param ignore_patterns? string[] List of patterns to ignore
---@return boolean valid True if buffer should be included in aider context
function M.is_valid_buffer(bufnr, ignore_patterns)
  ignore_patterns = ignore_patterns or {}

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  -- Ignore special buffers and directories
  if buftype ~= ""
     or filetype == "NvimTree"
     or filetype == "neo-tree"
     or filetype == "AiderConsole"
     or not vim.fn.filereadable(bufname) == 1
     or vim.fn.isdirectory(bufname) == 1 then
    return false
  end

  -- Check against ignore patterns
  for _, pattern in ipairs(ignore_patterns) do
    if bufname:match(pattern) then
      return false
    end
  end

  return true
end

---Get all valid buffers for aider context
---@param ignore_patterns? string[] List of patterns to ignore
---@return string[] filepaths List of absolute file paths
function M.get_valid_buffers(ignore_patterns)
  local buffers = vim.api.nvim_list_bufs()
  local filepaths = {}

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and M.is_valid_buffer(buf, ignore_patterns) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname ~= "" then
        table.insert(filepaths, vim.fn.fnamemodify(bufname, ":p"))
      end
    end
  end

  return filepaths
end

return M
