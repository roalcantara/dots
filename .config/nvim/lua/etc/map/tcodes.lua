local tcodes
tcodes = function(key, from_part, do_lt, special)
  return vim.api.nvim_replace_termcodes(key, from_part, do_lt, special)
end
return tcodes
