return _G.imports('cmp_git', function(plugin)
  local format = require('cmp_git/format')
  local sort = require('cmp_git/sort')
  return plugin.setup({
    filetypes = {
      'gitcommit',
      'octo'
    },
    remotes = {
      'upstream',
      'origin'
    },
    enableRemoteUrlRewrites = false,
    git = {
      commits = {
        limit = 100,
        sort_by = sort.git.commits,
        format = format.git.commits
      }
    },
    github = {
      issues = {
        fields = {
          'title',
          'number',
          'body',
          'updatedAt',
          'state'
        },
        filter = 'all',
        limit = 100,
        state = 'open',
        sort_by = sort.github.issues,
        format = format.github.issues
      },
      mentions = {
        limit = 100,
        sort_by = sort.github.mentions,
        format = format.github.mentions
      },
      pull_requests = {
        fields = {
          'title',
          'number',
          'body',
          'updatedAt',
          'state'
        },
        limit = 100,
        state = 'open',
        sort_by = sort.github.pull_requests,
        format = format.github.pull_requests
      }
    },
    trigger_actions = {
      {
        debug_name = 'git_commits',
        trigger_character = ':',
        action = function(sources, trigger_char, callback, params, _)
          return sources.git:get_commits(callback, params, trigger_char)
        end
      },
      {
        debug_name = 'github_issues_and_pr',
        trigger_character = '#',
        action = function(sources, trigger_char, callback, _, git_info)
          return sources.github:get_issues_and_prs(callback, git_info, trigger_char)
        end
      },
      {
        debug_name = 'github_mentions',
        trigger_character = '@',
        action = function(sources, trigger_char, callback, _, git_info)
          return sources.github:get_mentions(callback, git_info, trigger_char)
        end
      }
    }
  })
end)
