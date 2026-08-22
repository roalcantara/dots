local out = {}
for name in pairs(package.loaded) do
  if name:match('^core[/.]') then table.insert(out, name) end
end
table.sort(out)
io.write(table.concat(out, '\n'), '\n')
