# ~/.config/bin

Personal executable scripts is part of my [dotfiles][0].

Utilities, git helpers, fzf integrations, and whatever else doesn't belong in a
plugin or a shell function.

## OVERVIEW

Shell functions defined in `~/.zshrc` or autoloaded via ZIM/ZSH are great for
interactive workflows, but they are invisible to subshells. Tools like `fzf --preview`,
`xargs`, and `env -i` spawn non-interactive shells that don't source your config — so
functions simply don't exist there.

Scripts in `$PATH` solve that. They are executables, not functions, so any process can
invoke them regardless of how the shell was started.

`~/.config/bin` is the source of truth. A symlink from `~/.local/bin` puts everything
on `$PATH` without duplicating files.

```txt
~/.config/bin/xc-git-branch-preview   ← source (versioned with dotfiles)
~/.local/bin/xc-git-branch-preview    ← symlink → ~/.config/bin/xc-git-branch-preview
```

## DEPENDENCIES

- [Git][5]
- [FZF][6]
- [Gum][7]
- [Delta][8]

## DEVELOPMENT

### NAMING

Every script here is prefixed with `xc-`.

```txt
xc-<topic>-<action>
```

The prefix makes origin obvious at a glance — in a listing, in a `$PATH` search, in
shell history. It also prevents collisions with system tools, package managers, and
third-party CLIs.

#### EXAMPLES

```txt
xc-git-branch-preview
xc-git-stash-preview
xc-fzf-file-preview
```

### CONVENTIONS

Each script follows the same structure:

```zsh
#!/usr/bin/env zsh

#? xc-<name> - One-line description
#?
#? Usage:
#?   xc-<name> <arg>
#?   xc-<name> -h | --help
#?
#? Arguments:
#?   arg    What it is
#?
#? Examples:
#?   fzf --preview 'xc-<name> {}' | xargs <command>

arg="${1}"

case "${arg}" in
  -h|--help) grep '^#?' "${0}" | sed 's/^#? \{0,1\}//'; exit 0 ;;
  '')        grep '^#?' "${0}" | sed 's/^#? \{0,1\}//'; exit 1 ;;
esac

# implementation
```

#### RULES

- Shebang is always `#!/usr/bin/env zsh`
- Help lives in the `#?` header — no separate man page, no duplicated strings
- `-h`/`--help` and missing args both print the header and exit cleanly
- Scripts are self-contained — no sourcing of `~/.zshrc` or personal config
- All dependencies (`gum`, `delta`, `bat`, `fzf`, etc.) are assumed to be on `$PATH`

### ADDING SCRIPTS

```zsh
touch ~/.config/bin/xc-<name>
chmod +x ~/.config/bin/xc-<name>
ln -s ~/.config/bin/xc-<name> ~/.local/bin/xc-<name>
```

### HELP

```zsh
xc-<name> --help
# or
grep '^#?' ~/.config/bin/xc-<name> | sed 's/^#? \{0,1\}//'
```

## ACKNOWLEDGEMENTS

- [Standard Readme][4]

## CONTRIBUTING

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][3] rules.
- All contributors across code, issues, chat, and mailing lists must follow the [Contributor Covenant][2].

## LICENSE

The project is available as open source under the terms of the [MIT][1] [License](LICENSE)

[0]: https://github.com/roalcantara/dots 'An opinionated DotFiles'
[1]: https://opensource.org/licenses/MIT 'Open Source Initiative'
[2]: https://contributor-covenant.org 'A Code of Conduct for Open Source Communities'
[3]: https://editorconfig.org 'EditorConfig'
[4]: https://github.com/RichardLitt/standard-readme 'Standard Readme'
[5]: https://git-scm.com 'Distributed version control system'
[6]: https://github.com/junegunn/fzf 'FZF'
[7]: https://github.com/charmbracelet/gum 'Gum'
[8]: https://github.com/dandavison/delta 'Delta'
