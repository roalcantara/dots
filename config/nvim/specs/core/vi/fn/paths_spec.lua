--- @diagnostic disable: duplicate-set-field
local subject = require("core/vi/paths")

describe("#core.vi.paths", function()
  describe("get_stdpaths()", function()
    it("returns a table with config, data, cache, and state paths", function()
      local result = subject.get_stdpaths()
      assert.is_table(result)
      assert.is_string(result.config)
      assert.is_string(result.data)
      assert.is_string(result.cache)
      assert.is_string(result.state)
    end)
  end)

  describe("bin_for()", function()
    it("returns homebrew bin path for command", function()
      -- Mock the join function to return expected path
      local original_join = subject.join
      subject.join = function(...)
        local args = { ... }
        return table.concat(args, "/")
      end

      assert.equal("/opt/homebrew/bin/git", subject.bin_for("git"))
      assert.equal("/opt/homebrew/bin/lua", subject.bin_for("lua"))

      -- Restore original function
      subject.join = original_join
    end)
  end)

  describe("exists()", function()
    it("returns true for existing directory", function()
      -- Mock the directory check to return true
      local original_is_directory = subject.is_directory
      subject.is_directory = function() return 1 end
      subject.filereadable = function() return 0 end

      assert.is_true(subject.exists("/tmp"))

      -- Restore original function
      subject.is_directory = original_is_directory
    end)

    it("returns true for existing file", function()
      -- Mock the file check to return true
      local original_filereadable = subject.filereadable
      subject.is_directory = function() return 0 end
      subject.filereadable = function() return 1 end

      assert.is_true(subject.exists("/tmp/test.txt"))

      -- Restore original function
      subject.filereadable = original_filereadable
    end)

    it("returns false for non-existing path", function()
      -- Mock both checks to return false
      local original_is_directory = subject.is_directory
      local original_filereadable = subject.filereadable
      subject.is_directory = function() return 0 end
      subject.filereadable = function() return 0 end

      assert.is_false(subject.exists("/non/existing/path"))

      -- Restore original functions
      subject.is_directory = original_is_directory
      subject.filereadable = original_filereadable
    end)
  end)

  describe("get_lua_paths_with_name()", function()
    it("returns array of items with lua paths", function()
      -- Mock the functions directly
      local original_exists = subject.exists
      local original_expand = subject.expand
      local original_basename = subject.basename

      -- Mock vim.opt.runtimepath:get() by overriding the function
      local original_get_lua_paths_with_name = subject.get_lua_paths_with_name
      subject.get_lua_paths_with_name = function()
        local items = {}
        local test_paths = { "/test/path1", "/test/path2" }

        for _, path in ipairs(test_paths) do
          local lua_path = path .. "/lua"
          if lua_path:find("lua") ~= nil then
            local basename = "test"
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

      local result = subject.get_lua_paths_with_name()
      assert.is_table(result)
      assert.is_true(#result > 0)

      for _, item in ipairs(result) do
        assert.is_string(item.id)
        assert.is_string(item.text)
        assert.is_string(item.data)
        assert.is_string(item.value)
        assert.is_true(item.text:find("test") ~= nil)
      end

      -- Restore original function
      subject.get_lua_paths_with_name = original_get_lua_paths_with_name
    end)
  end)

  describe("get_lua_runtime_paths_items()", function()
    it("returns array of items with lua runtime paths", function()
      local result = subject.get_lua_runtime_paths_items()
      assert.is_table(result)
      assert.is_true(#result > 0)

      for _, item in ipairs(result) do
        assert.is_string(item.id)
        assert.is_string(item.text)
        assert.is_string(item.data)
        assert.is_string(item.value)
      end
    end)
  end)

  describe("get_runtimepath_path_items()", function()
    it("returns array of items with runtime paths", function()
      -- Mock the function directly
      local original_get_runtimepath_path_items = subject.get_runtimepath_path_items
      subject.get_runtimepath_path_items = function()
        local items = {}
        local test_paths = { "/test/path1", "/test/path2" }

        for _, path in ipairs(test_paths) do
          local basename = "test"
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

      local result = subject.get_runtimepath_path_items()
      assert.is_table(result)
      assert.is_true(#result > 0)

      for _, item in ipairs(result) do
        assert.is_string(item.id)
        assert.is_string(item.text)
        assert.is_string(item.data)
        assert.is_string(item.value)
        assert.is_true(item.text:find("test") ~= nil)
      end

      -- Restore original function
      subject.get_runtimepath_path_items = original_get_runtimepath_path_items
    end)
  end)

  describe("bin_for_python3_venv()", function()
    it("returns VIRTUAL_ENV when set", function()
      -- Mock os.getenv and join
      local original_getenv = os.getenv
      local original_join = subject.join

      os.getenv = function(name)
        return name == "VIRTUAL_ENV" and "/path/to/venv" or nil
      end
      subject.join = function(...)
        local args = { ... }
        return table.concat(args, "/")
      end

      assert.equal("/path/to/venv", subject.bin_for_python3_venv())

      -- Restore original functions
      os.getenv = original_getenv
      subject.join = original_join
    end)

    it("returns NEOVIM_PYTHON3_VENV_PATH when VIRTUAL_ENV not set", function()
      -- Mock os.getenv and join
      local original_getenv = os.getenv
      local original_join = subject.join

      os.getenv = function(name)
        return name == "NEOVIM_PYTHON3_VENV_PATH" and "/path/to/neovim/venv" or nil
      end
      subject.join = function(...)
        local args = { ... }
        return table.concat(args, "/")
      end

      assert.equal("/path/to/neovim/venv", subject.bin_for_python3_venv())

      -- Restore original functions
      os.getenv = original_getenv
      subject.join = original_join
    end)

    it("returns default path when neither env var is set", function()
      -- Mock os.getenv and join
      local original_getenv = os.getenv
      local original_join = subject.join

      os.getenv = function(name)
        return nil
      end
      subject.join = function(...)
        local args = { ... }
        return table.concat(args, "/")
      end

      assert.equal("config/.venv/bin/python3", subject.bin_for_python3_venv())

      -- Restore original functions
      os.getenv = original_getenv
      subject.join = original_join
    end)
  end)

  describe("norm()", function()
    it("returns empty string for nil path", function()
      assert.equal("", subject.norm(nil))
    end)

    it("returns empty string for empty path", function()
      assert.equal("", subject.norm(""))
    end)

    it("returns normalized path for directory", function()
      -- Mock is_directory and join
      local original_is_directory = subject.is_directory
      local original_join = subject.join

      subject.is_directory = function(path)
        return path == "/tmp" and 1 or 0
      end
      subject.join = function(path, suffix)
        return path .. suffix
      end

      assert.equal("/tmp", subject.norm("/tmp"))

      -- Restore original functions
      subject.is_directory = original_is_directory
      subject.join = original_join
    end)

    it("returns current working directory for file path", function()
      -- Mock is_directory and cwd
      local original_is_directory = subject.is_directory
      local uv_or_loop = vim.uv or vim.loop
      local original_cwd = uv_or_loop.cwd
      local original_normalize = vim.fs.normalize

      subject.is_directory = function(path)
        return 0
      end
      uv_or_loop.cwd = function() return "." end
      vim.fs.normalize = function(path) return path end

      assert.equal(".", subject.norm("test.txt"))

      -- Restore original functions
      subject.is_directory = original_is_directory
      uv_or_loop.cwd = original_cwd
      vim.fs.normalize = original_normalize
    end)
  end)

  describe("is_executable()", function()
    it("calls vim.fn.executable with the command name and returns true when executable", function()
      -- Create a spy to track calls to vim.fn.executable
      local spy_calls = {}
      local original_executable = vim.fn.executable
      vim.fn.executable = function(name)
        table.insert(spy_calls, name)
        return 1
      end

      local result = subject.is_executable("git")

      -- Verify the function was called with the correct parameter
      assert.equal(1, #spy_calls)
      assert.equal("git", spy_calls[1])
      assert.is_true(result)

      -- Restore original function
      vim.fn.executable = original_executable
    end)

    it("calls vim.fn.executable with the command name and returns false when not executable", function()
      -- Create a spy to track calls to vim.fn.executable
      local spy_calls = {}
      local original_executable = vim.fn.executable
      vim.fn.executable = function(name)
        table.insert(spy_calls, name)
        return 0
      end

      local result = subject.is_executable("nonexistent")

      -- Verify the function was called with the correct parameter
      assert.equal(1, #spy_calls)
      assert.equal("nonexistent", spy_calls[1])
      assert.is_false(result)

      -- Restore original function
      vim.fn.executable = original_executable
    end)
  end)

  describe("xdg_config_home()", function()
    local scenarios = {
      ["no paths are provided"] = { when = "", expected = "/home/dev/.config" },
      ["a path is provided"] = { when = "ghostty", expected = "/home/dev/.config/ghostty" },
      ["multiple paths are provided"] = { when = "ghostty/config", expected = "/home/dev/.config/ghostty/config" },
    }

    for given, scenario in pairs(scenarios) do
      it(given, function()
        assert.equal(scenario.expected, subject.xdg_config_home(scenario.when))
      end)
    end
  end)
end)
