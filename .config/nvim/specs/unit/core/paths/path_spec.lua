local path = require('core/paths/path')

local scenarios = {
  to_path = {
    {
      when = {arg1 = '~/.config', arg2 = 'nvim'},
      expected = '~/.config/nvim'
    },
    {
      when = {arg1 = '~/.config'},
      expected = '~/.config'
    },
    {
      when = {arg1 = '~/.cache/nvim', arg2 = 'debug'},
      expected = '~/.cache/nvim/debug'
    }
  },
  to_stdpath = {
    {
      when = {stdpath = 'cache', arg1 = 'debug'},
      expected = '~/.cache/nvim/debug'
    },
    {
      when = {stdpath = 'data', arg1 = 'foo'},
      expected = '~/.local/share/nvim/foo'
    },
    {
      when = {stdpath = 'config', arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.config/nvim/foo/bar'
    }
  },
  conf = {
    {
      expected = '~/.config/nvim'
    },
    {
      when = {arg1 = 'debug'},
      expected = '~/.config/nvim/debug'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.config/nvim/foo/bar'
    }
  },
  dots = {
    {
      expected = '~/.config'
    },
    {
      when = {arg1 = 'nvim'},
      expected = '~/.config/nvim'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.config/foo/bar'
    }
  },
  data = {
    {
      expected = '~/.local/share/nvim'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.local/share/nvim/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.local/share/nvim/foo/bar'
    }
  },
  cache = {
    {
      expected = '~/.cache/nvim'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.cache/nvim/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.cache/nvim/foo/bar'
    }
  },
  debug = {
    {
      expected = '~/.cache/nvim/debug'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.cache/nvim/debug/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.cache/nvim/debug/foo/bar'
    }
  },
  log = {
    {
      expected = '~/.cache/nvim/debug/log'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.cache/nvim/debug/log/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.cache/nvim/debug/log/foo/bar'
    }
  },
  session = {
    {
      expected = '~/.cache/nvim/session'
    }
  },
  undo = {
    {
      expected = '~/.local/share/nvim/undo'
    }
  },
  backup = {
    {
      expected = '~/.local/share/nvim/backup'
    }
  },
  view = {
    {
      expected = '~/.local/share/nvim/view'
    }
  },
  swap = {
    {
      expected = '~/.local/share/nvim/swap'
    }
  },
  spellfile = {
    {
      expected = '~/.local/share/nvim/spell/en.utf-8.add'
    }
  },
  lsp_servers = {
    {
      expected = '~/.local/share/nvim/lsp_servers'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.local/share/nvim/lsp_servers/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.local/share/nvim/lsp_servers/foo/bar'
    }
  },
  global_snippets = {
    {
      expected = '~/.config/snippets'
    }
  },
  package_root = {
    {
      expected = '~/.local/share/nvim/site/pack'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.local/share/nvim/site/pack/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.local/share/nvim/site/pack/foo/bar'
    }
  },
  packer_start = {
    {
      expected = '~/.local/share/nvim/site/pack/packer/start'
    },
    {
      when = {arg1 = 'foo'},
      expected = '~/.local/share/nvim/site/pack/packer/start/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = '~/.local/share/nvim/site/pack/packer/start/foo/bar'
    }
  },
  packer = {
    {
      expected = '~/.local/share/nvim/site/pack/packer/start/packer.nvim'
    }
  },
  server_config = {
    {
      expected = 'neo/etc/lsp/langs'
    },
    {
      when = {arg1 = 'foo'},
      expected = 'neo/etc/lsp/langs/foo'
    },
    {
      when = {arg1 = 'foo', arg2 = 'bar'},
      expected = 'neo/etc/lsp/langs/foo/bar'
    }
  }
}

describe("Path", function()
  describe("#to_path()", function()
    for _, scenario in ipairs(scenarios.to_path) do
      it("returns the path " .. scenario.expected, function()
        if scenario.when.arg2 then
          assert.are.same(scenario.expected, path.to_path(scenario.when.arg1, scenario.when.arg2))
        else
          assert.are.same(scenario.expected, path.to_path(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#to_stdpath()", function()
    for _, scenario in ipairs(scenarios.to_stdpath) do
      it("returns the stdpath for " .. scenario.expected, function()
        if scenario.when.arg2 then
          assert.are.same(scenario.expected,
            path.to_stdpath(scenario.when.stdpath, scenario.when.arg1, scenario.when.arg2))
        else
          assert.are.same(scenario.expected, path.to_stdpath(scenario.when.stdpath, scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#conf()", function()
    for _, scenario in ipairs(scenarios.conf) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.conf())
        elseif scenario.when.arg2 then
          assert.are.same(scenario.expected, path.conf(scenario.when.arg1, scenario.when.arg2))
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.conf(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#dots()", function()
    for _, scenario in ipairs(scenarios.dots) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.dots())
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.dots(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#data()", function()
    for _, scenario in ipairs(scenarios.data) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.data())
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.data(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#cache()", function()
    for _, scenario in ipairs(scenarios.cache) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.cache())
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.cache(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#debug()", function()
    for _, scenario in ipairs(scenarios.debug) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.debug())
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.debug(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#log()", function()
    for _, scenario in ipairs(scenarios.log) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.log())
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.log(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#session()", function()
    for _, scenario in ipairs(scenarios.session) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.session())
      end)
    end
  end)

  describe("#view()", function()
    for _, scenario in ipairs(scenarios.view) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.view())
      end)
    end
  end)

  describe("#swap()", function()
    for _, scenario in ipairs(scenarios.swap) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.swap())
      end)
    end
  end)

  describe("#spellfile()", function()
    for _, scenario in ipairs(scenarios.spellfile) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.spellfile())
      end)
    end
  end)

  describe("#lsp()", function()
    for _, scenario in ipairs(scenarios.lsp_servers) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.lsp())
        elseif scenario.when.arg2 then
          assert.are.same(scenario.expected, path.lsp(scenario.when.arg1, scenario.when.arg2))
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.lsp(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#global_snippets()", function()
    for _, scenario in ipairs(scenarios.global_snippets) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.global_snippets())
      end)
    end
  end)

  describe("#package_root()", function()
    for _, scenario in ipairs(scenarios.package_root) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.package_root())
        elseif scenario.when.arg2 then
          assert.are.same(scenario.expected, path.package_root(scenario.when.arg1, scenario.when.arg2))
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.package_root(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#packer_start()", function()
    for _, scenario in ipairs(scenarios.packer_start) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.packer_start())
        elseif scenario.when.arg2 then
          assert.are.same(scenario.expected, path.packer_start(scenario.when.arg1, scenario.when.arg2))
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.packer_start(scenario.when.arg1))
        end
      end)
    end
  end)

  describe("#packer()", function()
    for _, scenario in ipairs(scenarios.packer) do
      it("returns the path for " .. scenario.expected, function()
        assert.are.same(scenario.expected, path.packer())
      end)
    end
  end)

  describe("#server_config()", function()
    for _, scenario in ipairs(scenarios.server_config) do
      it("returns the path for " .. scenario.expected, function()
        if not scenario.when then
          assert.are.same(scenario.expected, path.server_config())
        elseif scenario.when.arg2 then
          assert.are.same(scenario.expected, path.server_config(scenario.when.arg1, scenario.when.arg2))
        elseif scenario.when.arg1 then
          assert.are.same(scenario.expected, path.server_config(scenario.when.arg1))
        end
      end)
    end
  end)
end)