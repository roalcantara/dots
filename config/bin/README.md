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

### TESTING (BUN + MISE)

- Some scripts here have automated checks driven by [mise][9] and [Bun][10].
- Specs live under [`tests/<script-name>.spec.ts`](tests/)
  - For example: [`tests/xc-git-log-fzf.spec.ts`](tests/xc-git-log-fzf.spec.ts)
- The mise task [`xc-git-log-fzf:specs`](mise.toml) sets:
  - `dir` to `{{ config_root }}` which is the directory that contains this `mise.toml`
    - For example: `config/bin` inside the dotfiles repo
    - Not the monorepo root unless your layout differs
  - `XC_GIT_LOG_FZF` to the absolute path of the script under test
- Then runs **`bunx bun test`** on the spec file
  - So the same command shape works whether Bun is on `PATH` via mise or via a global install
  - For example: `bunx bun test tests/xc-git-log-fzf.spec.ts`

#### GLOSSARY

- **`tests/*.spec.ts`** _(test files)_:
  - Bun discovers tests by filename ([test runner][11]).
  - Keeping `*.spec.ts` next to `mise.toml` avoids temp-file naming issues from inline-only tasks.

- **`bunx bun test …`** _(running specs)_:
  - [bunx][15] runs a package binary from the registry cache.
  - `bunx bun test <file>` invokes the `bun` CLI’s test runner on the given spec file.

- **`config_root`** _(mise template)_:
  - Mise template: the directory that contains this `mise.toml` ([templates][12]).
  - The task uses `dir = "{{ config_root }}"` and `env` so:
    - `bun test` runs with the correct cwd
    - `XC_GIT_LOG_FZF` points to the script under test

- **`usage` / `usage_*`** _(mise task arguments)_:
  - CLI flags from the task `usage` block are exposed as environment variables
  - e.g. `usage_scenario` is set to the value of `--scenario`
  - See [task arguments][13]

- **`--scenario` + `choices`** _(mise task arguments)_:
  - Optional filter: omit the flag to run **all** suites; with `--scenario`, only the matching suite runs and the rest are skipped
  - Valid values:
    - Are defined in the task `usage` block
    - Must match the scenario ids used in `describe.skipIf(skipWhenOtherScenario("…"))` in the spec file

- **`skipWhenOtherScenario(id)`** _(test file)_:
  - If `usage_scenario` is set:
    - Suites whose id does not match are skipped
    - So you can run one scenario at a time
    - Example: `mise run xc-git-log-fzf:specs --scenario help` runs only the `help` suite

#### CONVENTIONS AND PATTERNS

1. Add `tests/<name>.spec.ts`
   1. With `describe` / `it` from `bun:test`
   2. Using [Better Specs][14]-style names: `when …`, present-tense `it`

2. Add a `[tasks."<name>:specs"]` entry:
   1. `dir = "{{ config_root }}"`
   2. `env` for any absolute paths.
   3. Optional `usage` with `flag … choices …`.
   4. And `run = "bunx bun test tests/<name>.spec.ts"`

3. For subprocess checks on shell scripts:
   1. Use `Bun.spawnSync(["zsh", script, …], { env, stdout: "pipe", stderr: "pipe" })`
   2. Assert exit code and output.
   3. If `XC_GIT_LOG_FZF` is unset (running `bun test` by hand):
      1. Fall back to a path relative to `import.meta.dir`

#### RUNNING SPECS

##### WITH MISE

1. Run `cd config/bin` in this repo.
2. Run `mise trust` if prompted.
3. Run the specs:

  ```sh
  # 💡 NOTE: Invalid `--scenario` values are rejected by mise before Bun starts

  # xc-git-log-fzf
  mise run xc-git-log-fzf:specs
  mise run xc-git-log-fzf:specs --scenario help
  mise run xc-git-log-fzf:specs --scenario missing_gitx
  mise run xc-git-log-fzf:specs --help
  ```

##### WITHOUT MISE

1. Ensure Bun is on `PATH`
2. Run `cd config/bin` from the root of this repo.
3. Run the specs:

  ```sh
  # xc-git-log-fzf
  bunx bun test tests/xc-git-log-fzf.spec.ts
  ```

## REFERENCES

- [mise — TOML tasks][18] (including [shell shebang][19])
- [mise — Task arguments / usage][13]
- [mise — Templates][12]
- [Bun — bunx][15]
- [Bun — Test runner (CLI)][11]
- [Bun — Writing tests][16]
- [Bun — Shell (`$`)][17]
- [Better Specs][14]

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
[9]: https://mise.jdx.dev/ "mise-en-place"
[10]: https://bun.sh/ "Bun"
[11]: https://bun.com/docs/cli/test "Bun test runner"
[12]: https://mise.jdx.dev/templates.html#variables "mise templates"
[13]: https://mise.jdx.dev/tasks/task-arguments.html#usage-field "mise task arguments"
[14]: https://betterspecs.org/ "Better Specs"
[15]: https://bun.com/docs/cli/bunx "bunx"
[16]: https://bun.com/docs/test/writing-tests "Bun writing tests"
[17]: https://bun.com/docs/runtime/shell "Bun shell (`$`)"
[18]: https://mise.jdx.dev/tasks/toml-tasks.html "mise TOML tasks"
[19]: https://mise.jdx.dev/tasks/toml-tasks.html#shell-shebang "mise shell shebang"
