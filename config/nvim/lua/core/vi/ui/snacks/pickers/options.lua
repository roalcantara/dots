--- Return all Neovim's options as a structured table
--- @return fn function (event: table) -> table | Picker that lists all neovim's options
return function()
  -- Get all options as a structured table
  local all_options = vim.api.nvim_get_all_options_info()
  local items = {}

  -- Convert options to items for picker
  for name, option in pairs(all_options) do
    -- Get current value
    local current_value
    local success, value = pcall(function()
      return vim.api.nvim_get_option_value(name, {})
    end)
    if success then
      if type(value) == "boolean" then
        current_value = value and "true" or "false"
      elseif type(value) == "table" then
        current_value = vim.inspect(value):sub(1, 50) -- Limit length
      else
        current_value = tostring(value)
      end
    else
      current_value = "N/A"
    end

    -- Format display text
    local display_text =
        string.format("%-25s %-10s %-10s %s", name, option.shortname or "", option.type or "", current_value or "")

    table.insert(items, {
      id = name,
      text = display_text,
      data = option,
      value = current_value,
    })
  end

  -- Sort items by option name
  table.sort(items, function(a, b)
    return a.id < b.id
  end)

  return Snacks.picker({
    title = "Neovim Options",
    items = items,
    format = "text",
    on_choice = function(selection)
      if selection then
        -- Create a detailed view of the option
        local option = selection.data
        local details = {
          "Option: " .. option.name,
          "Short name: " .. (option.shortname or ""),
          "Type: " .. (option.type or ""),
          "Scope: " .. (option.scope or ""),
          "Current value: " .. selection.value,
          "Default value: " .. vim.inspect(option.default),
          "Was set: " .. (option.was_set and "Yes" or "No"),
        }

        -- Show the details
        vim.notify(table.concat(details, "\n"), vim.log.levels.INFO)

        -- Could also show help for the option
        -- vim.cmd("help '" .. option.name .. "'")
      end
    end,
  })
end
