return require('neo/lib/functions/imports')('bufferline', function(plugin)
  local symbols = {
    error = ' ',
    warning = ' ',
    info = ' '
  }
  return plugin.setup({
    options = {
      mode = 'buffers',
      numbers = function(opts)
        return string.format('%s', opts.raise(opts.ordinal))
      end,
      close_command = 'bdelete! %d',
      right_mouse_command = 'bdelete! %d',
      left_mouse_command = 'buffer %d',
      middle_mouse_command = nil,
      buffer_close_icon = '',
      modified_icon = '●',
      close_icon = '',
      left_trunc_marker = '',
      right_trunc_marker = '',
      name_formatter = function(buf)
        if buf.name:match('%.md') then
          return vim.fn.fnamemodify(buf.name, ':t:r')
        end
      end,
      max_name_length = 18,
      max_prefix_length = 15,
      tab_size = 18,
      diagnostics = 'nvim_lsp',
      diagnostics_update_in_insert = false,
      diagnostics_indicator = function(total, _, diagnostics)
        local result = { }
        for name, count in pairs(diagnostics) do
          if symbols[name] and total > 0 then
            table.insert(result, symbols[name] .. count)
          end
        end
        local res = table.concat(result, ' ')
        return #res > 0 and ' ' .. res or ''
      end,
      custom_filter = function(buf_number, buf_numbers)
        if buf_numbers[1] ~= buf_number then
          return true
        end
        if vim.bo[buf_number].filetype ~= 'dashboard' then
          return true
        end
        if vim.fn.bufname(buf_number) ~= 'dashboard' then
          return true
        end
      end,
      offsets = {
        {
          filetype = 'DiffviewFiles',
          text = 'Diff View',
          highlight = 'PanelHeading',
          padding = 1,
          text_align = 'left'
        },
        {
          filetype = 'NvimTree',
          text = function()
            return vim.fn.getcwd()
          end,
          highlight = 'Directory',
          text_align = 'left'
        }
      },
      color_icons = true,
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_buffer_default_icon = true,
      show_close_icon = true,
      show_tab_indicators = true,
      persist_buffer_sort = true,
      separator_style = 'thin',
      enforce_regular_tabs = true,
      always_show_bufferline = false,
      sort_by = 'insert_at_end'
    }
  })
end)
