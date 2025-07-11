-- GPG vault implementation for encrypted files
local base = require('core.opt.vaults.vault_base')

local M = {}

--- GPG Vault implementation
--- @class GpgVault : Vault
local GpgVault = setmetatable({}, { __index = base.Vault })
GpgVault.__index = GpgVault

--- Create a new GPG vault
--- @param config table Configuration options
--- @return GpgVault
function GpgVault:new(config)
  local default_config = {
    gpg_binary = "gpg",
    secrets_file = nil, -- Path to encrypted secrets file
    format = "yaml",    -- Format of the encrypted file
    key_id = nil,       -- Optional: specific GPG key ID to use
  }

  local merged_config = vim.tbl_deep_extend("force", default_config, config or {})
  local instance = {
    name = "gpg",
    config = merged_config,
  }
  setmetatable(instance, GpgVault)
  return instance
end

--- Check if GPG is available
--- @return boolean available
--- @return string|nil error
function GpgVault:is_available()
  if vim.fn.executable(self.config.gpg_binary) == 0 then
    return false, string.format("GPG binary '%s' not found", self.config.gpg_binary)
  end

  if not self.config.secrets_file then
    return false, "GPG secrets file path not configured"
  end

  if vim.fn.filereadable(self.config.secrets_file) == 0 then
    return false, string.format("GPG secrets file '%s' not found", self.config.secrets_file)
  end

  return true, nil
end

--- Retrieve secret from GPG encrypted file
--- @param key string The secret key (supports dot notation)
--- @param options? table Additional options
--- @return string|nil secret
--- @return string|nil error
function GpgVault:get_secret(key, options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  -- Decrypt the file
  local cmd = { self.config.gpg_binary, "--quiet", "--decrypt", self.config.secrets_file }

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("GPG decryption failed: %s", result:gsub("\n", " "))
  end

  -- Parse the decrypted content based on format
  local data
  if self.config.format == "yaml" then
    local ok, yaml = pcall(vim.fn['yaml#decode'], result)
    if not ok then
      return nil, "Failed to parse YAML content"
    end
    data = yaml
  elseif self.config.format == "json" then
    local ok, json = pcall(vim.fn.json_decode, result)
    if not ok then
      return nil, "Failed to parse JSON content"
    end
    data = json
  else
    return nil, string.format("Unsupported format: %s", self.config.format)
  end

  -- Navigate to the key using dot notation
  local value = data
  for part in key:gmatch("[^%.]+") do
    if type(value) ~= "table" or value[part] == nil then
      return nil, string.format("Key '%s' not found", key)
    end
    value = value[part]
  end

  return tostring(value), nil
end

M.GpgVault = GpgVault

return M
