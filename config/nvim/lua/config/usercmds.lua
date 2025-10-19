local noice_helper = require('core/ui/noice')
local git_helpers = require('core/ui/git/commits')
local snacks_pickers = require('core/ui/snacks/pickers')

-- https://neovim.io/doc/user/lua-guide.html#lua-guide-commands-create
require('core/vi/au').setup_user_commands_async({
  GenerateGitCommit = {
    command = git_helpers.generate_conventional_commit,
    opts = {
      desc = 'Generate a git conventional commit message',
    },
  },
  History = {
    command = snacks_pickers.show_history.pick,
    opts = {
      desc = 'History Notifications',
    },
  },
  TotalHistory = {
    command = snacks_pickers.show_history.show_info,
    opts = {
      desc = 'History Search Notifications (total)',
    },
  },
  HistoryCommands = {
    command = snacks_pickers.show_history_commands.pick,
    opts = {
      desc = 'History Command Notifications',
    },
  },
  TotalHistoryCommands = {
    command = snacks_pickers.show_history_commands.show_info,
    opts = {
      desc = 'History Command Notifications (total)',
    },
  },
  HistorySearches = {
    command = snacks_pickers.show_history_searches.pick,
    opts = {
      desc = 'History Search Notifications',
    },
  },
  TotalHistorySearch = {
    command = snacks_pickers.show_history_searches.show_info,
    opts = {
      desc = 'History Search Notifications (total)',
    },
  },
  HistoryMessages = {
    command = snacks_pickers.show_history_messages.pick,
    opts = {
      desc = 'History Messages Notifications',
    },
  },
  TotalHistoryMessages = {
    command = snacks_pickers.show_history_messages.show_info,
    opts = {
      desc = 'History Messages Notifications (total)',
    },
  },
})
