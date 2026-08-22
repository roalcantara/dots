local out = {}
for _, p in ipairs(require('lazy').plugins()) do
  table.insert(out, p.name)
end
table.sort(out)
io.write(table.concat(out, '\n'), '\n')
