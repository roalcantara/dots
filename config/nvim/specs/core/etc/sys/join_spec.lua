local subject = require("core/etc/sys/os").join

describe("sys#join()", function()
  local test_scenarios = {
    -- Basic string joining scenarios
    {
      name = "joins single string part",
      base = "/home/user",
      parts = "documents",
      expected = "/home/user/documents"
    },
    {
      name = "joins multiple string parts",
      base = "/home/user",
      parts = { "documents", "projects", "readme.md" },
      expected = "/home/user/documents/projects/readme.md"
    },
    {
      name = "handles empty base path",
      base = "",
      parts = { "file.txt" },
      expected = "/file.txt"
    },
    {
      name = "handles nil base path",
      base = nil,
      parts = { "file.txt" },
      expected = "/file.txt"
    },
    {
      name = "handles both nil base and parts",
      base = nil,
      parts = nil,
      expected = ""
    },
    {
      name = "handles empty parts array",
      base = "/home/user",
      parts = {},
      expected = "/home/user"
    },
    {
      name = "handles single empty string part",
      base = "/home/user",
      parts = "",
      expected = "/home/user"
    },
    {
      name = "handles multiple empty string parts",
      base = "/home/user",
      parts = { "", "" },
      expected = "/home/user"
    },

    -- Parts starting with separator scenarios
    {
      name = "handles part starting with separator",
      base = "/home/user",
      parts = { "documents", "/absolute/path" },
      expected = "/home/user/documents/absolute/path"
    },
    {
      name = "handles multiple parts starting with separator",
      base = "/home/user",
      parts = { "/documents", "/projects" },
      expected = "/home/user/documents/projects"
    },

    -- Nested arrays (flattening) scenarios
    {
      name = "flattens nested arrays",
      base = "/home/user",
      parts = { { "documents", "projects" }, { "src", "main.lua" } },
      expected = "/home/user/documents/projects/src/main.lua"
    },
    {
      name = "flattens deeply nested arrays",
      base = "/home/user",
      parts = { { { "documents" }, { "projects" } }, "readme.md" },
      expected = "/home/user/documents/projects/readme.md"
    },

    -- -- Custom separator scenarios
    {
      name = "uses custom separator",
      base = "C:\\Users\\user",
      parts = { "Documents", "Projects" },
      opts = { separator = "\\" },
      expected = "C:\\Users\\user\\Documents\\Projects"
    },
    {
      name = "handles part starting with custom separator",
      base = "C:\\Users\\user",
      parts = { "Documents", "\\Projects" },
      opts = { separator = "\\" },
      expected = "C:\\Users\\user\\Documents\\Projects"
    },

    -- -- Path normalization scenarios
    {
      name = "normalizes path when option is enabled",
      base = "/home/user",
      parts = { "documents", "..", "projects" },
      opts = { normalize = true },
      expected = "/home/user/projects"
    },
    {
      name = "normalizes path with multiple dots",
      base = "/home/user",
      parts = { "documents", "..", "..", "root" },
      opts = { normalize = true },
      expected = "/home/root"
    },
    {
      name = "does not normalize when option is disabled",
      base = "/home/user",
      parts = { "documents", "..", "projects" },
      opts = { normalize = false },
      expected = "/home/user/documents/../projects"
    },

    -- Edge cases
    {
      name = "handles nil options",
      base = "/home/user",
      parts = { "documents" },
      opts = nil,
      expected = "/home/user/documents"
    },
    {
      name = "handles empty options table",
      base = "/home/user",
      parts = { "documents" },
      opts = {},
      expected = "/home/user/documents"
    },
    {
      name = "handles mixed string and array parts",
      base = "/home/user",
      parts = { "documents", { "projects", "src" }, "main.lua" },
      expected = "/home/user/documents/projects/src/main.lua"
    },
    {
      name = "handles single character parts",
      base = "/home/user",
      parts = { "a", "b", "c" },
      expected = "/home/user/a/b/c"
    },
    {
      name = "handles parts with special characters",
      base = "/home/user",
      parts = { "my-folder", "file_name.txt", "folder with spaces" },
      expected = "/home/user/my-folder/file_name.txt/folder with spaces"
    }
  }

  for _, scenario in ipairs(test_scenarios) do
    it(scenario.name, function()
      local result = subject(scenario.base, scenario.parts, scenario.opts)
      assert.equals(scenario.expected, result)
    end)
  end
end)
