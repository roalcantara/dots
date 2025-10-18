return {
  slant = {
    left = '',
    right = '',
  },
  diagnostic = {
    error = '',
    warn = '',
    info = '',
    hint = '',
  },
  lsp = '',
  diff = {
    add = '',
    modified = '',
    removed = '',
  },
  git = {
    icon = '',
    add = '+',
    branch = '',
    added = ' ',
    modified = ' ',
    removed = ' ',
  },
  space = ' ',
  bullet = '•',
  percent = '',
  separator = '',
  file = {
    help = 'ﲉ',
    readonly = '',
    empty = '',
    modifiable = '',
    regular = '',
    format = '',
    line_column = '',
    encode = '',
  },
  mode = {
    n = '',
    i = '',
    v = '',
    V = '',
    c = '',
    no = '',
    s = '',
    S = '',
    ic = 'ﳁ',
    R = '﯒',
    Rv = '',
    cv = '',
    ce = 'ﲵ',
    r = '⏎',
    rm = 'ﳂ',
    t = '',
    ['!'] = '',
    [''] = '蘭',
    ['r?'] = '',
  },
  misc = {
    dots = '󰇘',
  },
  ft = {
    octo = '',
  },
  dap = {
    Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
    Breakpoint = ' ',
    BreakpointCondition = ' ',
    BreakpointRejected = { ' ', 'DiagnosticError' },
    LogPoint = '.>',
  },
  diagnostics = {
    Error = ' ',
    Warn = ' ',
    Hint = ' ',
    Info = ' ',
  },
  kinds = {
    Array = ' ',
    Boolean = '󰨙 ',
    Class = ' ',
    Codeium = '󰘦 ',
    Color = ' ',
    Control = ' ',
    Collapsed = ' ',
    Constant = '󰏿 ',
    Constructor = ' ',
    Copilot = ' ',
    Enum = ' ',
    EnumMember = ' ',
    Event = ' ',
    Field = ' ',
    File = ' ',
    Folder = ' ',
    Function = '󰊕 ',
    Interface = ' ',
    Key = ' ',
    Keyword = ' ',
    Method = '󰊕 ',
    Module = ' ',
    Namespace = '󰦮 ',
    Null = ' ',
    Number = '󰎠 ',
    Object = ' ',
    Operator = ' ',
    Package = ' ',
    Property = ' ',
    Reference = ' ',
    Snippet = '󱄽 ',
    String = ' ',
    Struct = '󰆼 ',
    Supermaven = ' ',
    TabNine = '󰏚 ',
    Text = ' ',
    TypeParameter = ' ',
    Unit = ' ',
    Value = ' ',
    Variable = '󰀫 ',
  },
  formatters = {
    -- Generic formatter icons
    added = '󰘧',
    modified = '󰘧',
    removed = '󰘧',
    stop_after_first = '󰘧',
    lsp_format = '󰘧',
    timeout_ms = '󰘧',

    -- Specific formatter logos/icons
    stylua = '󰢱', -- Lua formatter (Lua symbol)
    isort = '󰌠', -- Python import sorter (Python symbol)
    black = '🐍', -- Python formatter (Python snake)
    rustfmt = '🦀', -- Rust formatter (Rust crab)
    prettierd = '💎', -- Prettier daemon (gem/diamond)
    prettier = '💎', -- Prettier formatter (gem/diamond)

    -- Additional common formatters
    gofmt = '🐹', -- Go formatter (Go gopher)
    shfmt = '🐚', -- Shell formatter (shell)
    yamlfmt = '📄', -- YAML formatter (document)
    jsonfmt = '📋', -- JSON formatter (clipboard)
    markdownfmt = '📝', -- Markdown formatter (memo)
  }
}
