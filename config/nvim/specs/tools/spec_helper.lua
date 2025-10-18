local busted = require('busted')

local function trim(value)
  if not value or type(value) == 'nil' then
    return ''
  end
  return string.match(value, '^()%s*$') and '' or string.match(value, '^%s*(.*%S)')
end

local function is_empty(value)
  if not value or type(value) == 'nil' then
    return true
  end

  if type(value) == 'string' then
    return trim(value) == ''
  end

  return false
end

-- Mock globals that might be referenced in the code
busted.setup(function()
  vim = {
    cmd = function(cmd)
      return function()
        return cmd
      end
    end,
    fs = {
      joinpath = function(...)
        local base = select(1, ...)
        local parts = select(2, ...)
        local opts = select(3, ...) or {}
        local normalize = opts.normalize or false
        local separator = opts.separator or '/'
        local inverted_separator = separator == '/' and '\\' or '/'

        -- Clean base path
        local clean_base = nil
        if base ~= nil and not is_empty(base) then
          clean_base = base:gsub(separator .. '+$', '')
        end

        local function flatten_recursive(item, result)
          if type(item) == 'string' and item ~= '' then
            -- Remove leading/trailing slashes from individual components
            local cleaned = item:gsub('^' .. separator .. '+', ''):gsub('' .. separator .. '+$', '')
            if cleaned ~= '' then
              table.insert(result, cleaned)
            end
          elseif type(item) == 'table' then
            for _, sub_item in ipairs(item) do
              flatten_recursive(sub_item, result)
            end
          end
        end

        if parts == nil or #parts == 0 then
          return clean_base or ''
        end

        local flattened = {}

        if not is_empty(clean_base) then
          table.insert(flattened, clean_base)
        end

        flatten_recursive(parts, flattened)

        -- Build the final path
        local joined = table.concat(flattened, separator)

        if normalize then
          return vim.fs.normalize(joined) or ''
        end

        joined = joined:gsub('//', separator)
        joined = joined:gsub(inverted_separator, separator)

        if not joined:match(separator) then
          return separator .. joined
        end

        return joined
      end,
      normalize = function(path)
        if type(path) ~= 'string' then
          error('Path must be a string', 2)
        end

        if path == '' then
          return '.'
        end

        -- Use LuaJIT string buffer for better performance
        local len = #path
        local is_absolute = path:byte(1) == 47 -- ASCII for '/'

        -- Parse components manually for better performance
        local components = {}
        local start = 1
        local i = 1

        while i <= len do
          if path:byte(i) == 47 then -- Found '/'
            if i > start then
              local component = path:sub(start, i - 1)
              if component ~= '' then
                table.insert(components, component)
              end
            end
            start = i + 1
          end
          i = i + 1
        end

        -- Add the last component if exists
        if start <= len then
          local component = path:sub(start, len)
          if component ~= '' then
            table.insert(components, component)
          end
        end

        -- Process components
        local stack = {}

        for j = 1, #components do
          local component = components[j]
          if component == '..' then
            if is_absolute then
              if #stack > 0 then
                table.remove(stack)
              end
            else
              if #stack > 0 and stack[#stack] ~= '..' then
                table.remove(stack)
              else
                table.insert(stack, '..')
              end
            end
          elseif component ~= '.' then
            table.insert(stack, component)
          end
        end

        -- Build result
        if is_absolute then
          if #stack == 0 then
            return '/'
          end
          return '/' .. table.concat(stack, '/')
        else
          if #stack == 0 then
            return '.'
          end
          return table.concat(stack, '/')
        end
      end,
      basename = function(path)
        if not path or path == '' then
          return ''
        end
        local parts = {}
        for part in path:gmatch('[^/]+') do
          table.insert(parts, part)
        end
        return parts[#parts] or ''
      end,
      dirname = function(path)
        if not path or path == '' then
          return ''
        end
        local parts = {}
        for part in path:gmatch('[^/]+') do
          table.insert(parts, part)
        end
        if #parts <= 1 then
          return ''
        end
        table.remove(parts)
        return '/' .. table.concat(parts, '/')
      end,
    },
    loop = {
      os_uname = function()
        return {
          name = 'Darwin',
          release = '20.6.0',
        }
      end,
    },
    fn = {
      has = function(feature)
        if feature == 'mac' then
          return 1
        end
        return 0
      end,
      expand = function(path)
        return path
      end,
      basename = function(path)
        return path
      end,
      dirname = function(path)
        return path
      end,
      is_directory = function(path)
        return path ~= nil
      end,
      filereadable = function(path)
        return path ~= nil
      end,
      stdpath = function(path)
        return path
      end,
      executable = function(name)
        return name == 'git' and 1 or 0
      end,
    },
    opt = {
      runtimepath = {
        get = function()
          return { '/test/path1', '/test/path2' }
        end,
      },
    },
    uv = {
      cwd = function()
        return '.'
      end,
    },

    env = {
      HOMEBREW_PREFIX = '/opt/homebrew',
      VIMRUNTIME = '/opt/homebrew/share/nvim/runtime',
      XDG_CONFIG_HOME = '/home/dev/.config',
      HOME = '/home/dev',
    },

    -- Mock vim.keymap.set for testing keymap creation
    keymap = {
      set = function(mode, lhs, rhs, opts)
        -- Mock implementation - just return the parameters for testing
        return { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
      end,
    },

    -- Mock vim.tbl_deep_extend for testing option merging
    tbl_deep_extend = function(strategy, ...)
      local result = {}
      local args = { ... }

      for i = 1, #args do
        local arg = args[i]
        if type(arg) == 'table' then
          for k, v in pairs(arg) do
            if strategy == 'force' or result[k] == nil then
              result[k] = v
            end
          end
        end
      end

      return result
    end,

    -- Mock vim.list_extend for testing option merging
    list_extend = function(target, source)
      local result = {}

      -- Copy target
      if type(target) == 'table' then
        for k, v in pairs(target) do
          result[k] = v
        end
      end

      -- Copy source
      if type(source) == 'table' then
        for k, v in pairs(source) do
          result[k] = v
        end
      end

      return result
    end,

    -- Mock vim.notify for testing error notifications
    notify = function(msg, level)
      -- Mock implementation - just return the message for testing
      return { message = msg, level = level }
    end,

    -- Mock vim.log.levels for testing
    log = {
      levels = {
        ERROR = 4,
        WARN = 3,
        INFO = 2,
        DEBUG = 1,
      },
    },

    -- Mock vim.api for user commands
    api = {
      nvim_create_user_command = function(name, callback, opts)
        -- Mock implementation - just return the parameters for testing
        return { name = name, callback = callback, opts = opts }
      end,
    },
  }
end)

busted.teardown(function()
  vim = nil
end)
