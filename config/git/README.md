# GIT

The stupid content tracker

## FILES

If not set explicitly with --file, there are four files where git config will search for configuration options:

1. `$(prefix)/etc/gitconfig`
  System-wide configuration file.

2. `$XDG_CONFIG_HOME/git/config`
  Second user-specific configuration file.

   - If `$XDG_CONFIG_HOME` is not set or empty, `$HOME/.config/git/config` will be used.
   - Any single-valued variable set in this file will be overwritten by whatever is in `~/.gitconfig`.
   - It is a good idea not to create this file if you sometimes use older versions of Git, as support for this file was added fairly recently.

3. `~/.gitconfig`
  User-specific configuration file. Also called `"global"` configuration file.

4. `$GIT_DIR/config`
  Repository specific configuration file.

5. `$GIT_DIR/config.worktree`
  This is optional and is only searched when extensions.worktreeConfig is present in `$GIT_DIR/config`.

## Configuration

```tree
git
│── config
│── attributes
│── alias.inc
│── auth.inc
│── auth-work.inc
│── color.inc
│── filter.inc
│── delta.inc
└── .zshrc
```

### Global

You can specify Git configuration settings [globally][2] with the git config command:

```sh
  # Set a Git username and email
  git config --global user.name "John Doe"
  git config --global user.email johndoe@example.com
```

Confirm that you have set the Git username correctly:

```sh
  $ git config user.name
  > John Doe
```

### Hooks and Validation

This project uses [hk](https://hk.jdx.dev) to manage git hooks and run commit message validation (Conventional Commits formatting) and staged-file linting automatically on commit. See [hk.pkl](../../hk.pkl) and the [hk configuration guide](../hk/README.md) for more details.

### Direnv

## References

- [git: The stupid content tracker][0]
- [About Version Control][1]
- [Get and set repository or global options][2]
- [Command aliases for the git command wrapper][3]
- [Signing Your Work][4]
- [Keep sensitive data encrypted in dotfiles][5]
- [Managing multiple Git profiles][6]
- [Set commit signing per git repository][7]

[0]: <https://git-scm.com/docs/git> "The stupid content tracker"
[1]: <https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control#ch01-getting-started> "About Version Control"
[2]: <https://git-scm.com/docs/git-config> "Get and set repository or global options"
[3]: <https://git-scm.com/docs/git-config#Documentation/git-config.txt-alias> "Command aliases for the git command wrapper"
[4]: <https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work> "Signing Your Work"
[5]: <https://www.outcoldman.com/en/archive/2015/09/17/keep-sensitive-data-encrypted-in-dotfiles/> "Keep sensitive data encrypted in dotfiles"
[6]: <https://deepsource.io/blog/managing-different-git-profiles/> "Managing multiple Git profiles"
[7]: <https://dev.to/olistik/set-commit-signing-per-git-repository-9m9> "Set commit signing per git repository"
