--- Configuration for LSP hover filtering
--- This module defines which element types should be excluded from automatic hover display
---
--- The hover filter uses treesitter to analyze the syntax tree and determine whether
--- to show hover documentation based on the element type under the cursor.
---
--- @usage
--- -- To customize excluded types, modify this file or override in your config:
--- local hover_filter = require("core/vi/ui/lsp/hover_filter")
---
--- -- Add more excluded types
--- table.insert(hover_filter.excluded_node_types, "new_type_to_exclude")
---
--- -- Add filetype-specific exclusions
--- hover_filter.filetype_exclusions.lua = { "local", "end", "then" }
--- hover_filter.filetype_exclusions.javascript = { "const", "let", "var" }

local M = {}

--- Default excluded node types for hover filtering
--- These are treesitter node types that should not trigger hover documentation
M.excluded_node_types = {
  -- String literals
  'string',
  'string_literal',
  'string_content',
  -- Brackets and punctuation
  '(',
  ')',
  '[',
  ']',
  '{',
  '}',
  '<',
  '>',
  -- Basic punctuation
  ',',
  ';',
  ":",
  '.',
  '!',
  '?',
  -- Operators
  '+',
  '-',
  '*',
  '/',
  '=',
  '==',
  '!=',
  '>',
  '<',
  '>=',
  '<=',
  -- Comments
  'comment',
  'line_comment',
  'block_comment',
  -- Whitespace
  'whitespace',
  'indent',
  'dedent',
  -- Basic literals
  'number',
  'number_literal',
  -- Keywords (optional - uncomment if you want to exclude keywords too)
  'keyword',
  'function',
  'if',
  'else',
  'for',
  'while',
  'return',
}

--- Filetype-specific exclusions
--- You can add filetype-specific exclusions here
M.filetype_exclusions = {
  -- Example: exclude more types for specific filetypes
  -- lua = { 'local', 'end', 'then' },
  -- javascript = { 'const', 'let', 'var' },
}

--- Function to check if hover should be shown for the current cursor position
--- Using treesitter to analyze and filter out basic elements
--- @return boolean True if hover should be shown, false otherwise
function M.should_show_hover()
  local success, node = pcall(vim.treesitter.get_node)
  if not success or not node then
    -- If treesitter fails, fall back to showing hover
    return true
  end

  local node_type = node:type()
  local filetype = vim.bo.filetype

  -- Get exclusions for current filetype
  local filetype_exclusions = M.filetype_exclusions[filetype] or {}

  -- Check if the node type is in the excluded list
  for _, excluded_type in ipairs(M.excluded_node_types) do
    if node_type == excluded_type then
      return false
    end
  end

  -- Check filetype-specific exclusions
  for _, excluded_type in ipairs(filetype_exclusions) do
    if node_type == excluded_type then
      return false
    end
  end

  -- Additional checks for specific patterns
  local node_text = vim.treesitter.get_node_text(node, 0)
  if node_text then
    -- Exclude single characters that are likely punctuation
    if #node_text == 1 and vim.fn.match(node_text, "[(){}\\[\\]<>.,;:!?]") >= 0 then
      return false
    end

    -- Exclude simple string literals (quoted strings)
    if node_text:match("^[\"'`].*[\"'`]$") then
      return false
    end
  end

  return true
end

--- Debug function to show current node information
--- Useful for understanding what node types are under the cursor
--- @return table|nil Node information or nil if no node found
function M.debug_current_node()
  local success, node = pcall(vim.treesitter.get_node)
  if not success or not node then
    return nil
  end

  local node_text = vim.treesitter.get_node_text(node, 0)
  return {
    type = node:type(),
    text = node_text,
    should_show_hover = M.should_show_hover(),
  }
end

return M
