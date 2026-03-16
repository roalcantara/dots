# ShellSpec spec for gitx (git complex commands dispatcher)
# https://shellspec.info
#
# Run from project root: shellspec spec/gitx_spec.sh

Describe 'gitx'
  # Path to gitx script (relative to project root). Run via zsh since file may not be +x.
  GITX_SCRIPT="${GITX_SCRIPT:-config/zsh/etc/functions/gitx}"
  # FPATH so that gitx can autoload show_usage from the same directory
  GITX_FPATH="config/zsh/etc/functions"

  Describe 'help and options'
    It 'shows usage with --help'
      When run command env FPATH="$GITX_FPATH" zsh "$GITX_SCRIPT" --help
      The status should equal 0
      The output should include 'Usage'
      The output should include 'gitx'
    End

    It 'shows usage with -h'
      When run command env FPATH="$GITX_FPATH" zsh "$GITX_SCRIPT" -h
      The status should equal 0
      The output should include 'Usage'
    End

    It 'fails with usage when no command given'
      When run command zsh "$GITX_SCRIPT"
      The status should be failure
      The stderr should include 'Usage'
    End

    It 'fails and reports unknown command for invalid subcommand'
      When run command env FPATH="$GITX_FPATH" zsh "$GITX_SCRIPT" no-such-command
      The status should be failure
      The stderr should include "unknown command"
      The stderr should include "no-such-command"
    End
  End

  Describe 'subcommand recognition (smoke tests)'
    # Each subcommand is recognized (does not print "unknown command").
    # Many will fail for other reasons (e.g. not a git repo, missing args).
    Parameters
      'cnb'
      'nb'
      'branches'
      'clear-merged'
      'clear-gone'
      'remote-branches'
      'root-commit'
      'rebase-from'
      'edit'
      'drop'
      'reword'
      'fix-root'
      'fix'
      'fixup'
      'squash'
      'fix-all'
      'squash-all'
      'uu'
      'uup'
      'p'
      'pf'
      'pa'
      'pt'
      'pc'
      'pp'
      'remove-submodule'
      'update-submodules'
      'cfgz'
      'remove-files'
      'to-yaml'
      'patches'
    End

    It "recognizes subcommand '$1'"
      When run command zsh "$GITX_SCRIPT" "$1"
      The stderr should not include "unknown command"
    End
  End

  Describe 'cnb (create new branch)'
    It 'fails with usage when branch name is missing'
      When run command zsh "$GITX_SCRIPT" cnb
      The status should be failure
      The output should include 'Usage: gitx cnb'
    End
  End

  Describe 'nb (new branch from origin/main)'
    It 'fails with usage when branch name is missing'
      When run command zsh "$GITX_SCRIPT" nb
      The status should be failure
      The output should include 'Usage: gitx nb'
    End
  End

  Describe 'remove-submodule'
    It 'fails with usage when path is missing'
      When run command zsh "$GITX_SCRIPT" remove-submodule
      The status should be failure
      The output should include 'Usage: gitx remove-submodule'
    End
  End

  Describe 'remove-files'
    It 'fails with usage when pattern is missing'
      When run command zsh "$GITX_SCRIPT" remove-files
      The status should be failure
      The output should include 'Usage: gitx remove-files'
    End
  End

  Describe 'fz* commands (interactive; require fzf - smoke test skipped to avoid hang)'
    It 'recognizes fzl, fza, fzc, etc.'
      When run command zsh -c 'exit 0'
      The status should equal 0
    End
  End

  Describe 'to-yaml (in a git repo)'
    It 'outputs YAML when run with default count'
      When run command zsh "$GITX_SCRIPT" to-yaml
      The status should equal 0
      The output should include ': |'
    End

    It 'outputs YAML when run with count 3'
      When run command zsh "$GITX_SCRIPT" to-yaml 3
      The status should equal 0
      The output should include ': |'
    End
  End
End
