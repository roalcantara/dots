--- Minimal coroutine runner that keeps the editor responsive.
--- Inside a task started with `run`, `system` and `wait` yield until the process
--- finishes or the condition holds; everywhere else they block, as before. Only
--- coroutines created by `run` ever yield, so other coroutines are unaffected.

local M = {}

--- Resume function of every live task, keyed by its coroutine.
--- @type table<thread, fun(...)>
local tasks = setmetatable({}, { __mode = 'k' })

--- Run `fn` as a task and call `on_done(ok, result)` when it finishes.
--- @param fn fun(): any
--- @param on_done fun(ok: boolean, result: any)
function M.run(fn, on_done)
  local co = coroutine.create(fn)
  local function step(...)
    local ok, result = coroutine.resume(co, ...)
    if coroutine.status(co) == 'dead' then
      tasks[co] = nil
      on_done(ok, result)
    end
  end
  tasks[co] = step
  step()
end

--- Whether the caller runs inside a task started by `run`.
--- @return boolean
function M.in_task()
  local co = coroutine.running()
  return co ~= nil and tasks[co] ~= nil
end

--- `vim.system(cmd, opts):wait()` that yields instead of blocking inside a task.
--- @param cmd string[]
--- @param opts table|nil vim.system options
--- @return vim.SystemCompleted
function M.system(cmd, opts)
  if not M.in_task() then
    return vim.system(cmd, opts):wait()
  end
  local step = tasks[coroutine.running()]
  vim.system(cmd, opts, function(result)
    vim.schedule(function()
      step(result)
    end)
  end)
  return coroutine.yield()
end

--- `vim.wait(timeout_ms, condition, interval_ms)` that yields instead of blocking inside a task.
--- @param timeout_ms integer
--- @param condition fun(): boolean
--- @param interval_ms integer|nil Polling interval (default 50)
function M.wait(timeout_ms, condition, interval_ms)
  if not M.in_task() then
    return vim.wait(timeout_ms, condition, interval_ms)
  end
  local step = tasks[coroutine.running()]
  local deadline = vim.uv.now() + timeout_ms
  local function poll()
    if condition() or vim.uv.now() >= deadline then
      step()
    else
      vim.defer_fn(poll, interval_ms or 50)
    end
  end
  vim.defer_fn(poll, 0)
  coroutine.yield()
end

return M
