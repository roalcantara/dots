--- @diagnostic disable: duplicate-set-field, need-check-nil

describe('#core.vi.paths', function()
  local subject -- Will be loaded fresh in each test
  before_each(function()
    subject = require('core/vi/paths')
  end)

  after_each(function()
    subject = nil
  end)

  describe('join()', function()
    it('joins two paths', function()
      local result = subject.join('foo', 'bar')
      assert.are.equal(result, 'foo/bar')
    end)

    it('joins multiple paths', function()
      local result = subject.join('path', 'to', 'foo', 'bar')
      assert.are.equal(result, 'path/to/foo/bar')
    end)

    it('joins a table of paths', function()
      local result = subject.join({ 'path', 'to', 'foo', 'bar' })
      assert.are.equal(result, 'path/to/foo/bar')
    end)
  end)

  describe('xdg', function()
    describe('config', function()
      local current_xdg_config_home

      before_each(function()
        current_xdg_config_home = '/home/dev/.config'
      end)

      describe('path_for()', function()
        before_each(function()
          vim.env.XDG_CONFIG_HOME = current_xdg_config_home
        end)

        after_each(function()
          vim.env.XDG_CONFIG_HOME = nil
        end)

        describe('with no arguments', function()
          it('returns the XDG_CONFIG_HOME path', function()
            local result = subject.xdg.config.path_for()
            assert.are.equal(result, current_xdg_config_home)
          end)
        end)

        describe('with `ghostty` and `config`', function()
          it('returns the ghostty config path under XDG_CONFIG_HOME', function()
            local result = subject.xdg.config.path_for('ghostty', 'config')
            assert.are.equal(result, current_xdg_config_home .. '/ghostty/config')
          end)
        end)
      end)
    end)
  end)
end)
