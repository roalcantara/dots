local storage = require('core/neo/storage')
local paths = require('core/vi/paths')

local M = {}


--- Get the path of a buffer
--- @param buf number The buffer number
--- @return string The path of the buffer
function M.bufpath(buf)
  return storage.memo('buf::bufpath', paths.realpath, vim.api.nvim_buf_get_name(buf))
end

--- Detect the path of a buffer using a pattern
--- @class LazyRootSpec
--- @field pattern string The pattern to detect the path
--- @field upward boolean Whether to detect the path upward
--- @field buf number The buffer number
--- @field spec string[] The patterns to detect the path
--- @param buf number The buffer number
--- @param patterns string[] The patterns to detect the path
--- @return string[] The path of the buffer
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

--- Detect the path of a buffer using a spec
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

--- Detect the path of a buffer using a spec
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
      local pp = paths.realpath(p)
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

return M
