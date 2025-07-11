local subject = require("core/vi/ui/snacks/pickers/toggle_options")

describe("toggle_options picker", function()
  it("should return a function", function()
    assert.is_function(subject)
  end)

  it("should create a picker with correct title", function()
    -- Mock Snacks.picker to capture the configuration
    local captured_config = nil
    local original_picker = Snacks.picker
    Snacks.picker = function(config)
      captured_config = config
      return {}
    end

    -- Call the function
    subject()

    -- Restore original
    Snacks.picker = original_picker

    -- Assertions
    assert.is_table(captured_config)
    assert.equals("Toggler", captured_config.title)
    assert.equals("text", captured_config.format)
    assert.is_function(captured_config.on_choice)
    assert.is_function(captured_config.preview)
  end)

  it("should include expected options", function()
    local captured_config = nil
    local original_picker = Snacks.picker
    Snacks.picker = function(config)
      captured_config = config
      return {}
    end

    subject()
    Snacks.picker = original_picker

    -- Check that items are created
    assert.is_table(captured_config.items)
    assert.is_true(#captured_config.items > 0)

    -- Check for some expected options
    local option_names = {}
    for _, item in ipairs(captured_config.items) do
      table.insert(option_names, item.id)
    end

    assert.is_true(vim.tbl_contains(option_names, "wrap"))
    assert.is_true(vim.tbl_contains(option_names, "spell"))
    assert.is_true(vim.tbl_contains(option_names, "relativenumber"))
  end)

  it("should format items correctly", function()
    local captured_config = nil
    local original_picker = Snacks.picker
    Snacks.picker = function(config)
      captured_config = config
      return {}
    end

    subject()
    Snacks.picker = original_picker

    -- Check that items have the expected structure
    for _, item in ipairs(captured_config.items) do
      assert.is_string(item.id)
      assert.is_string(item.text)
      assert.is_table(item.data)
      assert.is_string(item.buffer_value)
      assert.is_string(item.global_value)
      assert.is_number(item.index)

      -- Check text format (should contain the option name and values)
      assert.is_true(item.text:find(item.id))
      assert.is_true(item.text:find("|"))
    end
  end)
end)
