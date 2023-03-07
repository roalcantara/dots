-- Trims trailing whitespace and lines
-- https://github.com/cappyzawa/trim.nvim
_G.imports 'trim', (plugin) ->
   plugin.setup({
    -- ignore filetypes.
    ft_blocklist: {},
    trim_trailing: true,
    trim_last_line: true,
    trim_first_line: true,
    -- remove multiple blank lines
    patterns: {
      [[%s/\(\n\n\)\n\+/\1/]],   -- replace multiple blank lines with a single line
    },
  })
