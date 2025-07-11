-- 1Password vault implementation

local base = require('core.opt.vaults.vault_base')

local M = {}

--- 1Password Vault implementation
--- @class OnePasswordVault : Vault
local OnePasswordVault = setmetatable({}, { __index = base.Vault })
OnePasswordVault.__index = OnePasswordVault

--- Create a new 1Password vault
--- @param config table Configuration options
--- @return OnePasswordVault
function OnePasswordVault:new(config)
  local default_config = {
    op_binary = "op",
    account = nil, -- Optional: specific account shorthand
    vault = nil,   -- Optional: specific vault name
  }

  local merged_config = vim.tbl_deep_extend("force", default_config, config or {})
  local instance = {
    name = "1password",
    config = merged_config,
  }
  setmetatable(instance, OnePasswordVault)
  return instance
end

--- Check if 1Password CLI is available and authenticated
--- @return boolean available
--- @return string|nil error
function OnePasswordVault:is_available()
  if vim.fn.executable(self.config.op_binary) == 0 then
    return false, string.format("1Password CLI '%s' not found", self.config.op_binary)
  end

  -- Check if user is signed in
  local cmd = { self.config.op_binary, "account", "list", "--format=json" }
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return false, "1Password CLI not authenticated. Run 'op signin' first."
  end

  return true, nil
end

--- Retrieve secret from 1Password
--- @param key string The item reference (can be name, UUID, or reference syntax)
--- @param options table|nil Additional options (field, section, etc.)
--- @return string|nil secret
--- @return string|nil error
function OnePasswordVault:get_secret(key, options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  local opts = options or {}
  local cmd = { self.config.op_binary, "item", "get", key }

  -- Add account if specified
  if self.config.account then
    table.insert(cmd, "--account")
    table.insert(cmd, self.config.account)
  end

  -- Add vault if specified
  if self.config.vault then
    table.insert(cmd, "--vault")
    table.insert(cmd, self.config.vault)
  end

  -- Add field specification if provided
  if opts.field then
    table.insert(cmd, "--field")
    table.insert(cmd, opts.field)
  else
    -- Default to password field
    table.insert(cmd, "--field")
    table.insert(cmd, "password")
  end

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("1Password command failed: %s", result:gsub("\n", " "))
  end

  return result:gsub("\n$", ""), nil
end

M.OnePasswordVault = OnePasswordVault

return M
