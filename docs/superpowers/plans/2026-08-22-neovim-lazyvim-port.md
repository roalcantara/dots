# Neovim to LazyVim Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the current Kickstart-based Neovim configuration to a standard LazyVim-based setup, preserving all custom library code in `lua/core/`, global options, keymaps, autocommands, user commands, and plugin overrides.

**Architecture:** We will bootstrap LazyVim and register your custom plugins directory. The options, keymaps, and autocommands will be ported to the standard `lua/config/` locations, utilizing your custom `core/vi/maps` and `core/vi/au` engines. The plugin configuration files in `lua/plugins/` will be kept but adapted as deep-merged spec extensions (e.g., configuring `opts` instead of replacing `config`) to blend cleanly with LazyVim defaults.

**Tech Stack:** Neovim 0.10+, LazyVim, lazy.nvim, Mason, blink.cmp, conform.nvim, Lua.

---

## File Structure Changes

* **Create:**
  * `lua/config/lazy.lua`
* **Modify:**
  * `init.lua`
  * `lua/plugins/lsp.lua`
  * `lua/plugins/completion.lua`
  * `lua/plugins/formater.lua`
* **Preserved (Copied from Backup):**
  * `lua/config/options.lua`
  * `lua/config/keymaps.lua`
  * `lua/config/autocmds.lua`
  * `lua/config/usercmds.lua`
  * `lua/core/` (all directories & files)
  * `specs/` (all directories & files)
  * `tools/` (all directories & files)
  * `snippets/` (all directories & files)
  * `mise.toml`, `neovim.yml`, `.luarc.json`, `.gitignore`

---

## Tasks

### Task 1: Backup and Scaffolding

**Files:**
* Create: `lua/config/lazy.lua`
* Modify: `init.lua`

* [ ] **Step 1: Backup current configuration**
  Run a backup command. If `nvim.bak` exists, append a timestamp.
  Run:

  ```bash
  BACKUP_DIR="/Users/roalcantara/.config/nvim.bak"
  if [ -d "$BACKUP_DIR" ]; then
    BACKUP_DIR="${BACKUP_DIR}_$(date +%Y%m%d_%H%M%S)"
  fi
  cp -R /Users/roalcantara/.config/nvim "$BACKUP_DIR"
  echo "Backup created at: $BACKUP_DIR"
  ```

  Expected: Backup folder successfully created containing all current configurations.

* [ ] **Step 2: Scaffolding cleanup**
  Delete legacy Kickstart files from the active configuration directory (`/Users/roalcantara/.config/nvim`).
  Run:

  ```bash
  rm -rf /Users/roalcantara/.config/nvim/init.lua
  rm -rf /Users/roalcantara/.config/nvim/lua/config/
  mkdir -p /Users/roalcantara/.config/nvim/lua/config
  ```

* [ ] **Step 3: Write new `init.lua`**
  Write standard LazyVim entry point calling `config.lazy`.
  Run:

  ```bash
  cat << 'EOF' > /Users/roalcantara/.config/nvim/init.lua
  -- bootstrap lazy.nvim, LazyVim and your plugins
  require("config.lazy")
  EOF
  ```

* [ ] **Step 4: Write `lua/config/lazy.lua`**
  Write standard LazyVim bootstrapping code that registers the default LazyVim specifications plus your custom plugins.
  Run:

  ```bash
  cat << 'EOF' > /Users/roalcantara/.config/nvim/lua/config/lazy.lua
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazypath)

  require("lazy").setup({
    spec = {
      -- add LazyVim and import its plugins
      { "LazyVim/LazyVim", import = "lazyvim.plugins" },
      -- import your plugins/overrides
      { import = "plugins" },
    },
    defaults = {
      lazy = false,
      version = false,
    },
    install = { colorscheme = { "tokyonight" } },
    checker = { enabled = true, notify = false },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })
  EOF
  ```

