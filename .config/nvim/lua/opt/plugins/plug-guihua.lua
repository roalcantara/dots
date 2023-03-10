return _G.imports('guihua/maps', function(plugin)
  return plugin.setup({
    maps = {
      save = '<C-s>',
      jump_to_list = '<C-w>k',
      jump_to_preview = '<C-w>j',
      prev = '<C-p>',
      next = '<C-n>',
      pageup = '<C-b>',
      pagedown = '<C-f>',
      confirm = '<C-o>',
      split = '<C-s>',
      vsplit = '<C-v>',
      close_view = '<C-x>'
    }
  })
end)
