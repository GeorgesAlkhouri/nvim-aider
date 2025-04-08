-- Type definitions
---@alias CommandCategory "input"|"direct"

---@class Command
---@field value string The command string with prefix
---@field description string Description of the command's function
---@field category CommandCategory The category this command belongs to

-- Constants
---@type string
local COMMAND_PREFIX = "/"

-- Command registry
---@type table<string, Command>
local commands = {
  add = {
    value = COMMAND_PREFIX .. "add",
    description = "Add files to the chat so aider can edit them or review them in detail",
    category = "input",
  },
  architect = {
    value = COMMAND_PREFIX .. "architect",
    description = "Enter architect/editor mode using two different models. If no prompt is provided, switches to architect/editor mode",
    category = "input",
  },
  ask = {
    value = COMMAND_PREFIX .. "ask",
    description = "Ask questions about the code base without editing any files. If no prompt is provided, switches to ask mode",
    category = "input",
  },
  ["chat-mode"] = {
    value = COMMAND_PREFIX .. "chat-mode",
    description = "Switch to a new chat mode",
    category = "input",
  },
  clear = {
    value = COMMAND_PREFIX .. "clear",
    description = "Clear the chat history",
    category = "direct",
  },
  code = {
    value = COMMAND_PREFIX .. "code",
    description = "Ask for changes to your code. If no prompt is provided, switches to code mode",
    category = "input",
  },
  commit = {
    value = COMMAND_PREFIX .. "commit",
    description = "Commit edits to the repo made outside the chat (commit message optional)",
    category = "input",
  },
  context = {
    value = COMMAND_PREFIX .. "context",
    description = "Enter context mode to see surrounding code context. If no prompt is provided, switches to context mode",
    category = "input",
  },
  copy = {
    value = COMMAND_PREFIX .. "copy",
    description = "Copy the last assistant message to the clipboard",
    category = "direct",
  },
  ["copy-context"] = {
    value = COMMAND_PREFIX .. "copy-context",
    description = "Copy the current chat context as markdown, suitable for pasting into a web UI",
    category = "direct",
  },
  diff = {
    value = COMMAND_PREFIX .. "diff",
    description = "Display the diff of changes since the last message",
    category = "direct",
  },
  drop = {
    value = COMMAND_PREFIX .. "drop",
    description = "Remove files from the chat session to free up context space",
    category = "input",
  },
  edit = {
    value = COMMAND_PREFIX .. "edit",
    description = "Alias for /editor: Open an editor to write a prompt",
    category = "input",
  },
  editor = {
    value = COMMAND_PREFIX .. "editor",
    description = "Open an editor to write a prompt",
    category = "input",
  },
  ["editor-model"] = {
    value = COMMAND_PREFIX .. "editor-model",
    description = "Switch the Editor Model to a new LLM",
    category = "input",
  },
  exit = {
    value = COMMAND_PREFIX .. "exit",
    description = "Exit the application",
    category = "direct",
  },
  git = {
    value = COMMAND_PREFIX .. "git",
    description = "Run a git command (output excluded from chat)",
    category = "input",
  },
  help = {
    value = COMMAND_PREFIX .. "help",
    description = "Ask questions about aider",
    category = "input",
  },
  lint = {
    value = COMMAND_PREFIX .. "lint",
    description = "Lint and fix in-chat files or all dirty files if none are in chat",
    category = "direct",
  },
  load = {
    value = COMMAND_PREFIX .. "load",
    description = "Load and execute commands from a file",
    category = "input",
  },
  ls = {
    value = COMMAND_PREFIX .. "ls",
    description = "List all known files and indicate which are included in the chat session",
    category = "direct",
  },
  map = {
    value = COMMAND_PREFIX .. "map",
    description = "Print out the current repository map",
    category = "direct",
  },
  ["map-refresh"] = {
    value = COMMAND_PREFIX .. "map-refresh",
    description = "Force a refresh of the repository map",
    category = "direct",
  },
  model = {
    value = COMMAND_PREFIX .. "model",
    description = "Switch the Main Model to a new LLM",
    category = "input",
  },
  models = {
    value = COMMAND_PREFIX .. "models",
    description = "Search the list of available models",
    category = "direct",
  },
  ["multiline-mode"] = {
    value = COMMAND_PREFIX .. "multiline-mode",
    description = "Toggle multiline mode (swap behavior of Enter and Meta+Enter)",
    category = "direct",
  },
  paste = {
    value = COMMAND_PREFIX .. "paste",
    description = "Paste image/text from the clipboard into the chat (optionally provide a name for the image)",
    category = "direct",
  },
  quit = {
    value = COMMAND_PREFIX .. "quit",
    description = "Exit the application",
    category = "direct",
  },
  ["read-only"] = {
    value = COMMAND_PREFIX .. "read-only",
    description = "Add files to the chat for reference only (not for editing) or make added files read-only",
    category = "input",
  },
  ["reasoning-effort"] = {
    value = COMMAND_PREFIX .. "reasoning-effort",
    description = "Set the reasoning effort level (a number or low/medium/high, depending on model)",
    category = "input",
  },
  report = {
    value = COMMAND_PREFIX .. "report",
    description = "Report a problem by opening a GitHub Issue",
    category = "direct",
  },
  reset = {
    value = COMMAND_PREFIX .. "reset",
    description = "Drop all files and clear the chat history",
    category = "direct",
  },
  run = {
    value = COMMAND_PREFIX .. "run",
    description = "Run a shell command and optionally add the output to the chat (alias: !)",
    category = "input",
  },
  save = {
    value = COMMAND_PREFIX .. "save",
    description = "Save commands to a file that can reconstruct the current chat session",
    category = "direct",
  },
  settings = {
    value = COMMAND_PREFIX .. "settings",
    description = "Print out the current settings",
    category = "direct",
  },
  test = {
    value = COMMAND_PREFIX .. "test",
    description = "Run a shell command and add the output to the chat on non-zero exit code",
    category = "direct",
  },
  ["think-tokens"] = {
    value = COMMAND_PREFIX .. "think-tokens",
    description = "Set the thinking token budget (e.g. 8096, 8k, 10.5k, 0.5M)",
    category = "input",
  },
  tokens = {
    value = COMMAND_PREFIX .. "tokens",
    description = "Report on the number of tokens used by the current chat context",
    category = "direct",
  },
  undo = {
    value = COMMAND_PREFIX .. "undo",
    description = "Undo the last git commit if it was done by aider",
    category = "direct",
  },
  voice = {
    value = COMMAND_PREFIX .. "voice",
    description = "Record and transcribe voice input",
    category = "direct",
  },
  ["weak-model"] = {
    value = COMMAND_PREFIX .. "weak-model",
    description = "Switch the Weak Model to a new LLM",
    category = "input",
  },
  web = {
    value = COMMAND_PREFIX .. "web",
    description = "Scrape a webpage, convert it to markdown, and send it in a message",
    category = "input",
  },
}

return commands
