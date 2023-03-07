return _G.imports('indent_blankline', function(plugin)
  return plugin.setup({
    use_treesitter = true,
    show_end_of_line = true,
    show_current_context = true,
    show_current_context_start = false,
    indent_blankline_show_foldtext = true,
    show_trailing_blankline_indent = false,
    buftype_exclude = {
      'terminal',
      'dashboard',
      'packer',
      'nofile'
    },
    filetype_exclude = {
      'help',
      'startify',
      'dashboard',
      'packer',
      'neogitstatus',
      'NvimTree',
      'Trouble'
    }
  })
end)
