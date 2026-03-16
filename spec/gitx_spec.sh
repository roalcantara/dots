# ShellSpec spec for gitx (git complex commands dispatcher)
# https://shellspec.info
#
# Run from project root: shellspec spec/gitx_spec.sh
# Uses Include + Mock so we don't depend on show_usage or FPATH.

Describe 'gitx'
  GITX_DIR="config/zsh/etc/functions"
  GITX_SCRIPT="$GITX_DIR/gitx"

  # Avoid "file exists" in call_after_hooks when zsh has set -o noclobber (see shellspec#321)
  disable_noclobber() { set +o noclobber 2>/dev/null; true; }
  BeforeAll disable_noclobber

  # Load gitx (sourcing defines functions; skip entrypoint when sourced for tests)
  GITX_SOURCED_FOR_TEST=1
  Include "$GITX_DIR/gitx"

  # Ensure Mock overrides any show_usage autoloaded from the same directory as gitx
  BeforeAll 'unfunction show_usage 2>/dev/null; true'

  Describe 'help and options (with mocked show_usage)'
    Mock show_usage
      echo "Usage: gitx <command> [options] [args]"
      echo "Options: -h, --help"
      echo "Commands: cnb, nb, branches, ..."
    End

    It 'shows usage with --help'
      When call gitx --help
      The status should equal 0
      The output should include 'Usage'
      The output should include 'gitx'
    End

    It 'shows usage with -h'
      When call gitx -h
      The status should equal 0
      The output should include 'Usage'
    End

    It 'fails and reports unknown command for invalid subcommand'
      When call gitx no-such-command
      The status should be failure
      The stderr should include "unknown command"
      The stderr should include "no-such-command"
    End
  End


  Describe 'fails with usage when no command given'
    It 'prints usage to stderr and fails (from ${1:?} in dispatcher)'
      When run gitx
      The status should equal 1
      The stderr should include 'Usage'
      The stderr should include 'gitx'
    End
  End

  Describe 'subcommand recognition (smoke tests)'
    Parameters
      'cnb'
      'nb'
      'branches'
      'to-yaml'
      'patches'
    End
    It "recognizes subcommand '$1'"
      When run command zsh "$GITX_SCRIPT" "$1"
      The stderr should not include "unknown command"
    End
  End

  Describe 'cnb (create new branch)'
    Mock show_usage
      echo "Usage: gitx cnb <branch>"
      return ${1:-0}
    End
    It 'fails with usage when branch name is missing'
      When call gitx cnb
      The status should be failure
      The output should include 'Usage: gitx cnb'
    End
  End

  Describe 'nb (new branch from origin/main)'
    It 'fails with usage when branch name is missing (from ${1:?} in helper)'
      When run gitx nb
      The status should equal 1
      The stderr should include 'Usage: gitx nb'
    End
  End

  Describe 'remove-submodule'
    It 'fails with usage when path is missing (from ${1:?} in helper)'
      When run gitx remove-submodule
      The status should equal 1
      The stderr should include 'Usage: gitx remove-submodule'
    End
  End

  Describe 'remove-files'
    It 'fails with usage when pattern is missing (from ${1:?} in helper)'
      When run gitx remove-files
      The status should equal 1
      The stderr should include 'Usage: gitx remove-files'
    End
  End

  Describe 'to-yaml (in a git repo)'
    It 'outputs YAML when run with default count'
      When call gitx to-yaml
      The status should equal 0
      The output should include ': |'
    End

    It 'outputs YAML when run with count 3'
      When call gitx to-yaml 3
      The status should equal 0
      The output should include ': |'
    End
  End
End
