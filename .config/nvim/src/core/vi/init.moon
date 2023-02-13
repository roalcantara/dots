isNullOrEmpty = require 'neo/lib/lang/is_null'
is_table = require 'neo/lib/lang/is_table'
to_table = require 'neo/lib/lang/to_table'
props = {
  g: vim.g                            -- Global editor variables. Key with no value returns nil.
  b: vim.b                            -- Buffer-scoped variables for the current buffer. Invalid or unset key returns nil. Can be indexed with an integer to access variables for a specific buffer.
  w: vim.w                            -- Window-scoped variables for the current window. Invalid or unset key returns nil. Can be indexed with an integer to access variables for a specific window.
  t: vim.t                            -- Tabpage-scoped variables for the current tabpage. Invalid or unset key returns nil. Can be indexed with an integer to access variables for a specific tabpage.
  v: vim.v                            -- vim variables. Invalid or unset key returns nil.
  env: vim.env                        -- Environment variables defined in the editor session. Invalid or unset key returns nil. See expand-env and :let-environment for the Vimscript behavior.

  --- Get or set Vim options. Like :set. Invalid key is an error.
  --- @example To set a boolean toggle in Lua: vim.o.number = true (Vimscript: set number)
  --- @example To set a string value in Lua: vim.o.wildignore = '*.o,*.a,__pycache__' (Vimscript: set wildignore=*.o,*.a,__pycache__)
  --- Note: this works on both buffer-scoped and window-scoped options using the current buffer and window.
  o: vim.o

  -- Like :set and :setlocal.
  -- Get or set buffer-scoped options for the buffer with number {bufnr}.
  -- If [{bufnr}] is omitted then the current buffer is used. Invalid {bufnr} or key is an error.
  -- @example vim.bo[vim.api.nvim_get_current_buf()].buflisted = true (using a specific buffer number)
  -- @example vim.bo.buflisted = true (using the current buffer number)
  -- NOTE: It must NOT be confused with local-options and :setlocal, instead use:
  -- @example nvim_get_option_value(OPTION, { scope = 'local', buf = bufid })
  -- @example nvim_set_option_value(OPTION, VALUE, { scope = 'local', buf = bufid }
  bo: vim.bo                         -- NOTE: .

  -- Like :set.
  -- Get or set window-scoped options for the window with handle {winid}.
  -- If [{winid}] is omitted then the current window is used. Invalid {winid} or key is an error.
  -- @example vim.wo[vim.api.nvim_get_current_win()].number = true (using a specific buffer number)
  -- @example vim.wo.number = true  (using the current buffer number)
  -- NOTE: It must NOT be confused with local-options and :setlocal, instead use:
  -- @example nvim_get_option_value(OPTION, { scope = 'local', win = winid })
  -- @example nvim_set_option_value(OPTION, VALUE, { scope = 'local', win = winid }
  wo: vim.wo

  --- Like :setglobal
  --- Get or set global options. Invalid key is an error.
  --- Only accesses the global value of a global-local option, see :setglobal.
  --- Note: It differs from vim.o because
  ---       - it access the global option value
  ---       - and thus is mostly useful for use with global-local options.
  go: vim.go

  --- behaves like :setglobal
  --- Given two windows, both on C source code that uses the global 'makeprg' option.
  ---   When running `:setglobal makeprg=gmake` in one of the two windows
  ---   Then the other window will not switch the `makeprg` to `gmake`
  ---Given that I want to switch back to using the global value in the Perl window
  ---   When making the local value empty running `:setglobal makeprg=`
  ---   Then the Perl window will switch the `makeprg` to the global value
  opt_global: vim.opt_global

  --- Like :set but allows to conveniently interacting with Lua's list-and map-style opts
  ---
  --- Given two windows, both on C source code that uses the global 'makeprg' option.
  ---   When running `:set makeprg=gmake` in one of the two windows
  ---   Then the other window will switch the `makeprg` to `gmake` as well.
  ---
  --- Setting map-style opts compairson
  --- @example (w/ Vimscript)   set wildignore=*.o,*.a,__pycache__
  --- @example (w/ vim.o)       vim.o.wildignore = '*.o,*.a,__pycache__'
  --- @example (w/ vim.opt)     vim.opt.wildignore = { '*.o', '*.a', '__pycache__' }
  ---
  --- Setting map-style opts
  --- @example: (w/ Vimscript)  set listchars=space:_,tab:>~
  --- @example: (w/ vim.o)      vim.o.listchars = 'space:_,tab:>~'
  --- @example: (w/ vim.opt)    vim.opt.listchars = { space = '_', tab = '>~' }
  ---
  --- Append a value to string-style options:
  --- @example (see :set+=)      vim.opt.wildignore:append { "*.pyc", "node_modules" }
  ---
  --- Prepend a value to string-style options
  --- @example (see :set^=)      vim.opt.wildignore:prepend { "new_first_value" }
  ---
  --- Remove a value from string-style options:
  --- @example (see :set-=)      vim.opt.wildignore:remove { "node_modules" }
  ---
  --- vim.opt:get()
  --- vim.opt returns an Option object, not the value of the option, which is accessed through vim.opt:get():
  --- @example: (w/ Vimscript)  echo &wildignore
  --- @example: (w/ vim.o)      print(vim.o.wildignore)
  --- @example: (w/ vim.opt)    vim.pretty_print(vim.opt.wildignore:get())
  ---
  --- For comma-separated lists values, it returns an array with the values as entries:
  --- @example: vim.pretty_print(vim.opt.wildignore:get()) => { "*.pyc", "*.o", }
  ---
  --- For comma-separated maps values, it returns a dictionary with the keys and values as entries:
  --- @example: vim.pretty_print(vim.opt.listchars:get()) => { space = "_", tab = ">~", }
  ---
  --- For lists of flags values, it returns a set with the flags as keys and true as entries:
  --- @example: vim.pretty_print(vim.opt.formatoptions:get()) => { n = true, j = true, c = true, ... }
  opt: vim.opt

  --- behaves like :setlocal
  --- Given two windows, one editing a Perl file and another editing a C file.
  ---   When running `:setlocal makeprg=perlmake` in the Perl window
  ---   Then the Perl window will switch the `makeprg` to `perlmake`
  ---   But the C window will not change the `makeprg`
  ---Given that I want to switch back to using the global value in the Perl window
  ---   When making the local value empty running `:setlocal makeprg=`
  ---   Then the Perl window will switch the `makeprg` to the global value
  opt_local: vim.opt_local
}
get = (key) -> vim[key]
cmd = (command) -> vim.cmd(command)  -- execute vim commands
append = (key, value) ->
  vim[key] += value unless is_table(key)
  if is_table(key)
    for k,v in pairs key
      append(k, v)

prepend = (key, value) ->
  vim[key] = "#{value}#{vim[key]}" unless is_table(key)
  if is_table(key)
    for k,v in pairs key
      prepend(k, v)

set_opt_or_var = (ctx, key, value) ->
  if isNullOrEmpty(key)
    print('[W] [LOAD/#{ctx}] (${key}=${value}) skipped! key: "${key}"..')
  else
    props[ctx][key] = value
    props['go'][key] = value if (ctx == 'bo' or ctx == 'wo')

--- Set command (vim.cmd)
--- Only the command argument is needed, output is always set to false
--- @example set_cmd('setlocal iskeyword+=-')
set_cmd = (value) ->
  if isNullOrEmpty(value)
    print('[W] [cmd] skipped! Value: "${value}"..')
  else
    cmd(value)

vi = {
  sysname: () -> tostring(vim.loop.os_uname.sysname)

  is_darwin: () -> vim.loop.os_uname.sysname == 'Darwin'
  --- Set global variable (vim.g)
  --- @example set_var_g('my_var', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.g
  set_var_g: (key, value) ->
    set_opt_or_var('g', key, value)

  --- Set buffer variables (vim.b)
  --- @example set_var_b('my_var', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.b
  set_var_b: (key, value) ->
    set_opt_or_var('b', key, value)

  --- Set window variables (vim.w)
  --- @example set_var_w('my_var', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.w
  set_var_w: (key, value) ->
    set_opt_or_var('w', key, value)

  --- Set tabpage variables (vim.t)
  --- @example set_var_t('my_var', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.t
  set_var_t: (key, value) ->
    set_opt_or_var('t', key, value)

  --- Set predefined Vim variables (vim.v)
  --- @example set_var_v('my_var', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.v
  set_var_v: (key, value) ->
    set_opt_or_var('v', key, value)

  --- Set environment variables (vim.env)
  --- @example set_envar_env('my_envar', 'my_value')
  --- @see https://neovim.io/doc/user/lua.html#vim.env
  set_envar_env: (key, value) ->
    set_opt_or_var('env', key, value)

  --- Set global option (vim.go)
  --- Like :setglobal but accesses the global option value and thus is mostly useful for use with global-local options.
  --- @example set_go('my_var', 'my_value')
  set_go: (key, value) ->
    set_opt_or_var('go', key, value)

  --- Set buffer-scoped option (vim.bo)
  --- Equivalent to both :set and :setlocal. If [{bufnr}] is omitted then the current buffer is used. Invalid {bufnr} or key is an error.
  --- @example set_bo('my_var', 'my_value')
  set_bo: (key, value) ->
    set_opt_or_var('bo', key, value)

  --- Set buffer-scoped option (vim.wo)
  --- Equivalent to both :set and :setlocal. If [{winid}] is omitted then the current window is used. Invalid {winid} or key is an error.
  --- @example set_bo('my_var', 'my_value')
  set_wo: (key, value) ->
    set_opt_or_var('wo', key, value)

  --- Set option (vim.opt)
  --- Like ":set" but set only the global value for a local option without changing the local value.
  --- @example set_opt('number', true)
  set_opt: (key, value) ->
    set_opt_or_var('opt', key, value)

  --- Set global option (vim.opt_global)
  --- Sets only the global value for a local option without changing the local value
  --- behaves like :setglobal
  --- @example set_opt_global('number', true)
  set_opt_global: (key, value) ->
    set_opt_or_var('opt_global', key, value)

  --- Set local option (vim.opt_local)
  --- Sets only the global value for a local option without changing the local value
  --- vim.opt_local: behaves like :setlocal
  --- @example set_opt_local('number', true)
  set_opt_local: (key, value) ->
    set_opt_or_var('opt_local', key, value)

  --- Set vim options or variables
  ---@exampple set({
  ---  g: { loaded_gzip: 1 }             -- set global variable
  ---  o: { background: 'dark' }}        -- global options
  ---  go: { background: 'dark' }}       -- global options
  ---  bo: { fileencoding: 'utf-8' }}    -- global and buffer local options
  ---  wo: { list: true, number: true }} -- global and window local options
  --- opt: { terse: true }}              -- Set options
  --- })
  -- @see https://github.com/nanotee/nvim-lua-guide
  set: (...) ->
    settings = if is_table(...) then ... else to_table(...)
    for ctx, values in pairs settings
      for key, value in pairs values
        set_opt_or_var(ctx, key, value)

  --- Set vim commands (Alias for vim.api.nvim_exec())
  -- Only the command argument is needed, output is always set to false.
  --- @example cmds(
  --- 'packadd packer.nvim'
  --- 'setlocal iskeyword+=-'
  --- )
  -- @see https://github.com/nanotee/nvim-lua-guide
  cmd: (...) ->
    settings = if is_table(...) then ... else to_table(...)
    for _, value in pairs settings
      set_cmd(value)

  --- Set global variables (vim.g)
  --- Usually used to plugins settings and the leader key
  --- @see https://neovim.io/doc/user/lua.html#vim.g
  --- @see https://neovim.io/doc/user/eval.html#g:
  --- @see https://github.com/nanotee/nvim-lua-guide#managing-vim-internal-variables
  put: require('core/vi/put')

  --- Set global variables (vim.g)
  --- Usually used to plugins settings and the leader key
  --- @see https://neovim.io/doc/user/lua.html#vim.g
  --- @see https://neovim.io/doc/user/eval.html#g:
  --- @see https://github.com/nanotee/nvim-lua-guide#managing-vim-internal-variables
  sys: require('core/vi/system')

  --- Set global variables (vim.g)
  --- Usually used to plugins settings and the leader key
  --- @see https://neovim.io/doc/user/lua.html#vim.g
  --- @see https://neovim.io/doc/user/eval.html#g:
  --- @see https://github.com/nanotee/nvim-lua-guide#managing-vim-internal-variables
  setup: {
    global_variables: require('core/vi/options/global_variables')
    opts: require('core/vi/options/opts')
  }
}

return vi
