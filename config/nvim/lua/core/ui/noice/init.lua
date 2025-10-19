-- Noice helpers: fetch and count history messages for a given status name.
M = {
  CMD_LINE_EVENTS = {
    CMDLINE = "cmdline",
    SHOW = "cmdline_show",
    HIDE = "cmdline_hide",
    POS = "cmdline_pos",
    SPECIAL_CHAR = "cmdline_special_char",
    BLOCK_SHOW = "cmdline_block_show",
    BLOCK_APPEND = "cmdline_block_append",
    BLOCK_HIDE = "cmdline_block_hide",
  },

  EVENTS = {
    SHOW = 'show_msg',
    MSG_SHOW = "msg_show",
    CLEAR = "msg_clear",
    SHOWMODE = "msg_showmode",
    SHOWCMD = "msg_showcmd",
    RULER = "msg_ruler",
    HISTORY_SHOW = "msg_history_show",
    HISTORY_CLEAR = "msg_history_clear",
  },

  KINDS = {
    EMPTY = ' ',                     -- (empty) Unknown (consider a feature-request: |bugs|)
    ECHO = 'echo',                   --  |:echo| message
    ECHOMSG = 'echomsg',             -- |:echomsg| message
    CONFIRM = 'confirm',             -- |confirm()| or |:confirm| dialog
    CONFIRM_SUB = 'confirm_sub',     -- |:substitute| confirm dialog |:s_c|
    NUMBER_PROMPT = 'number_prompt', -- |inputlist()| prompt for a number
    RETURN_PROMPT = 'return_prompt', -- |press-enter| prompt after a multiple messages
    LIST_CMD = 'list_cmd',           -- |:list| command
    ERRORS = 'emsg',                 --  Error (|errors|, internal error, |:throw|, …)
    ECHOERR = 'echoerr',             -- |:echoerr| message
    LUA_ERRORS = 'lua_error',        -- Error in |:lua| code
    WARNINGS = 'wmsg',               --  Warning ("search hit BOTTOM", |W10|, …)
    RPC_ERRORS = 'rpc_error',        -- Error response from |rpcrequest()|
    QUICKFIX = 'quickfix',           -- Quickfix navigation message
    SEARCH_COUNT = 'search_count',   -- Search count message ("S" flag of 'shortmess')
  },

  QUERIES = {
    COMMAND_LINE = {
      filter = { event = "msg_showcmd" },
    },
    COMMAND = {
      filter = {
        event = { "cmdline", "msg_showcmd" }
      },
    },
    SHOW_COMMANDLINE = {
      filter = {
        event = { "msg_show", "msg_showcmd" },
        kind = { "echomsg" }
      },
    },
    MODE = {
      filter = {
        event = { "showmode", "msg_showmode" }
      },
    },
    CONFIRM = {
      filters = {
        any = {
          { event = "msg_show", kind = "confirm" },
          { event = "msg_show", kind = "confirm_sub" },
          { event = "msg_show", kind = "number_prompt" },
        },
      }
    },
    HISTORY = {
      filter = {
        event = "msg_history_show"
      },
    },
    FULL_HISTORY = {
      filter = {
        any = {
          { event = "notify" },
          { error = true },
          { warning = true },
          { event = "msg_show", kind = { "" } },
          { event = "lsp",      kind = "message" }
        }
      },
      opts = {
        enter = true,
        format = "details"
      }
    },
    VIEW_SEARCH = {
      filter = {
        {
          event = "msg_show",
          kind = "search_count",
        },
      }
    },
    SEARCH = {
      filter = {
        event = { "msg_showmode", "msg_showcmd", "msg_ruler" }
      },
      opts = { skip = true },
    },
    SEARCH_COUNT = {
      filter = {
        any = {
          { event = { "msg_showmode", "msg_showcmd", "msg_ruler" } },
          { event = "msg_show",                                    kind = "search_count" },
        },
      },
      opts = { skip = true },
    },
    MESSAGES = {
      filter = {
        event = { "show_msg", "msg_show" }, kind = { "lua_print", "list_cmd" }
      },
      opts = { replace = true, merge = true, title = "Messages" },
    },
    ALL_MESSAGES = {
      filter = {
        event = { "show_msg", "msg_show", "lsp" }, kind = { "", "echo", "echomsg", "lua_print", "list_cmd", "message" }
      },
      opts = { replace = true, merge = true, title = "Messages" },
    },
    ERRORS = {
      filter = { error = true },
      filter_opts = { reverse = true },
      opts = { title = "Error" },
    },
    WARNING = {
      filter = { warning = true },
      opts = { title = "Warning" },
    },
    NOTIFY = {
      filter = { event = "notify" },
      opts = { title = "Notify" },
    },
    NOTIFY_STATS = {
      filter = {
        event = "noice",
        kind = { "stats", "debug" },
      },
      opts = { lang = "lua", replace = true, title = "Noice" },
    },
    LSP_PROGRESS = {
      filter = { event = "lsp", kind = "progress" },
    },
    LSP_MESSAGES = {
      filter = { event = "lsp", kind = "message" },
    }
  },

  ICONS = {
    history = ' ',
    message = '󰨄 ',
    mode = ' ',
    search = '󱈆 ',
  }
}

