return require('neo/lib/functions/imports')('cmp_dictionary', function(plugin)
  return plugin.setup({
    dic = { },
    exact = 2,
    first_case_insensitive = true,
    document = false,
    document_command = 'wn %s -over',
    async = false,
    capacity = 5,
    debug = false
  })
end)
