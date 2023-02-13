-- Indent guides for Neovim
-- https://github.com/lukas-reineke/indent-blankline.nvim
require('neo/lib/functions/imports') 'indent_blankline', (plugin) ->
  plugin.setup{
    use_treesitter: true,
    show_end_of_line: true,
    show_current_context: true,
    show_current_context_start: false,
    indent_blankline_show_foldtext: true,
    show_trailing_blankline_indent: false,
    buftype_exclude: {'terminal', 'dashboard', 'packer', 'nofile'},
    filetype_exclude: {'help', 'startify', 'dashboard', 'packer', 'neogitstatus', 'NvimTree', 'Trouble'}
  }
