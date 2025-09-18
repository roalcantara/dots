local trim = require('core/vi/strings').trim

-- State management
local state = {
  scratch_win = nil,
  scratch_buf = nil,
  results_win = nil,
  results_buf = nil,
  current_language = 'lua',
  panel_open = false,
}

-- Configuration for the enhanced scratch panel
local config = {
  panel = {
    width = 70,
    title = ' Scratch ',
    position = 'right',
  },
  execution = {
    auto_run = false, -- Auto-run on buffer change
    clear_on_run = false, -- Clear previous results
    show_errors_inline = true, -- Use Snacks' inline error display
  },
  languages = {
    lua = {
      icon = '🌙',
      name = 'Lua',
      default_template = "-- Lua Scratch\nprint('Hello from Lua!')",
      cmd = 'lua -e ',
    },
    python = {
      icon = '🐍',
      name = 'Python',
      default_template = "# Python Scratch\nprint('Hello from Python!')",
      cmd = 'python -c ',
    },
    javascript = {
      icon = '🟨',
      name = 'JavaScript',
      default_template = "// JavaScript Scratch\nconsole.log('Hello from JS!');",
      cmd = 'node -e ',
    },
    typescript = {
      icon = '🔷',
      name = 'TypeScript',
      default_template = "// TypeScript Scratch\nconsole.log('Hello from TS!');",
      cmd = 'npx ts-node -e ',
    },
    bash = {
      icon = '🐚',
      name = 'Bash',
      default_template = "# Bash Scratch\necho 'Hello from Bash!'",
      cmd = 'bash -c ',
    },
    zsh = {
      icon = '🐚',
      name = 'Zsh',
      default_template = "# Zsh Scratch\necho 'Hello from Zsh!'",
      cmd = 'zsh -c ',
    },
    go = {
      icon = '🐹',
      name = 'Go',
      default_template = '// Go Scratch\npackage main\nimport "fmt"\nfunc main() {\n fmt.Println("Hello!") \n}',
      cmd = 'go run ',
    },
    ruby = {
      icon = '💎',
      name = 'Ruby',
      default_template = "# Ruby Scratch\nputs 'Hello from Ruby!'",
      cmd = 'ruby -e ',
    },
  },
}

--- Prepares a command to be executed
--- @param icon string Icon to display in the notification
--- @param cmd string Command to execute
--- @param code string Code to execute
--- @return string Prepared command
local function prepare(icon, cmd, code)
  local code_to_execute = vim.fn.shellescape(code)
  return cmd .. " '" .. code_to_execute .. "'"
end

--- Closes the scratch panel
--- @return table state of the panel
local function close_panel()
  -- Close results window
  if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
    vim.api.nvim_win_close(state.results_win, false)
    state.results_win = nil
  end

  -- Close scratch window (this is handled by Snacks automatically)
  state.scratch_win = nil
  state.panel_open = false

  return state
end

--- Clears the results buffer
local function clear_results()
  if state.results_buf and vim.api.nvim_buf_is_valid(state.results_buf) then
    vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, {})
  end
end

--- Creates the results buffer and window
--- @return nil
local function create_results_buffer()
  if not state.results_buf or not vim.api.nvim_buf_is_valid(state.results_buf) then
    state.results_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.results_buf })
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = state.results_buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = state.results_buf })
    vim.api.nvim_set_option_value('filetype', 'text', { buf = state.results_buf })
    vim.api.nvim_buf_set_name(state.results_buf, 'Execution Results')
  end

  -- Create results window at bottom
  if not state.results_win or not vim.api.nvim_win_is_valid(state.results_win) then
    vim.cmd('botright 12split')
    state.results_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.results_win, state.results_buf)

    -- Configure results window
    vim.api.nvim_set_option_value('wrap', true, { win = state.results_win })
    vim.api.nvim_set_option_value('number', false, { win = state.results_win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = state.results_win })
    vim.api.nvim_set_option_value('winhighlight', 'Normal:NormalFloat', { win = state.results_win })
  end
end

