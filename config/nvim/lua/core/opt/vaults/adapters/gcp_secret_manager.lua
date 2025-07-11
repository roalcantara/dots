-- Google Cloud Secret Manager vault implementation

local base = require('core.opt.vaults.vault_base')

local M = {}

--- Google Cloud Secret Manager Vault implementation
--- @class GcpSecretManagerVault : Vault
local GcpSecretManagerVault = setmetatable({}, { __index = base.Vault })
GcpSecretManagerVault.__index = GcpSecretManagerVault

--- Create a new Google Cloud Secret Manager vault
--- @param config table Configuration options
--- @return GcpSecretManagerVault
function GcpSecretManagerVault:new(config)
  local default_config = {
    gcloud_binary = "gcloud",
    project_id = nil,   -- GCP Project ID (required)
    format = "json",    -- Output format: json, yaml, text
    auth_account = nil, -- Optional: specific service account
    region = nil,       -- Optional: specific region
    timeout = 30,       -- Command timeout in seconds
  }

  local merged_config = vim.tbl_deep_extend("force", default_config, config or {})
  local instance = {
    name = "gcp_secret_manager",
    config = merged_config,
  }
  setmetatable(instance, GcpSecretManagerVault)
  return instance
end

--- Check if Google Cloud SDK is available and authenticated
--- @return boolean available
--- @return string|nil error
function GcpSecretManagerVault:is_available()
  -- Check if gcloud CLI is installed
  if vim.fn.executable(self.config.gcloud_binary) == 0 then
    return false, string.format("gcloud CLI '%s' not found. Install Google Cloud SDK.", self.config.gcloud_binary)
  end

  -- Check if project ID is configured
  if not self.config.project_id then
    return false, "GCP project ID not configured. Set 'project_id' in vault config."
  end

  -- Check authentication status
  local auth_cmd = { self.config.gcloud_binary, "auth", "list", "--format=json", "--filter=status:ACTIVE" }
  local auth_result = vim.fn.system(auth_cmd)
  local auth_exit_code = vim.v.shell_error

  if auth_exit_code ~= 0 then
    return false, "gcloud not authenticated. Run 'gcloud auth login' or 'gcloud auth application-default login'"
  end

  -- Parse auth result to check for active account
  local ok, auth_data = pcall(vim.fn.json_decode, auth_result)
  if not ok or not auth_data or #auth_data == 0 then
    return false, "No active gcloud authentication found"
  end

  -- Check if Secret Manager API is enabled (optional check)
  local api_cmd = {
    self.config.gcloud_binary,
    "services", "list",
    "--enabled",
    "--filter=name:secretmanager.googleapis.com",
    "--format=json",
    "--project=" .. self.config.project_id
  }
  local api_result = vim.fn.system(api_cmd)
  local api_exit_code = vim.v.shell_error

  if api_exit_code ~= 0 then
    return false,
      string.format("Cannot verify Secret Manager API status for project '%s'. Check project access.",
        self.config.project_id)
  end

  local ok_api, api_data = pcall(vim.fn.json_decode, api_result)
  if ok_api and api_data and #api_data == 0 then
    return false,
      string.format(
        "Secret Manager API not enabled for project '%s'. Run: gcloud services enable secretmanager.googleapis.com",
        self.config.project_id)
  end

  return true, nil
end

--- Validate vault configuration
--- @return boolean valid
--- @return string|nil error
function GcpSecretManagerVault:validate_config()
  if not self.config.project_id or self.config.project_id == "" then
    return false, "project_id is required for GCP Secret Manager"
  end

  -- Validate project ID format (basic check)
  if not self.config.project_id:match("^[a-z][a-z0-9%-]*[a-z0-9]$") then
    return false, "Invalid GCP project ID format"
  end

  return true, nil
end

