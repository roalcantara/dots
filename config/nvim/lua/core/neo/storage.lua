local strings = require('core/vi/strings')

local M = {
  __cache = {},
}

--- Generate a cache key from multiple parts
--- @param ... string|number Parts to join into a cache key
--- @return string Cache key
function M.cache_key(...)
  return table.concat({ ... }, '::')
end

--- Clear cache entries (useful for testing or when paths change)
--- @param pattern? string Optional pattern to match cache keys (if nil, clears all)
function M.clear_cache(pattern)
  if not pattern then
    M.__cache = {}
    return
  end

  for key in pairs(M.__cache) do
    if key:match(pattern) then
      M.__cache[key] = nil
    end
  end
end

--- Get cache statistics for debugging
--- @return table Cache statistics
function M.cache_stats()
  local count = 0
  local keys = {}
  for key in pairs(M.__cache) do
    count = count + 1
    table.insert(keys, key)
  end
  return {
    count = count,
    keys = keys
  }
end

--- Memoize expensive operations with automatic cache management
--- @param key string Cache key
--- @param compute_fn function Function that computes the value
--- @return any Cached or computed value
function M.memoize(key, compute_fn)
  if not key or strings.trim(key) == '' then
    return ''
  end
  if M.__cache[key] == nil then
    M.__cache[key] = compute_fn()
  end
  return M.__cache[key]
end

--- Memoize expensive operations with automatic cache management
--- @param key string Cache key
--- @param compute_fn function Function that computes the value
--- @param ... any Additional arguments to pass to the compute function
--- @return any Cached or computed value
function M.memo(key, compute_fn, ...)
  local cache_key_str = M.cache_key(key or 'default', ...)

  if M.__cache[cache_key_str] == nil then
    M.__cache[cache_key_str] = compute_fn(...)
  end

  return M.__cache[cache_key_str]
end

return M
