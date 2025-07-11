-- Factory for creating vault instances
local M = {}

-- Import all vault implementations
local vault_types = {
  sops = require('core.opt.vaults.adapters.sops').SopsVault,
  pass = require('core.opt.vaults.adapters.pass').PassVault,
  ['1password'] = require('core.opt.vaults.adapters.onepassword').OnePasswordVault, -- Alias
  gpg = require('core.opt.vaults.adapters.gpg').GpgVault,
  gcp_secret_manager = require('core.opt.vaults.adapters.gcp_secret_manager').GcpSecretManagerVault,
}

--- Create a vault instance
--- @param vault_type string The type of vault to create
--- @param config table Configuration for the vault
--- @return Vault|nil vault The vault instance, or nil if type not found
--- @return string|nil error Error message if creation failed
function M.create_vault(vault_type, config)
  local VaultClass = vault_types[vault_type]
  if not VaultClass then
    return nil, string.format("Unknown vault type: %s", vault_type)
  end

  local ok, vault = pcall(VaultClass.new, VaultClass, config)
  if not ok then
    return nil, string.format("Failed to create %s vault: %s", vault_type, vault)
  end

  return vault, nil
end

--- Get list of available vault types
--- @return table types List of available vault type names
function M.get_available_types()
  return vim.tbl_keys(vault_types)
end

--- Register a new vault type
--- @param name string The vault type name
--- @param vault_class table The vault class
function M.register_vault_type(name, vault_class)
  vault_types[name] = vault_class
end

return M