--- Retrieve secret from Google Secret Manager
--- @param key string The secret name or resource path
--- @param options table|nil Additional options
--- @return string|nil secret
--- @return string|nil error
function GcpSecretManagerVault:get_secret(key, options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  local valid, validate_err = self:validate_config()
  if not valid then
    return nil, validate_err
  end

  local opts = options or {}
  local version = opts.version or "latest"

  -- Extract secret name and version from key if needed
  local secret_name, secret_version = key:match("^([^:]+):?(.*)$")
  if secret_version and secret_version ~= "" then
    version = secret_version
  end

  -- Build gcloud command
  local cmd = {
    self.config.gcloud_binary,
    "secrets",
    "versions",
    "access",
    version,
    "--secret=" .. secret_name,
    "--project=" .. self.config.project_id,
  }

  -- Add optional parameters
  if self.config.auth_account then
    table.insert(cmd, "--account=" .. self.config.auth_account)
  end

  -- Execute command with timeout
  local start_time = vim.fn.reltime()
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  local elapsed = vim.fn.reltimestr(vim.fn.reltime(start_time))

  -- Check for timeout (approximate)
  if tonumber(elapsed) > self.config.timeout then
    return nil, string.format("Command timed out after %s seconds", elapsed)
  end

  if exit_code ~= 0 then
    -- Parse common error scenarios
    local error_msg = result:gsub("\n", " "):gsub("%s+", " ")

    if error_msg:match("NOT_FOUND") or error_msg:match("not found") then
      return nil, string.format("Secret '%s' not found in project '%s'", key, self.config.project_id)
    elseif error_msg:match("PERMISSION_DENIED") or error_msg:match("permission denied") then
      return nil, string.format("Permission denied accessing secret '%s'. Check IAM permissions.", key)
    elseif error_msg:match("FAILED_PRECONDITION") then
      return nil, string.format("Secret '%s' is disabled or destroyed", key)
    else
      return nil, string.format("gcloud command failed: %s", error_msg)
    end
  end

  -- Clean up result (remove trailing newlines)
  local secret_value = result:gsub("\n$", "")

  -- Additional validation for empty secrets
  if secret_value == "" then
    return nil, string.format("Secret '%s' exists but is empty", key)
  end

  return secret_value, nil
end

--- List available secrets (bonus feature)
--- @param options table|nil Filter options
--- @return table|nil secrets List of secret names
--- @return string|nil error
function GcpSecretManagerVault:list_secrets(options)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  local opts = options or {}
  local cmd = {
    self.config.gcloud_binary,
    "secrets",
    "list",
    "--project=" .. self.config.project_id,
    "--format=json"
  }

  -- Add filter if provided
  if opts.filter then
    table.insert(cmd, "--filter=" .. opts.filter)
  end

  -- Add limit if provided
  if opts.limit then
    table.insert(cmd, "--limit=" .. tostring(opts.limit))
  end

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("Failed to list secrets: %s", result:gsub("\n", " "))
  end

  local ok, secrets_data = pcall(vim.fn.json_decode, result)
  if not ok then
    return nil, "Failed to parse secrets list JSON response"
  end

  -- Extract secret names
  local secret_names = {}
  for _, secret in ipairs(secrets_data or {}) do
    if secret.name then
      -- Extract just the secret name from full resource path
      local name = secret.name:match("secrets/([^/]+)$")
      table.insert(secret_names, name or secret.name)
    end
  end

  return secret_names, nil
end

--- Get secret metadata (bonus feature)
--- @param key string Secret name
--- @return table|nil metadata Secret metadata
--- @return string|nil error
function GcpSecretManagerVault:get_secret_metadata(key)
  local available, err = self:is_available()
  if not available then
    return nil, err
  end

  local cmd = {
    self.config.gcloud_binary,
    "secrets",
    "describe",
    key,
    "--project=" .. self.config.project_id,
    "--format=json"
  }

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    return nil, string.format("Failed to get secret metadata: %s", result:gsub("\n", " "))
  end

  local ok, metadata = pcall(vim.fn.json_decode, result)
  if not ok then
    return nil, "Failed to parse secret metadata JSON response"
  end

  return metadata, nil
end

--- Get vault info with GCP-specific details
--- @return table info Extended vault information
function GcpSecretManagerVault:get_info()
  local base_info = base.Vault.get_info(self)

  -- Add GCP-specific information
  base_info.gcp_info = {
    project_id = self.config.project_id,
    auth_account = self.config.auth_account,
    region = self.config.region,
  }

  -- Try to get current gcloud configuration
  local config_cmd = { self.config.gcloud_binary, "config", "list", "--format=json" }
  local config_result = vim.fn.system(config_cmd)
  if vim.v.shell_error == 0 then
    local ok, config_data = pcall(vim.fn.json_decode, config_result)
    if ok and config_data then
      base_info.gcp_info.current_account = config_data.core and config_data.core.account
      base_info.gcp_info.current_project = config_data.core and config_data.core.project
    end
  end

  return base_info
end

M.GcpSecretManagerVault = GcpSecretManagerVault

return M

--[[
USAGE EXAMPLES:

-- Basic configuration
local gcp_vault = require('vault.gcp_secret_manager').GcpSecretManagerVault:new({
  project_id = "my-gcp-project",
})

-- Advanced configuration
local gcp_vault = require('vault.gcp_secret_manager').GcpSecretManagerVault:new({
  project_id = "my-production-project",
  auth_account = "service-account@project.iam.gserviceaccount.com",
  timeout = 60,
})

-- Get secrets
local api_key, err = gcp_vault:get_secret("openai-api-key")
local db_password, err = gcp_vault:get_secret("database-password", { version = "2" })

-- Using in vault manager
local vault = require('vault.manager')
vault.setup({
  default_vault = "gcp_secrets",
  vaults = {
    gcp_secrets = {
      type = "gcp_secret_manager",
      config = {
        project_id = "my-neovim-secrets",
      }
    }
  }
})

-- Access secrets
local openai_key = vault.get_secret("llm.openai.api_key")
local anthropic_key = vault.get_secret("llm.anthropic.api_key")

PREREQUISITES:
1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
2. Authenticate: gcloud auth login
3. Set project: gcloud config set project YOUR_PROJECT_ID
4. Enable Secret Manager API: gcloud services enable secretmanager.googleapis.com
5. Grant IAM permissions: Secret Manager Secret Accessor role

SECRET NAMING CONVENTIONS:
- Use lowercase with hyphens: "openai-api-key"
- Organize with prefixes: "llm-openai-key", "db-prod-password"
- Use labels in GCP for better organization

ERROR HANDLING:
- Authentication errors: Guides user to proper gcloud auth commands
- Permission errors: Suggests checking IAM roles
- API not enabled: Provides exact command to enable
- Secret not found: Clear error with project context
- Network timeouts: Configurable timeout with clear messaging
--]]