--- Shows the execution results in the results buffer
--- @param code string
--- @param output string
--- @return nil
local function show_execution_result(code, output)
  -- Create results buffer if needed
  if not state.results_buf or not vim.api.nvim_buf_is_valid(state.results_buf) then
    create_results_buffer()
  end

  -- Execute command asynchronously
  local output_lines = {}
  local stderr_lines = {}

  local function on_exit(code_result)
    vim.schedule(function()
      local timestamp = os.date('%H:%M:%S')
      local lang = config.languages[state.current_language]

      local result_lines = {
        '',
        '=== ' .. timestamp .. ' [' .. lang.icon .. ' ' .. lang.name .. '] ===',
        '> ' .. (code:match('^(.-)%s*$') or ''):sub(1, 50) .. (#code > 50 and '...' or ''),
        '',
      }

      if #output_lines > 0 then
        vim.list_extend(result_lines, output_lines)
      end

      if #stderr_lines > 0 then
        table.insert(result_lines, '')
        table.insert(result_lines, 'STDERR:')
        vim.list_extend(result_lines, stderr_lines)
      end

      if code_result ~= 0 then
        table.insert(result_lines, '')
        table.insert(result_lines, 'Exit code: ' .. code_result)
      end

      table.insert(result_lines, '')

      -- Append to results buffer
      local current_lines = vim.api.nvim_buf_get_lines(state.results_buf, 0, -1, false)
      vim.api.nvim_buf_set_lines(state.results_buf, #current_lines, #current_lines, false, result_lines)

      -- Scroll to bottom in results window
      if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
        local line_count = vim.api.nvim_buf_line_count(state.results_buf)
        vim.api.nvim_win_set_cursor(state.results_win, { line_count, 0 })
      end
    end)
  end

  -- Start the process
  vim.system({ output }, {
    stdout = function(_, data)
      if data then
        vim.list_extend(output_lines, vim.split(data, '\n'))
      end
    end,
    stderr = function(_, data)
      if data then
        vim.list_extend(stderr_lines, vim.split(data, '\n'))
      end
    end,
  }, function(result)
    on_exit(result.code)
  end)
end

--- Executes external languages (Python, JavaScript, etc.)
--- @return nil
local function execute_external_language()
  local lines = vim.api.nvim_buf_get_lines(state.scratch_buf, 0, -1, false)
  local code = table.concat(lines, '\n')

  -- Ensures there is code to execute
  if trim(code) == '' then
    return Snacks.notify.error('No code to execute', 'Scratch', 'No code to execute')
  end

  -- Gets the current language and the command to execute
  local lang = state.current_language
  local command = config.languages[lang].cmd

  -- Checks if is possible to execute the command
  if not command then
    return Snacks.notify.error('Language not supported!', 'Scratch', 'Language ' .. lang .. ' is not supported!')
  end

  -- Executes the command
  local output = prepare(lang.icon, command, code)

  -- Shows the output in the results buffer
  show_execution_result(code, output)
end

--- Executes the current code
--- @return nil
local function execute_code()
  -- Check if the scratch buffer is valid
  if not state.scratch_buf or not vim.api.nvim_buf_is_valid(state.scratch_buf) then
    return Snacks.notify.error('No Buffer', 'Scratch', 'No scratch buffer available')
  end

  -- Clears previous results if configured
  if config.execution.clear_on_run then
    clear_results()
  end

  -- Switches to scratch buffer to execute
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(state.scratch_win)

  -- Gets the current language
  local lang = config.languages[state.current_language]
  if state.current_language == 'lua' then
    -- If Lua, use Snacks' native execution via debug.run
    Snacks.notify.warn(
      lang.icon,
      lang.cmd,
      table.concat(vim.api.nvim_buf_get_lines(state.scratch_buf, 0, -1, false), '\n')
    )
    -- Printout the output within the current buffer
    Snacks.debug.run({ buf = state.scratch_buf, name = 'scratch.' .. lang, print = true })
  else
    -- Other languages, perform external execution
    execute_external_language()
  end

  -- Returns to the original window
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

--- Opens the scratch panel
--- @param settings table Language settings
--- @return table Scratch panel configuration
local function open_scratch_panel_for(settings)
  -- Opens the scratch buffer
  local scratch_win = Snacks.scratch({
    name = settings.name .. ' Scratch',
    ft = state.current_language,
    template = settings.default_template,
    win = {
      position = config.panel.position,
      width = config.panel.width,
      height = vim.o.lines - 4,
      border = 'rounded',
      title = ' ' .. settings.icon .. ' ' .. settings.name .. ' Scratch ',
      title_pos = 'center',
      backdrop = false,
      keys = {
        -- Execute code
        execute = {
          '<D-Enter>',
          function(win)
            state.scratch_win = win.win
            state.scratch_buf = win.buf
            execute_code()
          end,
          desc = 'Execute the current code',
          mode = { 'n', 'i', 'v' },
        },
        -- Clear results
        clear = {
          '<C-c>',
          clear_results,
          desc = 'Clear',
          mode = { 'n', 'i' },
        },
        -- Close panel
        close = {
          '<Esc>',
          close_panel,
          desc = 'Close',
          mode = { 'n' },
        },
      },
    },
  })

  local current_state = vim.tbl_deep_extend('force', state, scratch_win, {
    scratch_win = scratch_win.win,
    scratch_buf = scratch_win.buf,
    panel_open = true,
  })

  -- Enter insert mode
  vim.cmd('startinsert!')

  return current_state
end

return function()
  local get_filetypes = vim.tbl_keys(config.languages)

  Snacks.picker.select(get_filetypes, {
    prompt = 'Select a filetype',
  }, function(ft)
    if type(ft) == nil then
      return
    end
    vim.schedule(function()
      Snacks.scratch({
        ft = ft,
        format = 'text',
        layout = {
          layout = { title = ' Select Scratch Buffer: ' },
          preset = function()
            return vim.o.columns >= 120 and 'default' or 'vertical'
          end,
        },
        on_change = function()
          vim.schedule(function()
            open_scratch_panel_for(config.languages[ft])
          end)
        end,
      })
    end)
  end)
end
