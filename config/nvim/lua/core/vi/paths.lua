-- Path and file system utilities
local M = {
  -- Project root detection utilities
  cache = {},
  spec = { 'lsp', { '.git', 'lua' }, 'cwd' },
  detectors = {},
  join = require('core/etc/sys/os').join,
  separator = require('core/etc/sys/os').get_separator,
  expand = vim.fn.expand,
  basename = vim.fs.basename,
  dirname = vim.fs.dirname,
  is_directory = vim.fn.isdirectory,
  filereadable = vim.fn.filereadable,
  stdpath = vim.fn.stdpath,
  homebrew_prefix = vim.env.HOMEBREW_PREFIX or '/opt/homebrew',
}

--- Get standard Neovim paths
--- @return table Table with config, data, cache, and state paths
function M.get_stdpaths()
  return {
    config = M.stdpath('config'),
    data = M.stdpath('data'),
    cache = M.stdpath('cache'),
    state = M.stdpath('state'),
  }
end

function M.bin_for(name)
  return M.join(M.homebrew_prefix, 'bin', name)
end

--- Check if a path exists
--- @param path string Path to check
--- @return boolean True if path exists
function M.exists(path)
  return M.is_directory(path) == 1 or M.filereadable(path) == 1
end

function M.get_lua_paths_with_name()
  local rtp = vim.opt.runtimepath:get()
  local items = {}

  for _, path in ipairs(rtp) do
    local lua_path = M.expand(M.join(path, 'lua'))
    if M.exists(lua_path) then
      local basename = M.basename(path)
      local display_text = string.format('%-25s %s', basename, lua_path)

      table.insert(items, {
        id = lua_path,
        text = display_text,
        data = lua_path,
        value = lua_path,
      })
    end
  end

  return items
end

M.lua = {
  runtime = {
    path = {
      '?.lua',
      M.join('?', 'init.lua'),
      M.join('lua', '?.lua'),
      M.join('lua', '?', 'init.lua'),
      M.join(vim.env.VIMRUNTIME, 'lua', '?.lua'),
      M.join(vim.env.VIMRUNTIME, 'lua', '?', 'init.lua'),
      M.join(M.stdpath('config'), '*', 'lua', '?.lua'),
      M.join(M.stdpath('config'), '*', 'lua', '?', 'init.lua'),
      M.join(M.stdpath('data'), 'lazy', '*', 'lua', '?.lua'),
      M.join(M.stdpath('data'), 'lazy', '*', 'lua', '?', 'init.lua'),
      M.join(M.stdpath('data'), 'mason', '*', 'lua', '?.lua'),
      M.join(M.stdpath('data'), 'mason', '*', 'lua', '?', 'init.lua'),
      M.join(M.stdpath('data'), 'blink', '*', 'lua', '?.lua'),
      M.join(M.stdpath('data'), 'blink', '*', 'lua', '?', 'init.lua'),
      M.join(M.stdpath('data'), 'scratch', '*', 'lua', '?.lua'),
      M.join(M.stdpath('data'), 'scratch', '*', 'lua', '?', 'init.lua'),
      M.join(M.stdpath('data'), 'snacks', '*', 'lua', '?.lua'),
      M.join(M.stdpath('data'), 'snacks', '*', 'lua', '?', 'init.lua'),
    },
    special = {
      include = 'require',
      vim = 'require',
      ['vim.loop'] = 'require',
    },
  },
  workspace = {
    library = {
      M.join(vim.env.VIMRUNTIME, 'lua'),
      M.bin_for('lua-language-server'),
      M.join(M.stdpath('data'), 'lazy', '*', 'lua'),
      M.join(M.stdpath('data'), 'mason', '*', 'lua'),
      M.join(M.stdpath('data'), 'blink', '*', 'lua'),
      M.join(M.stdpath('data'), 'scratch', '*', 'lua'),
      M.join(M.stdpath('data'), 'snacks', '*', 'lua'),
      '${3rd}/lfs/library',
      '${3rd}/luv/library',
      '${3rd}/busted/library',
      '${3rd}/luassert/library',
      M.join(M.stdpath('config'), 'lua'),
    },
  },
}

M.lua_runtime_paths = {
  '?.lua',
  M.join('?', 'init.lua'),
  M.join('lua', '?.lua'),
  M.join('lua', '?', 'init.lua'),
  M.expand(M.join(M.stdpath('config'), 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('config'), 'lua', '?', 'init.lua')),
  M.expand(M.join(M.stdpath('data'), 'lazy', '*', 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('data'), 'lazy', '*', 'lua', '?', 'init.lua')),
  M.expand(M.join(M.stdpath('data'), 'mason', '*', 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('data'), 'mason', '*', 'lua', '?', 'init.lua')),
  M.expand(M.join(M.stdpath('data'), 'blink', '*', 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('data'), 'blink', '*', 'lua', '?', 'init.lua')),
  M.expand(M.join(M.stdpath('data'), 'scratch', '*', 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('data'), 'scratch', '*', 'lua', '?', 'init.lua')),
  M.expand(M.join(M.stdpath('data'), 'snacks', '*', 'lua', '?.lua')),
  M.expand(M.join(M.stdpath('data'), 'snacks', '*', 'lua', '?', 'init.lua')),
  M.expand(M.join(vim.env.VIMRUNTIME, 'lua', '?.lua')),
  M.expand(M.join(vim.env.VIMRUNTIME, 'lua', '?', 'init.lua')),
  M.expand(M.join(vim.env.VIMRUNTIME, '*', 'lua', '?.lua')),
  M.expand(M.join(vim.env.VIMRUNTIME, '*', 'lua', '?', 'init.lua')),
}

