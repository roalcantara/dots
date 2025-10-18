--- @diagnostic disable: duplicate-set-field, need-check-nil

describe('#core.vi.maps', function()
  describe('parse_mappings()', function()
    -- Store original functions to restore later
    local test_function = function() return '<C-d>' end
    local original_keymap_set, original_tbl_deep_extend, original_notify, original_user_command
    local subject -- Will be loaded fresh in each test

    before_each(function()
      -- Store original functions
      original_keymap_set = vim.keymap.set
      original_tbl_deep_extend = vim.tbl_deep_extend
      original_notify = vim.notify

      -- Create spy arrays to track calls
      local keymap_calls = {}
      local tbl_deep_extend_calls = {}
      local notify_calls = {}
      local user_command_calls = {}

      -- Mock vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        table.insert(keymap_calls, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
      end

      -- Mock vim.tbl_deep_extend
      vim.tbl_deep_extend = function(strategy, ...)
        table.insert(tbl_deep_extend_calls, { strategy = strategy, args = { ... } })
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
      end

      -- Mock vim.notify
      vim.notify = function(msg, level)
        table.insert(notify_calls, { msg = msg, level = level })
      end

      -- Mock user_command module
      original_user_command = package.loaded['core/vi/maps/user_command']
      package.loaded['core/vi/maps/user_command'] = function(cmd, action, desc)
        table.insert(user_command_calls, { cmd = cmd, action = action, desc = desc })
        return vim.api.nvim_create_user_command(cmd, action, { desc = desc })
      end

      -- Clear parse_mappings module cache and reload fresh
      package.loaded['core/vi/maps/parse_mappings'] = nil
      subject = require('core/vi/maps/parse_mappings')

      -- Store spy arrays in global scope for assertions
      _G.test_spies = {
        keymap_calls = keymap_calls,
        tbl_deep_extend_calls = tbl_deep_extend_calls,
        notify_calls = notify_calls,
        user_command_calls = user_command_calls
      }
    end)

    after_each(function()
      -- Restore original functions
      vim.keymap.set = original_keymap_set
      vim.tbl_deep_extend = original_tbl_deep_extend
      vim.notify = original_notify
      package.loaded['core/vi/maps/user_command'] = original_user_command

      -- Clear spy arrays
      _G.test_spies = nil
    end)

    it('parses simple mode-specific mappings', function()
      local mappings = {
        ['<D-a>'] = { { n = 'ggVG', i = '<C-O>ggVG', v = '<ESC>ggVG' }, 'Select All' },
      }

      subject(mappings)

      -- Verify vim.keymap.set was called for each mode
      assert.equal(3, #_G.test_spies.keymap_calls) -- n, i, v modes

      -- Check specific calls (order may vary due to pairs() iteration)
      local calls = _G.test_spies.keymap_calls
      assert.equal(3, #calls)

      -- Check that all expected modes are present
      local modes = {}
      for i = 1, #calls do
        modes[calls[i].mode] = true
      end
      assert.is_true(modes['n'])
      assert.is_true(modes['i'])
      assert.is_true(modes['v'])

      -- Check that all calls have the same key
      for i = 1, #calls do
        assert.equal('<D-a>', calls[i].lhs)
      end

      -- Check specific commands for each mode
      for i = 1, #calls do
        if calls[i].mode == 'n' then
          assert.equal('ggVG', calls[i].rhs)
        elseif calls[i].mode == 'i' then
          assert.equal('<C-O>ggVG', calls[i].rhs)
        elseif calls[i].mode == 'v' then
          assert.equal('<ESC>ggVG', calls[i].rhs)
        end
      end
    end)

    it('parses mappings with user commands', function()
      local mappings = {
        ['<D-M-c>'] = { { n = '<CMD>let @+ = expand("%:p")<CR>' }, 'Copy File Path', { cmd = 'CopyFilePath' } },
      }

      subject(mappings)

      -- Verify keymap was created
      assert.equal(1, #_G.test_spies.keymap_calls)

      -- Verify user command was created
      assert.equal(1, #_G.test_spies.user_command_calls)
      local user_cmd_call = _G.test_spies.user_command_calls[1]
      assert.equal('CopyFilePath', user_cmd_call.cmd)
      assert.equal('<CMD>let @+ = expand("%:p")<CR>', user_cmd_call.action)
    end)

    it('parses function-based mappings with expr option', function()
      local mappings = {
        ['<S-Tab>'] = { { n = '<<', v = '<gv', i = { callback = test_function, opts = { expr = true } } }, 'Smart Outdent/Completion' },
      }

      subject(mappings)

      -- Verify vim.keymap.set was called for each mode
      assert.equal(3, #_G.test_spies.keymap_calls) -- n, v, i modes

      -- Check that tbl_deep_extend was called for option merging (may be called multiple times)
      assert.is_true(#_G.test_spies.tbl_deep_extend_calls >= 1)

      -- Check specific calls (find the Shift-Tab calls)
      local calls = _G.test_spies.keymap_calls
      local shift_tab_calls = {}
      for i = 1, #calls do
        if calls[i].lhs == '<S-Tab>' then
          table.insert(shift_tab_calls, calls[i])
        end
      end

      assert.equal(3, #shift_tab_calls) -- Should have 3 Shift-Tab calls

      -- Check that all expected modes are present for Shift-Tab
      local modes = {}
      for i = 1, #shift_tab_calls do
        modes[shift_tab_calls[i].mode] = true
      end
      assert.is_true(modes['n'])
      assert.is_true(modes['v'])
      assert.is_true(modes['i'])

      -- Check specific commands for each mode
      for i = 1, #shift_tab_calls do
        if shift_tab_calls[i].mode == 'n' then
          assert.equal('<<', shift_tab_calls[i].rhs)
        elseif shift_tab_calls[i].mode == 'v' then
          assert.equal('<gv', shift_tab_calls[i].rhs)
        elseif shift_tab_calls[i].mode == 'i' then
          assert.equal(test_function, shift_tab_calls[i].rhs)
        end
      end
    end)

    it('parses single mode mappings', function()
      local mappings = {
        ['<D-C-h>'] = { { v = 'y:%s#<C-R>=@"<CR>#' }, 'Replace the selected text' },
      }

      subject(mappings)

      -- Verify vim.keymap.set was called once
      assert.equal(1, #_G.test_spies.keymap_calls)

      -- Check specific call
      local call = _G.test_spies.keymap_calls[1]
      assert.equal('v', call.mode)
      assert.equal('<D-C-h>', call.lhs)
      assert.equal('y:%s#<C-R>=@"<CR>#', call.rhs)
    end)

    it('handles complex command structures', function()
      local test_function = function() return 'complex' end
      local mappings = {
        ['<D-f>'] = {
          { n = 'simple_command', i = { callback = test_function, opts = { expr = true } } }
        },
        'Complex Test',
      }

      subject(mappings)

      -- Verify vim.keymap.set was called for both modes (plus previous calls)
      assert.equal(3, #_G.test_spies.keymap_calls)

      -- Check specific calls (find the D-f calls)
      local calls = _G.test_spies.keymap_calls
      local d_f_calls = {}
      for i = 1, #calls do
        if calls[i].lhs == '<D-f>' then
          table.insert(d_f_calls, calls[i])
        end
      end

      assert.equal(2, #d_f_calls) -- Should have 2 D-f calls

      -- Check that all expected modes are present for D-f
      local modes = {}
      for i = 1, #d_f_calls do
        modes[d_f_calls[i].mode] = true
      end
      assert.is_true(modes['n'])
      assert.is_true(modes['i'])

      -- Check specific commands for each mode
      for i = 1, #d_f_calls do
        if d_f_calls[i].mode == 'n' then
          assert.equal('simple_command', d_f_calls[i].rhs)
        elseif d_f_calls[i].mode == 'i' then
          assert.equal(test_function, d_f_calls[i].rhs)
        end
      end
    end)

    it('handles array format commands', function()
      local mappings = {
        ['<D-g>'] = {
          { n = { 'array_command', { silent = true } } }
        },
        'Array Format Test',
      }

      subject(mappings)

      -- Verify vim.keymap.set was called (plus previous calls)
      assert.equal(2, #_G.test_spies.keymap_calls)

      -- Check specific call (find the D-g call)
      local calls = _G.test_spies.keymap_calls
      local d_g_call = nil
      for i = 1, #calls do
        if calls[i].lhs == '<D-g>' then
          d_g_call = calls[i]
          break
        end
      end

      assert.is_not_nil(d_g_call)
      assert.equal('n', d_g_call.mode)
      assert.equal('<D-g>', d_g_call.lhs)
      assert.equal('array_command', d_g_call.rhs)
    end)

    it('handles keymap creation errors gracefully', function()
      -- Mock vim.keymap.set to throw an error
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function() error('Test error') end

      local mappings = {
        ['<D-test>'] = { { n = 'test_command' }, 'Test Command' },
      }

      subject(mappings)

      -- Verify error notification was sent
      assert.equal(1, #_G.test_spies.notify_calls)
      local notify_call = _G.test_spies.notify_calls[1]
      assert.equal('Failed to set keymap: <D-test> for command: test_command', notify_call.msg)
      assert.equal(4, notify_call.level) -- ERROR level

      -- Restore original function
      vim.keymap.set = original_keymap_set
    end)

    it('handles user command creation errors gracefully', function()
      -- Mock user_command to throw an error and reload subject
      local original_user_command = package.loaded['core/vi/maps/user_command']
      package.loaded['core/vi/maps/user_command'] = function() error('User command error') end

      -- Reload subject with the error-throwing mock
      package.loaded['core/vi/maps/parse_mappings'] = nil
      local error_subject = require('core/vi/maps/parse_mappings')

      local mappings = {
        ['<D-test>'] = { { n = 'test_command' }, 'Test Command', { cmd = 'TestCmd' } },
      }

      error_subject(mappings)

      -- Verify error notification was sent
      assert.equal(1, #_G.test_spies.notify_calls)
      local notify_call = _G.test_spies.notify_calls[1]
      assert.is_true(notify_call.msg:find('Failed to create user') ~= nil)
      assert.equal(4, notify_call.level) -- ERROR level

      -- Restore original function
      package.loaded['core/vi/maps/user_command'] = original_user_command
    end)

    it('formats key combinations correctly', function()
      local mappings = {
        ['<D-a>'] = { { n = 'ggVG', i = '<C-O>ggVG', v = '<ESC>ggVG' }, 'Select All' },
        ['<D-S-M-C-Space>'] = { { n = 'complex_key' }, 'Complex Key Test' },
        ['<Tab>'] = { { n = 'tab_key' }, 'Tab Test' },
        ['<S-Tab>'] = { { n = '<<', v = '<gv', i = { callback = test_function, opts = { expr = true } } }, 'Smart Outdent/Completion' },
      }

      subject(mappings)

      -- Verify keymap.set was called for each key
      assert.equal(8, #_G.test_spies.keymap_calls) -- 4 keys: 3+1+1+3 modes
    end)

    it('handles non-string keys gracefully', function()
      local mappings = {
        [1] = { 'numeric_key', 'Numeric Key Test' },
        [true] = { 'boolean_key', 'Boolean Key Test' },
      }

      subject(mappings)

      -- Verify keymap.set was called for each key
      assert.equal(2, #_G.test_spies.keymap_calls)
    end)
  end)
end)
