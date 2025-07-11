local vault = require('core.opt.vaults.vault_manager')

--- Setup vault configuration
--- @example local openai_key, err = vault.get_secret("llm.openai.api_key") | Get OpenAI API key from default vault
--- @example local anthropic_key, err = vault.get_secret("anthropic_api_key", "work_secrets") | Get Anthropic API key from work_secrets vault
--- @example local github_token, err = vault.get_secret("github", "personal_passwords", { field = "token" }) | Get GitHub token from personal_passwords vault with field "token"
--- @example local api_key, err = vault.manager:get_secret("llm.openai.api_key", { "gcp_secrets" }) | Try multiple vaults in order
--- @example local api_key, err = vault.manager:get_secret_from_any("openai_key", { "dev_secrets", "work_secrets" }) | Try multiple vaults in order
vault.setup({
  default_vault = "dev_secrets",
  vaults = {
    dev_secrets = {
      type = "sops",
      config = {
        file_path = vim.fn.expand("~/.config/nvim/secrets.yaml"),
        format = "yaml"
      }
    },
    personal_passwords = {
      type = "pass",
      config = {
        store_dir = vim.fn.expand("~/.password-store")
      }
    },
    work_secrets = {
      type = "1password",
      config = {
        account = "work",
        vault = "Development"
      }
    },
    gcp_secrets = {
      type = "gcp_secret_manager",
      config = {
        project_id = "my-neovim-secrets",
        auth_account = "service-account@project.iam.gserviceaccount.com",
        timeout = 60,
      }
    }
  }
})

--- Get a secret from the vault
--- @param key string The secret key
--- @param options? table Additional options
--- @return string|nil secret
--- @example get_secret("llm.openai.api_key") | Get OpenAI API key from default vault
--- @example get_secret("anthropic_api_key", { vault = "work_secrets" }) | Get Anthropic API key from work_secrets vault
--- @example get_secret("github", { vault = "personal_passwords", field = "token" }) | Get GitHub token from personal_passwords vault with field "token"
--- @example get_secret("openai_key", { vault = { "dev_secrets", "work_secrets" } }) | Try multiple vaults in order
--- @example get_secret("llm.openai.api_key", { vault = "gcp_secrets" }) | Get OpenAI API key from gcp_secrets vault
local function get_secret(key, options)
  options = options or { vault = vault.default_vault }
  local value, err = vault.get_secret(key, options.vault, options)
  if err then
    return nil
  end
  return value
end

return get_secret
