-- PASS vault implementation

local base = require('core.opt.vaults.vault_base')

local M = {}

--- PASS Vault implementation
--- @class PassVault : Vault
local PassVault = setmetatable({}, { __index = base.Vault })
PassVault.__index = PassVault

--- Create a new PASS vault
--- @param config table Configuration options
--- @return PassVault
function PassVault:new(config)
  local default_config = {
    pass_binary = "pass",
    store_dir = nil, -- Optional: specific password store directory
  }

  local merged_config = vim.tbl_deep_extend("force", default_config, config or {})
  local instance = {
    name = "pass",
    config = merged_config,
  }
  setmetatable(instance, PassVault)
  return instance
end

--- Check if PASS is available
--- @return boolean available
--- @return string|nil error
function PassVault:is_available()
  if vim.fn.executable(self.config.pass_binary) == 0 then
    return false, string.format("PASS binary '%s' not found", self.config.pass_binary)
  end

  -- Check if password store is initialized
  local store_dir = self.config.store_dir or os.getenv("PASSWORD_STORE_DIR") or (os.getenv("HOME") .. "/.password-store")
  if vim.fn.isdirectory(store_dir) == 0 then
    return false, string.format("Password store not found at '%s'", store_dir)
  end

  return true, nil
end

--- Retrieve secret from PASS
--- @param key string The secret path in password store
--- @param options table|nil Additional options
--- @return string|nil secret
--- @return string|nil error
function PassVault:get_secret(key, options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  local cmd = { self.config.pass_binary, "show", key }

  -- Set PASSWORD_STORE_DIR if configured
  local env = {}
  if self.config.store_dir then
    env.PASSWORD_STORE_DIR = self.config.store_dir
  end

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("PASS command failed: %s", result:gsub("\n", " "))
  end

  -- PASS returns the password on the first line, optionally followed by metadata
  local lines = vim.split(result, "\n")
  return lines[1], nil
end

M.PassVault = PassVault

return M
