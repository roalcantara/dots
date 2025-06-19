return {
  -- AVANTE - Use your Neovim like using Cursor AI IDE!
  -- https://github.com/yetone/avante.nvim?tab=readme-ov-file#installation
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    enabled = true,
    version = false, -- Never set this value to '*'! Never!
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick",         -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua",              -- for file_selector provider fzf
      "echasnovski/mini.icons",        -- modern icon provider
      "zbirenbaum/copilot.lua",        -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
          latex = { enabled = false },
        },
        ft = { "markdown", "Avante" },
      },
    },
    ---@see https://github.com/yetone/avante.nvim?tab=readme-ov-file#installation
    ---@see https://github.com/yetone/avante.nvim/wiki#secrets
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, {
        provider = "claude", -- The provider used in Aider mode or in the planning phase of Cursor Planning Mode
        mode = "agentic",    -- The default mode for interaction. "agentic" uses tools to automatically generate code, "legacy" uses the old planning method to generate code.
        -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
        -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
        -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
        auto_suggestions_provider = "claude",
        -- All request body fields (such as temperature, max_tokens, max_completion_tokens, reasoning_effort, options for ollama provider) of a provider
        -- have been moved from the top level of their respective provider's configuration to the extra_request_body field within that provider's configuration.
        -- https://github.com/yetone/avante.nvim/wiki/Provider-configuration-migration-guide
        providers = {
          claude = {
            model = "claude-3-5-sonnet-20241022",
            endpoint = "https://api.anthropic.com",
            timeout = 60000,                                                           -- Timeout in milliseconds, increase this for reasoning models
            api_key_name = "cmd:gopass show -n --password token/avante.anthropic.com", -- the shell command must prefixed with `^cmd:(.*)`
            -- api_key_name = 'cmd:sops -d --extract \'["ANTHROPIC_API_KEY"]\' --config ~/.config/.sops.yaml ~/.config/.env', -- the shell command must prefixed with `^cmd:(.*)`
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4096,
            },
          },
          openai = {
            model = "gpt-4o", -- Desired model (or use gpt-4o, etc.)
            endpoint = "https://api.openai.com/v1",
            timeout = 60000,  -- Timeout in milliseconds, increase this for reasoning models
            api_key_name = "cmd:gopass show -n --password token/avante.openai.com",
            -- api_key_name = 'cmd:sops -d --extract \'["OPENAI_API_KEY"]\' --config ~/.config/.sops.yaml ~/.config/.env', -- the shell command must prefixed with `^cmd:(.*)`
            extra_request_body = {
              temperature = 0,
              max_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
              --reasoning_effort = 'medium',                                    -- low|medium|high, only used for reasoning models
            },
          },
          copilot = {
            model = "gpt-4o-2024-08-06",
            endpoint = "https://api.githubcopilot.com",
            proxy = nil,            -- [protocol://]host[:port] Use this proxy
            allow_insecure = false, -- Allow insecure server connections
            timeout = 60000,        -- Timeout in milliseconds (1min)
            api_key_name = "cmd:gopass show -n --password token/avante.copilot.github.com",
            -- api_key_name = 'cmd:sops -d --extract \'["GITHUB_COPILOT_TOKEN"]\' --config ~/.config/.sops.yaml ~/.config/.env', -- the shell command must prefixed with `^cmd:(.*)`
            extra_request_body = {
              temperature = 0,    -- Temperature for the model, 0 for deterministic output
              max_tokens = 20480, -- Maximum number of tokens to generate in the completion
            },
          },
          gemini = {
            model = "gemini-2.0-flash", -- 'gemini-1.5-flash-latest',
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            timeout = 60000,            -- Timeout in milliseconds (1min)
            api_key_name = "cmd:gopass show -n --password token/avante.gemini.google.com",
            -- api_key_name = 'cmd:sops -d --extract \'["GEMINI_API_KEY"]\' --config ~/.config/.sops.yaml ~/.config/.env', -- the shell command must prefixed with `^cmd:(.*)`
            extra_request_body = {
              temperature = 0,    -- Temperature for the model, 0 for deterministic output
              max_tokens = 20480, -- Maximum number of tokens to generate in the completion
            },
          },
        },
      })
    end,
  },
}
