-- A snazzy bufferline for Neovim
-- https://github.com/akinsho/bufferline.nvim
require('neo/lib/functions/imports') 'bufferline', (plugin) ->
  symbols = {error: ' ', warning: ' ', info: ' '}
  plugin.setup{
    options: {
      mode: 'buffers', -- set to 'tabs' to only show tabpages instead
      numbers: (opts) -> string.format('%s', opts.raise(opts.ordinal)),
      close_command: 'bdelete! %d', -- can be a string | function, see 'Mouse actions'
      right_mouse_command: 'bdelete! %d', -- can be a string | function, see 'Mouse actions'
      left_mouse_command: 'buffer %d', -- can be a string | function, see 'Mouse actions'
      middle_mouse_command: nil, -- can be a string | function, see 'Mouse actions'
      -- NOTE: this plugin is designed with this icon in mind,
      -- and so changing this is NOT recommended, this is intended
      -- as an escape hatch for people who cannot bear it for whatever reason
      buffer_close_icon: '',
      modified_icon: '●',
      close_icon: '',
      left_trunc_marker: '',
      right_trunc_marker: '',
      --- name_formatter can be used to change the buffer's label in the bufferline.
      --- Please note some names can/will break the
      --- bufferline so use this at your discretion knowing that it has
      --- some limitations that will *NOT* be fixed.
      name_formatter: (buf) ->
        -- buf contains a 'name', 'path' and 'bufnr'
        -- remove extension from markdown files
        vim.fn.fnamemodify(buf.name, ':t:r') if buf.name\match('%.md'),
      max_name_length: 18,
      max_prefix_length: 15, -- prefix used when a buffer is de-duplicated
      tab_size: 18,
      diagnostics: 'nvim_lsp',
      diagnostics_update_in_insert: false,
      diagnostics_indicator: (total, _, diagnostics) ->
        result = {}
        for name, count in pairs diagnostics
          table.insert(result, symbols[name] .. count) if symbols[name] and total > 0
        res = table.concat(result, ' ')
        #res > 0 and ' ' .. res or '',
      -- NOTE: this will be called a lot so don't do any heavy processing here
      custom_filter: (buf_number, buf_numbers) ->
        -- filter out by it's index number in list (don't show first buffer)
        return true if buf_numbers[1] ~= buf_number
        -- filter out filetypes you don't want to see
        return true if vim.bo[buf_number].filetype ~= 'dashboard'
        -- filter out by buffer name
        return true if vim.fn.bufname(buf_number) ~= 'dashboard'
        -- filter out based on arbitrary rules
        -- e.g. filter out vim wiki buffer from tabline in your work repo
        -- if vim.fn.getcwd() == '<work-repo>' and vim.bo[buf_number].filetype ~= 'wiki' then return true end
      ,
      offsets: {
        {filetype: 'DiffviewFiles', text: 'Diff View', highlight: 'PanelHeading', padding: 1, text_align: 'left'},
        {
          filetype: 'NvimTree',
          text: () -> vim.fn.getcwd(),
          highlight: 'Directory',
          text_align: 'left'
        }
      },
      color_icons: true, -- whether or not to add the filetype icon highlights
      show_buffer_icons: true, -- disable filetype icons for buffers
      show_buffer_close_icons: true,
      show_buffer_default_icon: true, -- whether or not an unrecognised filetype should show a default icon
      show_close_icon: true,
      show_tab_indicators: true,
      persist_buffer_sort: true, -- whether or not custom sorted buffers should persist
      -- can also be a table containing 2 custom separators [focused and unfocused]. eg: { '|', '|' }
      -- 'slant' | 'thick' | { 'any', 'any' },
      separator_style: 'thin',
      enforce_regular_tabs: true,
      always_show_bufferline: false,
      sort_by: 'insert_at_end'
    }
  }
