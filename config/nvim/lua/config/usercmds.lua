-- https://neovim.io/doc/user/lua-guide.html#lua-guide-commands-create
require('core/vi/au').setup_user_commands_async({
  GenerateGitCommit = {
    command = require('core/ui/git/commits').generate_conventional_commit,
    opts = {
      desc = 'Generate a git conventional commit message',
    },
  },
  -- https://github.com/folke/snacks.nvim/blob/main/docs/notifier.md#snacksnotifiershow_history
  History = {
    command = function()
      return Snacks.notifier.show_history()
    end,
    opts = {
      desc = 'Show Notification History',
    },
  },
})
