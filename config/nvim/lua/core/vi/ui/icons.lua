local function extends_icons()
  return vim.tbl_deep_extend('force', LazyVim.config.icons or {}, {
    misc = {
      dots = '󰇘',
      active_lsp = '',
      alarm = '󰞏',
      clock = '',
      tab = '',
      edit_circle = '󰣕',
      lock = '',
      file_question_mark = '󱀶',
      tree = '',
      wrap = '',
      arrow_left_bottom = '',
      spell = '󰓆',
      numbers = '󰎠',
      Eye = '󰈈',
      wand = '',
      diagnostic = '󰕥',
      bars = { '__', '▁▁', '▂▂', '▃▃', '▄▄', '▅▅', '▆▆', '▇▇', '██' },
    },
    ft = {
      octo = '',
      lua = '󰢱',
    },
    git = {
      added = ' ',
      modified = ' ',
      removed = ' ',
      branch = '',
    }
  })
end

return extends_icons
