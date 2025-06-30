local M = {}

-- Track files that are currently in aider session to avoid duplicate operations
local session_files = {}

---Add a file to the session tracking
---@param filepath string Absolute path to the file
function M.add_file(filepath)
  if filepath then
    session_files[filepath] = true
  end
end

---Remove a file from the session tracking
---@param filepath string Absolute path to the file
function M.remove_file(filepath)
  if filepath then
    session_files[filepath] = nil
  end
end

---Check if a file is currently tracked in the session
---@param filepath string Absolute path to the file
---@return boolean is_tracked True if the file is in the session
function M.is_file_in_session(filepath)
  return filepath and session_files[filepath] == true
end

---Clear all tracked files (useful when resetting session)
function M.clear_session()
  session_files = {}
end

---Get all files currently tracked in the session
---@return string[] filepaths List of absolute file paths
function M.get_session_files()
  local files = {}
  for filepath, _ in pairs(session_files) do
    table.insert(files, filepath)
  end
  return files
end

---Initialize session tracking with a list of files
---@param filepaths string[] List of absolute file paths
function M.init_session(filepaths)
  session_files = {}
  for _, filepath in ipairs(filepaths or {}) do
    session_files[filepath] = true
  end
end

return M