--- Fetch Noice messages history for a given status name.
--- @param name string e.g. 'messages'
--- @param opts? { filter?: table, sort?: boolean, event?: any, kind?: any, any?: any, warning?: boolean, error?: boolean }
--- @return table messages
function M.noice_history(name, opts)
  opts = opts or {}
  local ok_cfg, Config = pcall(require, 'noice.config')
  local ok_mgr, Manager = pcall(require, 'noice.message.manager')
  if not (ok_cfg and ok_mgr) then
    return {}
  end

  -- Prefer explicit filter, otherwise build from event/kind/etc, otherwise fallback to status[name]
  local filter = opts.filter
  if not filter then
    local f = {}
    if opts.event ~= nil then f.event = opts.event end
    if opts.kind ~= nil then f.kind = opts.kind end
    if opts.any ~= nil then f.any = opts.any end
    if opts.warning ~= nil then f.warning = opts.warning end
    if opts.error ~= nil then f.error = opts.error end
    filter = next(f) and f or ((Config.options.status and Config.options.status[name]) or {})
  end

  local params = {
    history = true,
    sort = opts.sort ~= false,
    -- Do NOT set `count` so we get the full history.
  }

  return Manager.get(filter, params) or {}
end

--- Count Noice history messages for a status name.
--- @param name string e.g. 'messages'
--- @param opts? { filter?: table, sort?: boolean, event?: any, kind?: any, any?: any, warning?: boolean, error?: boolean }
--- @return number
function M.noice_count_history(name, opts)
  local msgs = M.noice_history(name, opts)
  return #msgs
end

-- Snacks notifier history helpers (to match Snacks.notifier.show_history)
--- Fetch Snacks notifier history items, optionally filtered by level (e.g. 'info').
--- @param opts? { filter?: string|number, level?: string|number }
--- @return table
function M.notifier_history(opts)
  opts = opts or {}
  local ok_sn, Snacks = pcall(require, 'snacks')
  if not ok_sn or not Snacks or not Snacks.notifier then
    return {}
  end

  local hist = Snacks.notifier.history or {}
  local want = opts.level or opts.filter
  if not want then
    return hist
  end

  local lvl_map = {
    trace   = vim.log.levels.TRACE,
    debug   = vim.log.levels.DEBUG,
    info    = vim.log.levels.INFO,
    warn    = vim.log.levels.WARN,
    warning = vim.log.levels.WARN,
    error   = vim.log.levels.ERROR,
  }
  local want_num = type(want) == 'string' and lvl_map[string.lower(want)] or want

  local items = {}
  for _, it in ipairs(hist) do
    local lvl = it.level or (it.opts and it.opts.level)
    if not want_num or lvl == want_num then
      table.insert(items, it)
    end
  end
  return items
end

--- Count Snacks notifier history items.
--- @param opts? { filter?: string|number, level?: string|number }
--- @return number
function M.notifier_count_history(opts)
  return #M.notifier_history(opts)
end

-- Example usage:
-- local n = require('core.ui.noice').noice.count('messages')
-- print('Noice messages history count: ' .. n)

return M
