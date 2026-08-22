local out = {}
for _, a in ipairs(vim.api.nvim_get_autocmds({})) do
  table.insert(out, table.concat({ a.group_name or '<none>', a.event, a.pattern or '' }, '\t'))
end
table.sort(out)
io.write(table.concat(out, '\n'), '\n')
