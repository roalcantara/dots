-- vault/sops.lua
-- SOPS vault implementation

local base = require('core.opt.vaults.vault_base')

local M = {}

--- SOPS Vault implementation
--- @class SopsVault : Vault
local SopsVault = setmetatable({}, { __index = base.Vault })
SopsVault.__index = SopsVault

--- Create a new SOPS vault
--- @param config table Configuration options
--- @return SopsVault
function SopsVault:new(config)
  local default_config = {
    sops_binary = "sops",
    file_path = nil, -- Path to encrypted SOPS file
    format = "yaml", -- yaml, json, env, etc.
  }

  local merged_config = vim.tbl_deep_extend("force", default_config, config or {})
  local instance = {
    name = "sops",
    config = merged_config,
  }
  setmetatable(instance, SopsVault)
  return instance
end

--- Check if SOPS is available
--- @return boolean available
--- @return string|nil error
function SopsVault:is_available()
  if not self.config.file_path then
    return false, "SOPS file path not configured"
  end

  if vim.fn.executable(self.config.sops_binary) == 0 then
    return false, string.format("SOPS binary '%s' not found", self.config.sops_binary)
  end

  if vim.fn.filereadable(self.config.file_path) == 0 then
    return false, string.format("SOPS file '%s' not found or not readable", self.config.file_path)
  end

  return true, nil
end

--- Retrieve secret from SOPS file
--- @param key string The secret key (supports dot notation for nested keys)
--- @param options? table Additional options
--- @return string|nil secret
--- @return string|nil error
function SopsVault:get_secret(key, options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  -- Build SOPS command to extract specific key
  local cmd = {
    self.config.sops_binary,
    "--decrypt",
    "--extract",
    string.format('["__%s__"]', key:gsub("%.", '"]["')),
    self.config.file_path
  }

  -- Execute SOPS command
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("SOPS command failed: %s", result:gsub("\n", " "))
  end

  -- Clean up the result (remove trailing newlines)
  return result:gsub("\n$", ""), nil
end

M.SopsVault = SopsVault

return M
