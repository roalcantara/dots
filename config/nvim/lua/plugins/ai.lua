return {
  -- Copilot plugin for Neovim configured for using blink-copilot with lazy.nvim
  -- https://github.com/fang2hou/blink-copilot?tab=readme-ov-file#-recipes
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        ['*'] = true,
      },
    }
  },
}
