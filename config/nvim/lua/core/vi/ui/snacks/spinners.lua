-- In your async dashboard system
local M = {}

-- Spinner configurations
M.colored_spinners = {
  rainbow = {
    frames = { "●", "●", "●", "●", "●", "●" },
    colors = { "Red", "Yellow", "Green", "Cyan", "Blue", "Magenta" },
  },
  progress = {
    frames = { "▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰" },
    colors = { "Comment", "WarningMsg", "MoreMsg", "Question" },
  },
}

-- In your dashboard config
function M.create_async_section()
  local placeholder_text = "Loading..."
  local section = {
    { text = "Git Status: " .. placeholder_text,   hl = "SnacksDashboardDesc" },
    { text = "Project Info: " .. placeholder_text, hl = "SnacksDashboardDesc" },
  }

  -- Update asynchronously
  vim.schedule(function()
    -- Fetch git status
    vim.system({ 'git', 'rev-parse', '--short', 'HEAD' }, {
      cwd = vim.fn.getcwd(),
      text = true,
    }, function(result)
      if result.code == 0 then
        section[1].text = "Git Status: " .. vim.trim(result.stdout)
        -- Refresh dashboard
        require('snacks.dashboard').refresh()
      end
    end)

    -- Fetch project info
    vim.system({ 'find', '.', '-name', '*.lua', '-type', 'f' }, {
      cwd = vim.fn.getcwd(),
      text = true,
    }, function(result)
      if result.code == 0 then
        local count = vim.split(result.stdout, '\n')
        section[2].text = "Project Info: " .. #count .. " Lua files"
        require('snacks.dashboard').refresh()
      end
    end)
  end)

  return section
end

-- Create animated spinner
function M.create_spinner(style)
  style = style or "dots"
  local frames = M.spinners[style]
  local current_frame = 1

  local spinner = {
    current_text = frames[1],
    timer = nil,
    is_spinning = false,
  }

  function spinner:start()
    if self.is_spinning then return end
    self.is_spinning = true

    self.timer = vim.loop.new_timer()
    self.timer:start(0, 100, function() -- Update every 100ms
      current_frame = (current_frame % #frames) + 1
      self.current_text = frames[current_frame]

      vim.schedule(function()
        -- Trigger dashboard refresh
        if package.loaded['snacks.dashboard'] then
          require('snacks.dashboard').refresh()
        end
      end)
    end)
  end

  function spinner:stop()
    if self.timer then
      self.timer:stop()
      self.timer:close()
      self.timer = nil
    end
    self.is_spinning = false
    self.current_text = "✓" -- Success indicator
  end

  return spinner
end

-- Enhanced async item with spinner
function M.create_async_item_with_spinner(label, fetch_fn, opts)
  opts = opts or {}
  local spinner = M.create_spinner(opts.spinner_style)

  -- Start spinner immediately
  spinner:start()

  local item = {
    text = label .. spinner.current_text .. " Loading...",
    hl = opts.hl or "SnacksDashboardDesc",
  }

  -- Store reference for updates
  local item_id = #M.async_items + 1
  M.async_items[item_id] = {
    item = item,
    label = label,
    spinner = spinner,
    fetch_fn = fetch_fn,
  }

  -- Fetch data
  fetch_fn(function(result)
    vim.schedule(function()
      spinner:stop()
      item.text = label .. "✓ " .. result

      -- Final refresh
      if package.loaded['snacks.dashboard'] then
        require('snacks.dashboard').refresh()
      end
    end)
  end)

  -- Update spinner text regularly
  local function update_spinner()
    if spinner.is_spinning then
      item.text = label .. spinner.current_text .. " Loading..."
      vim.schedule(function()
        vim.defer_fn(update_spinner, 100)
      end)
    end
  end
  update_spinner()

  return item
end

function M.create_colored_spinner(style)
  local config = M.colored_spinners[style] or M.colored_spinners.rainbow
  local current_frame = 1

  local spinner = {
    current_text = config.frames[1],
    current_hl = config.colors[1],
    timer = nil,
    is_spinning = false,
  }

  function spinner:start()
    if self.is_spinning then return end
    self.is_spinning = true

    self.timer = vim.loop.new_timer()
    self.timer:start(0, 200, function()
      current_frame = (current_frame % #config.frames) + 1
      self.current_text = config.frames[current_frame]
      self.current_hl = config.colors[current_frame]

      vim.schedule(function()
        if package.loaded['snacks.dashboard'] then
          require('snacks.dashboard').refresh()
        end
      end)
    end)
  end

  return spinner
end

-- Progress bar spinner
function M.create_progress_spinner(total_steps)
  total_steps = total_steps or 10
  local current_step = 0

  local function get_progress_bar()
    local filled = math.floor((current_step / total_steps) * 20)
    local empty = 20 - filled
    return ("▰"):rep(filled) .. ("▱"):rep(empty) .. (" %d%%"):format(math.floor((current_step / total_steps) * 100))
  end

  local spinner = {
    current_text = get_progress_bar(),
    timer = nil,
    is_spinning = false,
  }

  function spinner:start()
    if self.is_spinning then return end
    self.is_spinning = true
    current_step = 0

    self.timer = vim.loop.new_timer()
    self.timer:start(0, 150, function()
      current_step = (current_step + 1) % (total_steps + 1)
      self.current_text = get_progress_bar()

      vim.schedule(function()
        if package.loaded['snacks.dashboard'] then
          require('snacks.dashboard').refresh()
        end
      end)
    end)
  end

  return spinner
end

return M