* [ ] **Step 5: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/init.lua /Users/roalcantara/.config/nvim/lua/config/lazy.lua
  git commit -m "chore: scaffold LazyVim setup and backup old configuration"
  ```

---

### Task 2: Restoring Core Configurations

**Files:**
* Create: `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`, `lua/config/usercmds.lua`

* [ ] **Step 1: Copy core configuration files from backup**
  Run (substitute `$BACKUP_DIR` with the actual backup path printout from Task 1):

  ```bash
  # Identify your backup directory name first
  BACKUP_PATH=$(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)
  cp "$BACKUP_PATH/lua/config/options.lua" /Users/roalcantara/.config/nvim/lua/config/options.lua
  cp "$BACKUP_PATH/lua/config/keymaps.lua" /Users/roalcantara/.config/nvim/lua/config/keymaps.lua
  cp "$BACKUP_PATH/lua/config/autocmds.lua" /Users/roalcantara/.config/nvim/lua/config/autocmds.lua
  cp "$BACKUP_PATH/lua/config/usercmds.lua" /Users/roalcantara/.config/nvim/lua/config/usercmds.lua
  ```

* [ ] **Step 2: Explicitly load user commands in keymaps**
  Since LazyVim does not load `usercmds.lua` automatically, append it to `lua/config/keymaps.lua`.
  Run:

  ```bash
  echo "require('config/usercmds')" >> /Users/roalcantara/.config/nvim/lua/config/keymaps.lua
  ```

* [ ] **Step 3: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/lua/config/options.lua /Users/roalcantara/.config/nvim/lua/config/keymaps.lua /Users/roalcantara/.config/nvim/lua/config/autocmds.lua /Users/roalcantara/.config/nvim/lua/config/usercmds.lua
  git commit -m "feat: restore core configurations options, keymaps, autocmds, and usercmds"
  ```

---

### Task 3: Porting LSP and Tool Installer Specifications

**Files:**
* Modify: `lua/plugins/lsp.lua`

* [ ] **Step 1: Replace `lua/plugins/lsp.lua`**
  Modify the file to override the default LazyVim `"neovim/nvim-lspconfig"` spec. This maps your custom servers and configures `mason-tool-installer` as a clean dependency.
  Run:

  ```bash
  cat << 'EOF' > /Users/roalcantara/.config/nvim/lua/plugins/lsp.lua
  local has = require('core/vi/paths').has

  local ensured_installed = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            diagnostics = { globals = { 'vim', 'require' } },
          },
        },
      },
    },
    other_servers = {
      bashls = {},
      cssls = {},
      diagnosticls = {},
      docker_compose_language_service = {},
      dockerls = {},
      emmet_ls = {},
      eslint = {},
      html = {},
      jsonls = {},
      pyright = {},
      ruby_lsp = {},
      taplo = {},
      vimls = {},
      vtsls = {
        filetypes = {
          'javascript', 'javascriptreact', 'javascript.jsx',
          'typescript', 'typescriptreact', 'typescript.tsx',
        },
        settings = vim.tbl_deep_extend('force', {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = 'always' },
            suggest = { completeFunctionCalls = true },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = 'literals' },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        }, vim.fn.executable('bun') == 1 and { vtsls = { packageManager = 'bun' } } or {}),
      },
      yamlls = {},
    },
    tools = {
      'editorconfig-checker',
      'beautysh',
      'shellcheck',
      'shfmt',
      'stylua',
      'yamlfix',
      'yamlfmt',
      'yamllint',
      'prettier',
      'prettierd',
      { 'biome',         condition = has('biome') },
      { 'elixirls',      condition = has('elixir') },
      { 'eslint',        condition = has('eslint') },
      { 'gopls',         condition = has('go') },
      { 'gradle_ls',     condition = has('gradle') },
      { 'groovyls',      condition = has('groovy') },
      { 'kcl',           condition = has('kcl') },
      { 'kotlin_lsp',    condition = has('kotlin') },
      { 'marksman',      condition = has('marksman') },
      { 'nxls',          condition = has('nxls') },
      { 'postgres_lsp',  condition = has('psql') },
      { 'pyrefly',       condition = has('python') },
      { 'ruby_lsp',      condition = has('ruby') },
      { 'rust-analyzer', condition = has('rustc') },
      { 'ruff',          condition = has('python') },
      { 'gofumpt',       condition = has('go') },
      { 'golines',       condition = has('go') },
      { 'gomodifytags',  condition = has('go') },
      { 'gotests',       condition = has('go') },
      { 'black',         condition = has('python') },
      { 'isort',         condition = has('python') },
      { 'rustfmt',       condition = has('rust') },
    }
  }

  return {
    {
      'neovim/nvim-lspconfig',
      opts = function(_, opts)
        -- Set custom diagnostics text styles using icons
        local icons = require('core/ui/icons/icons_list')
        vim.diagnostic.config({
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
              [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
              [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
              [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
            },
          },
          virtual_lines = {
            current_line = true,
          },
        })

        -- Copy server setup logic to opts
        opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, ensured_installed.servers)
        
        -- Enable non-mason servers
        for server, config in pairs(ensured_installed.other_servers) do
          opts.servers[server] = config
        end
      end,
      dependencies = {
        {
          'WhoIsSethDaniel/mason-tool-installer.nvim',
          config = function()
            local ensure_installed = vim.tbl_keys(ensured_installed.servers or {})
            vim.list_extend(ensure_installed, ensured_installed.tools)
            require('mason-tool-installer').setup { ensure_installed = ensure_installed }
          end
        }
      }
    }
  }
  EOF
  ```

