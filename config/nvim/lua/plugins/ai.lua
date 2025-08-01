return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        ['*'] = true
      },
    },
    config = function(_, opts)
      require('copilot').setup(opts)
      vim.keymap.set('i', '<S-Tab>', function()
        if require('copilot.suggestion').is_visible() then
          require('copilot.suggestion').accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true), 'n', true)
          -- require('copilot.suggestion').next()
        end
      end, { silent = false, desc = 'Accept Copilot suggestion or next' })
    end
  }
}
