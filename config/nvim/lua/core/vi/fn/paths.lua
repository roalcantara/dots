--- Path management utilities
local M = {
  join = require('core/etc/sys/os').join,
  separator = require('core/etc/sys/os').get_separator,
  expand = vim.fn.expand,
  basename = vim.fs.basename,
  dirname = vim.fs.dirname,
  is_directory = vim.fn.isdirectory,
  filereadable = vim.fn.filereadable,
  stdpath = vim.fn.stdpath,
  homebrew_prefix = vim.env.HOMEBREW_PREFIX or '/opt/homebrew',
  is_executable = vim.fn.executable,
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

return M