* [ ] **Step 2: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/lua/plugins/lsp.lua
  git commit -m "feat: port LSP configurations and mason-tool-installer specs to LazyVim"
  ```

---

### Task 4: Porting Blink.cmp Completion Specifications

**Files:**
* Modify: `lua/plugins/completion.lua`

* [ ] **Step 1: Replace `lua/plugins/completion.lua`**
  Modify completion spec to extend LazyVim's default `"saghen/blink.cmp"` using `opts`.
  Run:

  ```bash
  cat << 'EOF' > /Users/roalcantara/.config/nvim/lua/plugins/completion.lua
  return {
    {
      'saghen/blink.cmp',
      dependencies = {
        { "nvim-tree/nvim-web-devicons", opts = {} },
        {
          'folke/lazydev.nvim',
          ft = 'lua',
          opts = {},
        },
        'rafamadriz/friendly-snippets',
        'onsails/lspkind.nvim',
        'disrupted/blink-cmp-conventional-commits',
        'fang2hou/blink-copilot',
        {
          'Kaiser-Yang/blink-cmp-git',
          dependencies = { 'nvim-lua/plenary.nvim' },
        },
        'xzbdmw/colorful-menu.nvim',
      },
      opts = function(_, opts)
        local ui_helper = require('core/ui/ui_helper')
        local paths = require('core/vi/paths')

        -- Deep extend / replace with custom settings
        opts.snippets = {
          expand = function(snippet)
            vim.snippet.expand(snippet)
          end,
          active = function(filter)
            if filter and filter.direction then
              return vim.snippet.active({ direction = filter.direction })
            end
            return vim.snippet.active()
          end,
          jump = function(direction)
            vim.snippet.jump(direction)
          end,
        }

        opts.appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = 'mono',
          kind_icons = {
            claude = '󰋦',
            openai = '󱢆',
            codestral = '󱎥',
            gemini = '',
            Groq = '',
            Openrouter = '󱂇',
            Ollama = '󰳆',
            ['Llama.cpp'] = '󰳆',
            Deepseek = '',
          },
        }

        opts.cmdline = {
          enabled = true,
          keymap = { preset = 'cmdline' },
          completion = {
            trigger = {
              show_on_blocked_trigger_characters = {},
              show_on_x_blocked_trigger_characters = {},
            },
            list = {
              selection = {
                preselect = true,
                auto_insert = true,
              },
            },
            menu = {
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ':' or ctx.mode == 'cmdwin'
              end,
            },
            ghost_text = { enabled = true },
          }
        }

        opts.sources = {
          default = function(ctx)
            local success, node = pcall(vim.treesitter.get_node)
            if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
              return { 'buffer', 'copilot' }
            else
              return { 'copilot', 'lazydev', 'lsp', 'path', 'snippets', 'buffer' }
            end
          end,
          providers = {
            copilot = {
              name = 'copilot',
              module = 'blink-copilot',
              score_offset = 100,
              async = true,
            },
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100,
            },
            lsp = {
              name = 'LSP',
              module = 'blink.cmp.sources.lsp',
              transform_items = function(_, items)
                return vim.tbl_filter(function(item)
                  return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text
                end, items)
              end,
              opts = { tailwind_color_icon = '██' },
              enabled = true,
              async = false,
              timeout_ms = 2000,
              should_show_items = true,
              max_items = nil,
              min_keyword_length = 0,
              fallbacks = { 'buffer' },
              score_offset = 0,
              override = nil,
            },
            snippets = {
              name = 'snippets',
              module = 'blink.cmp.sources.snippets',
              score_offset = -3,
              opts = {
                friendly_snippets = true,
                search_paths = { paths.stdpaths.snippets },
                global_snippets = { 'all' },
                extended_filetypes = {},
                ignored_filetypes = {},
              },
            },
            path = {
              module = 'blink.cmp.sources.path',
              score_offset = 3,
              fallbacks = { 'buffer' },
              opts = {
                trailing_slash = true,
                label_trailing_slash = true,
                get_cwd = function(context)
                  return paths.bufcwd(context.bufnr)
                end,
                show_hidden_files_by_default = false,
                ignore_root_slash = false,
              },
            },
            cmdline = {
              module = 'blink.cmp.sources.cmdline'
            },
            omni = {
              module = 'blink.cmp.sources.complete_func',
              enabled = function()
                return vim.bo.omnifunc ~= 'v:lua.vim.lsp.omnifunc'
              end,
              opts = {
                complete_func = function()
                  return vim.bo.omnifunc
                end,
              },
            },
          },
        }

        opts.keymap = {
          ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
          ['<C-e>'] = { 'hide', 'fallback' },
          ['<Tab>'] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            'snippet_forward',
            'fallback_to_mappings',
          },
          ['<S-Tab>'] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.snippet_backward()
              end
            end,
            'fallback_to_mappings',
          },
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback_to_mappings', 'fallback' },
        }

        opts.completion = {
          menu = {
            enabled = true,
            border = nil,
            min_width = 15,
            max_height = 20,
            winblend = 0,
            scrolloff = 2,
            scrollbar = false,
            auto_show = true,
            draw = {
              align_to = 'label',
              padding = { 1, 1 },
              gap = 2,
              cursorline_priority = 10000,
              treesitter = { 'lsp' },
              components = {
                kind = {
                  ellipsis = false,
                  width = { fill = true },
                  text = function(ctx) return ctx.kind end,
                  highlight = ui_helper.get_kind_highlight,
                },
                kind_icon = {
                  text = ui_helper.get_kind_icon_with_gap,
                  highlight = ui_helper.get_kind_highlight,
                },
                label = {
                  text = ui_helper.get_label_text,
                  highlight = ui_helper.get_label_highlight,
                },
                label_description = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.label_description end,
                  highlight = 'BlinkCmpLabelDescription',
                },
                source_name = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.source_name end,
                  highlight = 'BlinkCmpSource',
                },
                source_id = {
                  width = { max = 30 },
                  text = function(ctx) return ctx.source_id end,
                  highlight = 'BlinkCmpSource',
                },
              },
              columns = { { 'kind_icon' }, { 'label', gap = 1 } },
            },
            direction_priority = ui_helper.detect_window_direction_order_priority,
          },
          documentation = {
            window = {
              border = nil,
              scrollbar = false,
              winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
            },
            auto_show = false,
            auto_show_delay_ms = 10000,
            treesitter_highlighting = true,
          },
          list = {
            max_items = 200,
            selection = {
              preselect = function(ctx)
                return not require('blink.cmp').snippet_active({ direction = 1 })
              end,
              auto_insert = true,
            },
            cycle = {
              from_bottom = true,
              from_top = true,
            },
          },
          accept = {
            auto_brackets = {
              enabled = true,
            },
          },
          ghost_text = {
            enabled = true,
            show_with_selection = true,
            show_without_selection = false,
            show_with_menu = true,
            show_without_menu = true,
          },
        }

        opts.signature = {
          enabled = false,
          trigger = {
            enabled = false,
            show_on_keyword = false,
            blocked_trigger_characters = {},
            blocked_retrigger_characters = {},
            show_on_trigger_character = true,
            show_on_insert = false,
            show_on_insert_on_trigger_character = true,
          },
          window = {
            min_width = 1,
            max_width = 100,
            max_height = 10,
            border = 'rounded',
            winblend = 0,
            winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
            scrollbar = false,
            direction_priority = ui_helper.detect_window_direction_order_priority,
            treesitter_highlighting = true,
            show_documentation = false,
          },
        }

        opts.fuzzy = { implementation = 'prefer_rust_with_warning' }
      end,
    },
  }
  EOF
  ```

* [ ] **Step 2: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/lua/plugins/completion.lua
  git commit -m "feat: port blink.cmp completion specs to LazyVim"
  ```

