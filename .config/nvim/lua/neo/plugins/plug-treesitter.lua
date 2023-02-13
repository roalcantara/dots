return require('neo/lib/functions/imports')('nvim-treesitter/configs', function(plugin)
  local path = require('core/paths/path')
  vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
  vim.wo.foldmethod = 'expr'
  vim.opt.runtimepath:append(path.packer.start('nvim-treesitter.vim'))
  vim.opt.runtimepath:append('/usr/local/bin/tree-sitter')
  vim.opt.runtimepath:remove('/usr/share/nvim/runtime/parser')
  require('neo/lib/functions/imports')('nvim-treesitter/parsers', function(parsers)
    parsers.get_parser_configs().markdown = {
      install_info = {
        url = 'https://github.com/ikatyang/tree-sitter-markdown',
        files = {
          'src/parser.c',
          'src/scanner.cc'
        }
      }
    }
  end)
  return plugin.setup({
    indent = {
      enable = true
    },
    autotag = {
      enable = true
    },
    rainbow = {
      enable = true
    },
    autopairs = {
      enable = true
    },
    playground = {
      enable = true
    },
    highlight = {
      enable = true,
      use_languagetree = true,
      additional_vim_regex_highlighting = true
    },
    refactor = {
      highlight_definitions = {
        enable = true
      },
      smart_rename = {
        enable = true
      }
    },
    context_commentstring = {
      enable = true
    },
    tree_docs = {
      enable = true
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<c-backspace>'
      }
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner'
        }
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer'
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer'
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer'
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer'
        }
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner'
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner'
        }
      }
    },
    ensure_installed = {
      'bash',
      'cmake',
      'python',
      'ruby',
      'lua',
      'css',
      'dockerfile',
      'go',
      'graphql',
      'html',
      'javascript',
      'jsdoc',
      'json',
      'scss',
      'svelte',
      'toml',
      'typescript',
      'tsx',
      'yaml'
    }
  })
end)