function M.get_lua_runtime_paths_items()
  local rtp = M.lua_runtime_paths
  local items = {}

  for _, path in ipairs(rtp) do
    table.insert(items, {
      id = path,
      text = path,
      data = path,
      value = path,
    })
  end

  return items
end

function M.get_runtimepath_path_items()
  local rtp = vim.opt.runtimepath:get()
  local items = {}

  for _, path in ipairs(rtp) do
    -- Format display text
    local basename = M.basename(path)
    local display_text = string.format('%-25s %s', basename, path)

    table.insert(items, {
      id = path,
      text = display_text,
      data = path,
      value = path,
    })
  end

  return items
end

function M.bin_for_python3_venv()
  return os.getenv('VIRTUAL_ENV') or os.getenv('NEOVIM_PYTHON3_VENV_PATH') or
    M.join(M.stdpath('config'), '.venv', 'bin', 'python3')
end

function M.norm(path)
  if not path or path == '' then
    return ''
  end
  if M.is_directory(path) == 1 then
    return M.join(path, '')
  end
  return vim.fs.normalize((vim.uv or vim.loop).cwd() or '.')
end

--- Check if a command is executable
--- @param name string
--- @return boolean true if the command is executable
function M.is_executable(name)
  return vim.fn.executable(name) == 1
end

--- Get the XDG config home path for a given set of paths
--- @param ... string|string[] Path to XDG_CONFIG_HOME
--- @return string path to XDG_CONFIG_HOME
function M.xdg_config_home(...)
  local xdg_config_home = vim.env.XDG_CONFIG_HOME or M.join(vim.env.HOME, '.config')
  local paths = unpack({ ... }) or {}
  if #paths == 0 then
    return xdg_config_home
  end
  return M.join(xdg_config_home, paths)
end

function M.realpath(path)
  if path == "" or path == nil then
    return nil
  end
  path = vim.uv.fs_realpath(path) or path
  return M.norm(path)
end

function M.cwd()
  return M.realpath(vim.uv.cwd()) or ''
end

function M.bufpath(buf)
  return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.detectors.pattern(buf, patterns)
  patterns = type(patterns) == 'string' and { patterns } or patterns
  local path = M.bufpath(buf) or vim.uv.cwd()
  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if name == p then
        return true
      end
      if p:sub(1, 1) == '*' and name:find(vim.pesc(p:sub(2)) .. '$') then
        return true
      end
    end
    return false
  end, { path = path, upward = true })[1]
  return pattern and { vim.fs.dirname(pattern) } or {}
end

--- @param spec LazyRootSpec
--- @return function
function M.resolve(spec)
  if M.detectors[spec] then
    return M.detectors[spec]
  elseif type(spec) == 'function' then
    return spec
  end
  return function(buf)
    return M.detectors.pattern(buf, spec)
  end
end

--- @param opts? { buf?: number, spec?: LazyRootSpec[], all?: boolean }
--- @return LazyRoot[]
function M.detect(opts)
  opts = opts or {}
  opts.spec = opts.spec or type(vim.g.root_spec) == 'table' and vim.g.root_spec or M.spec
  opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

  local ret = {} --- @type LazyRoot[]
  for _, spec in ipairs(opts.spec) do
    local paths = M.resolve(spec)(opts.buf)
    paths = paths or {}
    paths = type(paths) == 'table' and paths or { paths }
    local roots = {} --- @type string[]
    for _, p in ipairs(paths) do
      local pp = M.realpath(p)
      if pp and not vim.tbl_contains(roots, pp) then
        roots[#roots + 1] = pp
      end
    end
    table.sort(roots, function(a, b)
      return #a > #b
    end)
    if #roots > 0 then
      ret[#ret + 1] = { spec = spec, paths = roots }
      if opts.all == false then
        break
      end
    end
  end
  return ret
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
--- @param opts? {normalize?:boolean, buf?:number}
--- @return string
function M.get(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local ret = M.cache[buf]
  if not ret then
    local roots = M.detect({ all = false, buf = buf })
    ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
    M.cache[buf] = ret
  end
  if opts and opts.normalize then
    return ret
  end
  return M.get_separator() or ret
end

return M
