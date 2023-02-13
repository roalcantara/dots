-- nvim-cmp source for dictionary.
-- https://github.com/uga-rosa/cmp-dictionary
require('neo/lib/functions/imports') 'cmp_dictionary', (plugin) ->
  plugin.setup {
    dic: {
      -- ['*']: {'/usr/share/dict/words'},
      -- ['lua']: 'path/to/lua.dic',
      -- ['javascript,typescript']: {'path/to/js.dic', 'path/to/js2.dic'},
      -- filename: {['xmake.lua']: {'path/to/xmake.dic', 'path/to/lua.dic'}},
      -- filepath: {['%.tmux.*%.conf']: 'path/to/tmux.dic'},
      -- spelllang: {en: 'path/to/english.dic'}
    },
    -- The following are default values.
    exact: 2,
    first_case_insensitive: true,
    document: false,
    document_command: 'wn %s -over',
    async: false,
    capacity: 5,
    debug: false
  }
