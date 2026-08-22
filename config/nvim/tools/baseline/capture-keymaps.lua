local out = {}
for _, mode in ipairs({ 'n', 'i', 'v', 'x', 'o', 's', 't', 'c' }) do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    table.insert(out, table.concat({ mode, m.lhs, m.desc or '' }, '\t'))
  end
end
table.sort(out)
io.write(table.concat(out, '\n'), '\n')
