-- Resolve helpers on first invocation, not at startup. Eagerly requiring
-- core/ui/snacks/pickers here costs ~10ms during spec collection.
local function git_helpers()
  return require('core/ui/git/commits')
end

local function snacks_pickers()
  return require('core/ui/snacks/pickers')
end

-- https://neovim.io/doc/user/lua-guide.html#lua-guide-commands-create
require('core/vi/au').setup_user_commands_async({
  GenerateGitCommit = {
    command = function(...)
      return git_helpers().generate_conventional_commit(...)
    end,
    opts = {
      desc = 'Generate a git conventional commit message',
    },
  },
  History = {
    command = function(...)
      return snacks_pickers().show_history.pick(...)
    end,
    opts = {
      desc = 'History Notifications',
    },
  },
  TotalHistory = {
    command = function(...)
      return snacks_pickers().show_history.show_info(...)
    end,
    opts = {
      desc = 'History Search Notifications (total)',
    },
  },
  HistoryCommands = {
    command = function(...)
      return snacks_pickers().show_history_commands.pick(...)
    end,
    opts = {
      desc = 'History Command Notifications',
    },
  },
  TotalHistoryCommands = {
    command = function(...)
      return snacks_pickers().show_history_commands.show_info(...)
    end,
    opts = {
      desc = 'History Command Notifications (total)',
    },
  },
  HistorySearches = {
    command = function(...)
      return snacks_pickers().show_history_searches.pick(...)
    end,
    opts = {
      desc = 'History Search Notifications',
    },
  },
  TotalHistorySearch = {
    command = function(...)
      return snacks_pickers().show_history_searches.show_info(...)
    end,
    opts = {
      desc = 'History Search Notifications (total)',
    },
  },
  HistoryMessages = {
    command = function(...)
      return snacks_pickers().show_history_messages.pick(...)
    end,
    opts = {
      desc = 'History Messages Notifications',
    },
  },
  TotalHistoryMessages = {
    command = function(...)
      return snacks_pickers().show_history_messages.show_info(...)
    end,
    opts = {
      desc = 'History Messages Notifications (total)',
    },
  },
})