---

### Task 5: Porting Conform.nvim Formatting Specs

**Files:**
* Modify: `lua/plugins/formater.lua`

* [ ] **Step 1: Replace `lua/plugins/formater.lua`**
  Modify conform.nvim spec to extend LazyVim's default formatting using `opts`.
  Run:

  ```bash
  cat << 'EOF' > /Users/roalcantara/.config/nvim/lua/plugins/formater.lua
  return {
    {
      'stevearc/conform.nvim',
      opts = function(_, opts)
        opts.formatters_by_ft = {
          lua = { 'stylua' },
          python = { 'isort', 'black' },
          rust = { 'rustfmt' },
          javascript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
          javascriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
          typescript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
          typescriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        }
        
        opts.default_format_opts = {
          lsp_format = 'fallback',
        }
        
        opts.format_on_save = {
          timeout_ms = 500,
        }
        
        opts.log_level = vim.log.levels.ERROR
        opts.notify_on_error = true
        opts.notify_no_formatters = true
      end,
    },
  }
  EOF
  ```

* [ ] **Step 2: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/lua/plugins/formater.lua
  git commit -m "feat: port conform.nvim formatting specifications to LazyVim"
  ```

---

### Task 6: Custom Specifications Alignment

**Files:**
* Modify: `lua/plugins/coding.lua`, `lua/plugins/ui.lua`, `lua/plugins/markdown.lua`, `lua/plugins/ai.lua`

* [ ] **Step 1: Align `coding.lua`**
  Ensure dependencies of `mini.pairs` or `ts-comments` align cleanly and don't overwrite standard LazyVim setups.
  Since `mini.pairs` config is handled by `config = neo.mini.pairs` which loads your custom toggle wrapper, we retain it exactly as-is. We also ensure any other specifications remain intact.
  Run:

  ```bash
  # Restore legacy coding.lua from backup to active folder
  BACKUP_PATH=$(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)
  cp "$BACKUP_PATH/lua/plugins/coding.lua" /Users/roalcantara/.config/nvim/lua/plugins/coding.lua
  ```

* [ ] **Step 2: Restore and align `ui.lua`**
  Run:

  ```bash
  BACKUP_PATH=$(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)
  cp "$BACKUP_PATH/lua/plugins/ui.lua" /Users/roalcantara/.config/nvim/lua/plugins/ui.lua
  ```

* [ ] **Step 3: Restore and align `markdown.lua`**
  Run:

  ```bash
  BACKUP_PATH=$(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)
  cp "$BACKUP_PATH/lua/plugins/markdown.lua" /Users/roalcantara/.config/nvim/lua/plugins/markdown.lua
  ```

* [ ] **Step 4: Restore and align `ai.lua`**
  Run:

  ```bash
  BACKUP_PATH=$(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)
  cp "$BACKUP_PATH/lua/plugins/ai.lua" /Users/roalcantara/.config/nvim/lua/plugins/ai.lua
  ```

* [ ] **Step 5: Commit changes**
  Run:

  ```bash
  git add /Users/roalcantara/.config/nvim/lua/plugins/coding.lua /Users/roalcantara/.config/nvim/lua/plugins/ui.lua /Users/roalcantara/.config/nvim/lua/plugins/markdown.lua /Users/roalcantara/.config/nvim/lua/plugins/ai.lua
  git commit -m "feat: restore and align coding, ui, markdown, and ai specifications"
  ```

---

### Task 7: Supporting Files & Assets Restoration

**Files:**
* Preserved: `lua/core/`, `specs/`, `tools/`, `snippets/`, `.luarc.json`, `mise.toml`, `neovim.yml`

* [ ] **Step 1: Verify `lua/core/` presence**
  Since we cleaned only `lua/config/` and individual files in `lua/plugins/`, the `lua/core/` folder is intact. Confirm it matches the backup.
  Run:

  ```bash
  diff -r /Users/roalcantara/.config/nvim/lua/core/ $(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)/lua/core/
  ```

  Expected: No output (which means they are completely identical).

* [ ] **Step 2: Verify `specs/`, `tools/`, and symlinks**
  Confirm the rest of the folders match.
  Run:

  ```bash
  diff -r /Users/roalcantara/.config/nvim/specs/ $(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)/specs/
  diff -r /Users/roalcantara/.config/nvim/tools/ $(ls -td /Users/roalcantara/.config/nvim.bak* | head -n 1)/tools/
  ```

  Expected: No differences found.

---

### Task 8: Validation and Health Verification

* [ ] **Step 1: Run headless checkhealth**
  Verify there are no syntax errors or initialization errors on startup.
  Run:

  ```bash
  nvim --headless -c "checkhealth" -c "qa"
  ```

  Expected: Command exits successfully with exit code 0.

* [ ] **Step 2: Profile startup time**
  Ensure LazyVim boots cleanly and is fully optimized.
  Run:

  ```bash
  nvim --headless -c "Lazy profile" -c "qa"
  ```

  Expected: Profiler log outputs successfully, displaying startup times.

* [ ] **Step 3: List active plugins**
  Verify that both default LazyVim plugins and your custom configurations are loaded.
  Run:

  ```bash
  nvim --headless +"lua local lazy = require('lazy'); for _, p in ipairs(lazy.plugins()) do print(string.format('%s|loaded=%s', p.name, tostring(p._.loaded ~= nil))) end" +quit
  ```

  Expected: Output list contains `tokyonight`, `blink.cmp`, `conform.nvim`, `snacks.nvim`, and your other custom specs.
