--- @diagnostic disable: duplicate-set-field, need-check-nil

local format = require('core/etc/git/format_conventional_commit')

describe('#core.etc.git.format_conventional_commit', function()
  describe('header', function()
    it('keeps a valid message unchanged', function()
      assert.are.equal('feat(util): Add trim function', format('feat(util): Add trim function'))
    end)

    it('cuts the first line to 50 characters at a word boundary', function()
      local result = format('ref(bin): Implement helper functions for binary checking and output handling')
      assert.are.equal('ref(bin): Implement helper functions', result)
      assert.is_true(#result <= 50)
    end)

    it('drops a short unfinished tail after a cut', function()
      local result = format('feat(nvim): Update configuration files and enhance LLM provider setup')
      assert.are.equal('feat(nvim): Update configuration files', result)
    end)

    it('keeps a longer clause after a conjunction', function()
      local result = format('ref(nvim): Improve configuration and LLM provider setup')
      assert.are.equal('ref(nvim): Improve configuration and LLM provider', result)
    end)

    it('drops dangling words and honours a custom limit', function()
      assert.are.equal('docs: Update', format('docs: Update the design spec', { max_header = 16 }))
    end)

    it('capitalizes the subject and drops a trailing period', function()
      assert.are.equal('fix(zsh): Remove broken aliases', format('fix(zsh): remove broken aliases.'))
    end)

    it('maps refactor to ref', function()
      assert.are.equal('ref(docs): Update spec', format('refactor(docs): Update spec'))
    end)

    it('keeps the breaking-change marker and handles a missing scope', function()
      assert.are.equal('feat!: Drop legacy loader', format('feat!: drop legacy loader'))
    end)

    it('hard-cuts a single word longer than the limit', function()
      local result = format('feat(bin): ' .. string.rep('x', 60))
      assert.are.equal('feat(bin): X' .. string.rep('x', 38), result)
    end)
  end)

  describe('scope', function()
    it('keeps the term the repository used most', function()
      local result = format('ref(config, nvim, llm): Improve setup', { scopes = { nvim = 28, bin = 34 } })
      assert.are.equal('ref(nvim): Improve setup', result)
    end)

    it('falls back to the term matching most changed paths', function()
      local paths = { 'config/nvim/init.lua', 'config/zsh/.zshrc', 'config/zsh/aliases.zsh' }
      assert.are.equal('fix(zsh): Fix it', format('fix(nvim, zsh): Fix it', { paths = paths }))
    end)

    it('replaces a scope that names nothing in the changes', function()
      local paths = { 'config/nvim/a.lua', 'config/nvim/b.lua', 'config/zsh/.zshrc', 'docs/x.txt' }
      local result =
        format('feat(bin): Add x', { scopes = { bin = 34, nvim = 28, zsh = 33, config = 4 }, paths = paths })
      assert.are.equal('feat(nvim): Add x', result)
    end)

    it('ignores terms shared by nearly every changed path when replacing', function()
      local paths = { 'config/nvim/a.lua', 'config/nvim/b.lua', 'config/zsh/.zshrc', 'config/zsh/x', 'config/zsh/y' }
      local result = format('feat(bin): Add x', { scopes = { config = 9, nvim = 1, zsh = 1 }, paths = paths })
      assert.are.equal('feat(zsh): Add x', result)
    end)

    it('falls back to the first term without hints', function()
      assert.are.equal('fix(zsh): Fix it', format('fix(zsh, bin): Fix it'))
    end)
  end)

  describe('body', function()
    it('wraps each line at 70 characters and drops trailing blank lines', function()
      local result = format(
        'ref(nvim): Improve setup\n\n'
          .. 'Updates configuration files, including adding LM Studio CLI path to PATH, updating Homebrew casks.\n'
          .. 'Refactors Lua files.\n\n\n'
      )
      assert.are.equal(
        'ref(nvim): Improve setup\n\n'
          .. 'Updates configuration files, including adding LM Studio CLI path to\n'
          .. 'PATH, updating Homebrew casks.\n'
          .. 'Refactors Lua files.',
        result
      )
    end)

    it('indents the continuation of list items', function()
      local result = format('feat(bin): Add x\n\n- ' .. string.rep('word ', 16) .. 'end')
      assert.are.equal('feat(bin): Add x\n\n- ' .. string.rep('word ', 12) .. 'word\n  word word word end', result)
    end)

    it('collapses runs of blank lines', function()
      assert.are.equal('fix: Correct alias\n\nOne\n\nTwo', format('fix: Correct alias\n\n\nOne\n\n\n\nTwo'))
    end)

    it('strips markdown fences and separates the body with a blank line', function()
      assert.are.equal('fix: Correct alias\n\n- Explain why', format('```\nfix: Correct alias\n- Explain why\n```'))
    end)
  end)

  it('returns non-conventional messages trimmed but untouched', function()
    assert.are.equal('Not a conventional header', format('  Not a conventional header  \n'))
  end)
end)
