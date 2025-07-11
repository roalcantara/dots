-- High-level vault manager for easy secret retrieval

local factory = require('core.opt.vaults.vault_factory')

local M = {}

--- Vault Manager
--- @class VaultManager
--- @field vaults table Configured vault instances
--- @field default_vault string|nil Default vault name
local VaultManager = {}
VaultManager.__index = VaultManager

--- Create a new vault manager
--- @param config table Configuration with vault definitions
--- @return VaultManager
function VaultManager:new(config)
  local instance = {
    vaults = {},
    default_vault = config.default_vault,
  }

  -- Initialize configured vaults
  for name, vault_config in pairs(config.vaults or {}) do
    local vault, err = factory.create_vault(vault_config.type, vault_config.config)
    if vault then
      instance.vaults[name] = vault
    else
      vim.notify(string.format("Failed to initialize vault '%s': %s", name, err), vim.log.levels.WARN)
    end
  end

  setmetatable(instance, self)
  return instance
end

--- Get a secret from a specific vault or the default vault
--- @param key string The secret key
--- @param vault_name string|nil Specific vault name (uses default if nil)
--- @param options table|nil Additional options
--- @return string|nil secret The secret value
--- @return string|nil error Error message if retrieval failed
function VaultManager:get_secret(key, vault_name, options)
  local target_vault = vault_name or self.default_vault

  if not target_vault then
    return nil, "No vault specified and no default vault configured"
  end

  local vault = self.vaults[target_vault]
  if not vault then
    return nil, string.format("Vault '%s' not found", target_vault)
  end

  return vault:get_secret(key, options)
end

--- Try to get a secret from multiple vaults in order
--- @param key string The secret key
--- @param vault_names table List of vault names to try
--- @param options table|nil Additional options
--- @return string|nil secret The secret value
--- @return string|nil error Error message if all vaults failed
function VaultManager:get_secret_from_any(key, vault_names, options)
  local errors = {}

  for _, vault_name in ipairs(vault_names) do
    local secret, err = self:get_secret(key, vault_name, options)
    if secret then
      return secret, nil
    end
    table.insert(errors, string.format("%s: %s", vault_name, err or "unknown error"))
  end

  return nil, string.format("All vaults failed: %s", table.concat(errors, "; "))
end

--- Get list of available vaults
--- @return table vaults List of configured vault names
function VaultManager:list_vaults()
  return vim.tbl_keys(self.vaults)
end

--- Check status of all configured vaults
--- @return table status Status of each vault
function VaultManager:check_vault_status()
  local status = {}
  for name, vault in pairs(self.vaults) do
    local available, err = vault:is_available()
    status[name] = {
      available = available,
      error = err,
      info = vault:get_info(),
    }
  end
  return status
end

M.VaultManager = VaultManager

--- Global vault manager instance
M.manager = nil

--- Initialize the global vault manager
--- @param config table Configuration
function M.setup(config)
  M.manager = VaultManager:new(config)
end

--- Get a secret using the global manager
--- @param key string The secret key
--- @param vault_name string|nil Vault name
--- @param options table|nil Options
--- @return string|nil secret
--- @return string|nil error
function M.get_secret(key, vault_name, options)
  if not M.manager then
    return nil, "Vault manager not initialized. Call setup() first."
  end
  return M.manager:get_secret(key, vault_name, options)
end

return M
