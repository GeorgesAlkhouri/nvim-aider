local M = {}

--- Converts a Neovim diagnostic object into a compact text line format.
--- Format: SEVERITY|LOCATION|SOURCE|CODE|MESSAGE
--- LOCATION uses 1-based indexing for readability in the output string.
---@param diag vim.Diagnostic A single diagnostic object
---@return string The formatted diagnostic line
function M.format_single_diagnostic(diag)
  -- 1. Get Severity String (use names like ERROR, WARN)
  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }
  local severity_str = severity_map[diag.severity] or "UNKNOWN"

  -- 2. Format Location String (L{line+1}:C{col+1} or L{line+1}:C{col+1}-L{end_line+1}:C{end_col+1})
  local location_str = string.format("L%d:C%d", diag.lnum + 1, diag.col + 1)
  if diag.end_lnum ~= nil and diag.end_col ~= nil and diag.end_lnum >= diag.lnum then
    if diag.end_lnum > diag.lnum or diag.end_col > diag.col then
      location_str = location_str .. string.format("-L%d:C%d", diag.end_lnum + 1, diag.end_col + 1)
    end
  end

  -- 3. Get Source (handle nil)
  local source_str = diag.source or ""

  -- 4. Get Code (handle nil and convert numbers)
  local code_str = ""
  if diag.code ~= nil then
    code_str = tostring(diag.code)
  end

  -- 5. Get Message (handle nil and escape newlines/delimiter)
  local message_str = diag.message or ""
  message_str = string.gsub(message_str, "\n", "\\n")
  message_str = string.gsub(message_str, "|", "\\|")

  -- 6. Combine parts with '|' delimiter
  local parts = { severity_str, location_str, source_str, code_str, message_str }
  return table.concat(parts, "|")
end

--- Formats a table of diagnostics into a single multi-line string.
--- Each line represents one diagnostic in the compact text format.
---@param diagnostics_table vim.Diagnostic[] A list of diagnostic objects.
---@return string The formatted multi-line string.
function M.format_diagnostics(diagnostics_table)
  local formatted_lines = {}
  for _, diag in ipairs(diagnostics_table) do
    local formatted_line = M.format_single_diagnostic(diag)
    table.insert(formatted_lines, formatted_line)
  end
  return table.concat(formatted_lines, "\n")
end

return M
