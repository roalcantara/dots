local function del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

--- Disable keymaps
--- @param maps table|nil Keymap table
local function disable_keymaps(maps)
  for lhs, modes in pairs(maps or {}) do
    for _, mode in ipairs(modes) do
      del(mode, lhs)
    end
  end
end

--- Bulk disable keymaps by pattern
--- @param patterns table|nil Table of patterns to match keymaps
--- @param modes table|nil Modes to search in (default: all modes)
local function bulk_disable_keymaps(patterns, modes)
  patterns = patterns or {}
  modes = modes or { "n", "v", "i", "s", "o", "x" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(keymaps) do
      local lhs = keymap.lhs
      if type(lhs) == "string" then
        for _, pattern in ipairs(patterns) do
          if lhs:match(pattern) then
            del(mode, lhs)
            break
          end
        end
      end
    end
  end
end

--- Disable all LazyVim keymaps
local function disable_lazyvim_keymaps()
  -- Disable all Space keymaps (LazyVim's leader key)
  bulk_disable_keymaps({ "^<Space>" }, { "n", "v", "i", "s" })

  -- Disable specific LazyVim patterns
  local lazyvim_patterns = {
    "^<Space>",   -- All Space keymaps
    "^gc",        -- Comment keymaps
    "^gr",        -- LSP rename keymaps
    "^[[]",       -- Navigation keymaps
    "^[]]",       -- Navigation keymaps
    "^[a-zA-Z]$", -- Single letter keymaps that might be LazyVim
  }

  bulk_disable_keymaps(lazyvim_patterns)
end

--- Disable all keymaps from a specific source
--- @param source_pattern string Pattern to match in the keymap source
--- @param modes table|nil Modes to search in (default: all modes)
local function disable_keymaps_by_source(source_pattern, modes)
  modes = modes or { "n", "v", "i", "s", "o", "x" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(keymaps) do
      local source = keymap.rhs or ""
      if type(source) == "string" and source:match(source_pattern) then
        del(mode, keymap.lhs)
      end
    end
  end
end

--- Disable keymaps by their source file path
--- @param file_patterns table Table of file path patterns to match
--- @param modes table|nil Modes to search in (default: all modes)
local function disable_keymaps_by_file(file_patterns, modes)
  modes = modes or { "n", "v", "i", "s", "o", "x" }
  file_patterns = file_patterns or {}

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(keymaps) do
      local source = keymap.rhs or ""
      if type(source) == "string" then
        for _, pattern in ipairs(file_patterns) do
          if source:match(pattern) then
            del(mode, keymap.lhs)
            break
          end
        end
      end
    end
  end
end

--- Disable keymaps by their description or command content
--- @param patterns table Table of patterns to match in keymap description or command
--- @param modes table|nil Modes to search in (default: all modes)
local function disable_keymaps_by_description(patterns, modes)
  modes = modes or { "n", "v", "i", "s", "o", "x" }
  patterns = patterns or {}

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(keymaps) do
      local desc = keymap.desc or ""
      local rhs = keymap.rhs or ""
      local combined = desc .. " " .. rhs

      if type(combined) == "string" then
        for _, pattern in ipairs(patterns) do
          if combined:match(pattern) then
            del(mode, keymap.lhs)
            break
          end
        end
      end
    end
  end
end

--- Disable all LazyVim-related keymaps more aggressively
local function disable_lazyvim_keymaps_aggressive()
  -- Disable by source patterns
  local lazyvim_sources = {
    "LazyVim",
    "lazyvim",
    "vim/_defaults.lua",
    "flash.nvim",
    "mini.ai",
    "nvim%-treesitter",
    "gitsigns",
    "yanky.nvim",
    "snacks.nvim",
  }

  for _, source in ipairs(lazyvim_sources) do
    disable_keymaps_by_source(source)
  end

  -- Disable by file path patterns
  local lazyvim_files = {
    "LazyVim/lua/lazyvim",
    "vim/_defaults.lua",
    "flash.nvim",
    "mini.ai",
    "nvim%-treesitter",
    "gitsigns.nvim",
    "yanky.nvim",
    "snacks.nvim",
  }

  disable_keymaps_by_file(lazyvim_files)

  -- Disable by description patterns
  local lazyvim_descriptions = {
    "LazyVim",
    "lazyvim",
    "Find Files",
    "Buffers",
    "Grep",
    "Diagnostics",
    "LSP",
    "Git",
    "Comment",
    "Trouble",
    "Aerial",
    "Mason",
    "Noice",
    "Snacks",
  }

  disable_keymaps_by_description(lazyvim_descriptions)

  -- Also use the original pattern-based approach
  disable_lazyvim_keymaps()
end

--- List all remaining keymaps for debugging
--- @param modes table|nil Modes to list (default: all modes)
--- @param filter_pattern string|nil Optional pattern to filter keymaps
local function list_remaining_keymaps(modes, filter_pattern)
  modes = modes or { "n", "v", "i", "s", "o", "x" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    if #keymaps > 0 then
      print(string.format("Mode %s (%d keymaps):", mode, #keymaps))
      for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs or ""
        local rhs = keymap.rhs or ""
        local desc = keymap.desc or ""

        if not filter_pattern or lhs:match(filter_pattern) or rhs:match(filter_pattern) or desc:match(filter_pattern) then
          print(string.format("  %s -> %s (%s)", lhs, rhs, desc))
        end
      end
      print()
    end
  end
end

--- Comprehensive keymap disabling with feedback
--- @param verbose boolean|nil Whether to print feedback
local function disable_all_lazyvim_keymaps_comprehensive(verbose)
  verbose = verbose or false

  if verbose then
    print("Starting comprehensive LazyVim keymap disabling...")
  end

  -- Count keymaps before
  local before_count = 0
  for _, mode in ipairs({ "n", "v", "i", "s", "o", "x" }) do
    before_count = before_count + #vim.api.nvim_get_keymap(mode)
  end

  -- Run all disabling methods
  disable_lazyvim_keymaps_aggressive()

  -- Count keymaps after
  local after_count = 0
  for _, mode in ipairs({ "n", "v", "i", "s", "o", "x" }) do
    after_count = after_count + #vim.api.nvim_get_keymap(mode)
  end

  local disabled_count = before_count - after_count

  if verbose then
    print(string.format("Disabled %d keymaps (from %d to %d)", disabled_count, before_count, after_count))
  end

  return disabled_count
end

return {
  del = del,
  bulk_disable = bulk_disable_keymaps,
  disable_lazyvim = disable_lazyvim_keymaps,
  disable_keymaps = disable_keymaps,
  disable_lazyvim_aggressive = disable_lazyvim_keymaps_aggressive,
  disable_by_file = disable_keymaps_by_file,
  disable_by_source = disable_keymaps_by_source,
  disable_by_description = disable_keymaps_by_description,
  list_remaining_keymaps = list_remaining_keymaps,
  disable_all_lazyvim_comprehensive = disable_all_lazyvim_keymaps_comprehensive,
}
