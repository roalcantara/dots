local _list_0 = {
  'core/options',
  'core/plugins',
  'core/theme'
}
for _index_0 = 1, #_list_0 do
  local package = _list_0[_index_0]
  pcall(require, package)
end
