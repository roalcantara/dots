-- Abstract base class for all vault implementations
local M = {}

--- Abstract Vault class
--- @class Vault
--- @field name string The name/type of the vault
--- @field config table Configuration options for the vault
local Vault = {}
Vault.__index = Vault

--- Create a new vault instance
--- @param name string The vault type name
--- @param config table|nil Configuration options
--- @return Vault
function Vault:new(name, config)
  local instance = {
    name = name or "unknown",
    config = config or {},
  }
  setmetatable(instance, self)
  return instance
end

--- Retrieve a secret from the vault
--- This is an abstract method that must be implemented by concrete classes
--- @param key string The secret identifier/path
--- @param options table|nil Additional options for retrieval
--- @return string|nil secret The secret value, or nil if not found
--- @return string|nil error Error message if retrieval failed
function Vault:get_secret(key, options)
  error(string.format("get_secret() must be implemented by %s vault", self.name))
end

--- Check if the vault is available/configured
--- @return boolean available True if vault is ready to use
--- @return string|nil error Error message if not available
function Vault:is_available()
  error(string.format("is_available() must be implemented by %s vault", self.name))
end

--- Validate the vault configuration
--- @return boolean valid True if configuration is valid
--- @return string|nil error Error message if invalid
function Vault:validate_config()
  return true, nil
end

--- Get vault metadata/info
--- @return table info Vault information
function Vault:get_info()
  return {
    name = self.name,
    config = vim.tbl_deep_extend("force", {}, self.config),
  }
end

M.Vault = Vault

return M
