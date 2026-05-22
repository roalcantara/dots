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
~/.config/bin/xc-git                    ← unified git helpers (flat executable, like xc-fabric)
~/.local/bin/xc-git                     ← symlink → ~/.config/bin/xc-git
~/.config/bin/xc-fabric               ← interactive Fabric pattern runner
```

## DEPENDENCIES

- [Git][5]
- [FZF][6]
- [Gum][7]
- [Delta][8]
- [Fabric][20] _(required for `xc-fabric`)_
- [fzf][21] _(optional rich pattern picker for `xc-fabric`)_
- [Gum][22] _(optional prompts, logs, tables, and spinners for `xc-fabric`)_
- [Glow][23] _(optional Markdown renderer for `xc-fabric`)_
- [bat][24] _(optional `xc-fabric` rendering fallback)_

**`xc-fabric` picker:** When `fzf` is installed (**0.27+** for `preview-bg` / `header-bg` in COLSPEC; tested on **0.71**), the default pattern UI uses `--layout=default`, rounded borders, and a darker preview panel. Override Markdown preview styling with `GLOW_STYLE` (see `_boot_preview_cmd` in the script; default theme for that path is `dracula`). Result rendering after a run uses `glow -s "${GLOW_STYLE:-dark}"`.

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
xc-git
xc-git-stash-preview
xc-fzf-file-preview
```

### xc-git

Git workflow helpers are unified under a single CLI: **`xc-git`**

| Subcommand       | Purpose                           | Example                                  |
| ---------------- | --------------------------------- | ---------------------------------------- |
| `branch-preview` | fzf branch preview (gum + delta)  | `xc-git branch-preview main`             |
| `fixup-suggest`  | Safe fixup target or `git commit` | `xc-git fixup-suggest --dry-run -- path` |
| `log-fzf`        | Interactive log + gitx keys       | `xc-git log-fzf fix`                     |

```sh
xc-git -h
xc-git fixup-suggest --dry-run .
git add file && git fix "$(xc-git fixup-suggest -q -- file)"
git lol                # → gitx → xc-git log-fzf
```

`xc-git` lives at `config/bin/xc-git` (single flat executable, subcommands inline). Old package dir `xc-git/`, wrappers, and `lib/xc-git/` are removed.

**Dependencies:** `git` · `delta` (for `branch-preview` diff) · `gum` optional (section headings; plain `printf` fallback).

**Testing:**
```sh
mise run xc-git:specs
```

### Portable tool symlinks

```sh
ln -sf ~/.config/bin/xc-git  ~/.local/bin/xc-git
ln -sf ~/.config/bin/xc-puts        ~/.local/bin/xc-puts
ln -sf ~/.config/bin/xc-toast       ~/.local/bin/xc-toast
ln -sf ~/.config/bin/xc-usage       ~/.local/bin/xc-usage
```

**Removed:** `config/zsh/etc/functions/{puts,toast}`, `config/bin/{lib/xc-git,xc-git-*}` wrappers, root `config/bin/xc-git` file.

### xc (launcher)

**`xc`** is the interactive entry point for all other `xc-*` tools (each tool stays its own file).

```bash
xc              # fzf menu + stacked help preview (xc-usage preview)
xc list         # table of discovered tools
ln -sf ~/.config/bin/xc ~/.local/bin/xc
```

Discovery scans `~/.config/bin` for executable `xc-*` files (flat layout; skips `xc` itself). Requires **fzf** (or **gum** as fallback) for the interactive picker.

### xc-usage

All `config/bin` scripts use **`xc-usage`** to print help from `##?` docopt headers.
Legacy `#?` (single-hash) headers are no longer used for help extraction.

**Target-first API** — `xc-usage` resolves any `<target>` to its source file and
prints the `##?` block:

```bash
xc-usage gen           # Zsh function on $fpath → ##? from source file
xc-usage xc-git        # bin script on $PATH → ##? from config/bin/xc-git
xc-usage ./my-script   # explicit file path
```

Optional modifiers:

| Flag                      | Purpose                                               |
| ------------------------- | ----------------------------------------------------- |
| `--md`                    | Pipe help through `xc-md` (glow → bat → plain)        |
| `--scope main\|sub:NAME`  | Scoped docopt block in multi-section dispatchers only |
| `--preview [--tool NAME]` | Stacked help for `xc` launcher fzf preview            |
| `--list-subs`             | Subcommand names from `##? Subcommands:`              |
| `--no-help-footer`        | Suppress auto `-h` footer in scoped output            |

Scoped flags (`--scope`, `--preview`, `--list-subs`) are **dispatcher helpers only**
and do not apply to flat tools.

**Three-layer help model:**

| Layer       | Mechanism                      | When                             |
| ----------- | ------------------------------ | -------------------------------- |
| Script help | `##?` + `xc-usage`             | `xc-fabric -h`, always           |
| CLI parsing | `zparseopts` in the script     | real flags and positionals       |
| Mise tasks  | `usage = '''…'''` in mise.toml | `mise run tool:specs --scenario` |

**Mise `usage` field** applies only to `mise run` tasks — never to `xc-usage`. `xc-usage` is a standalone zsh script; it does not invoke mise, parse KDL, or read `#USAGE` headers.

**Dual header convention (`#?` + `##?`):**

| Prefix | Purpose                      |
| ------ | ---------------------------- |
| `#?`   | License, version, docopt URL |
| `##?`  | Docopt help                  |

Use `xc-usage --metadata <file>` to print only `#?` license/metadata lines. Files with only `#?` (no `##?`) are rejected with a docopt hint.

For Zsh function conventions, see [config/zsh/README.md](../zsh/README.md).

### xc-md

`xc-md` renders markdown from stdin with graceful fallback: **glow → bat → plain**.
Exit **0** on success; no stderr warnings when a renderer is absent.

```bash
xc-usage gen --md         # rendered help via xc-md
xc-usage gen | xc-md      # equivalent composition
echo '# Title' | xc-md    # standalone stdin → rendered output
```

| Tier | Condition            | Action                                      |
| ---- | -------------------- | ------------------------------------------- |
| 1    | `command -v glow`    | `glow` (stdin → stdout)                     |
| 2    | else `command -v bat` | `bat -l md --paging=never` (stdin → stdout) |
| 3    | else                 | `cat` (passthrough)                         |

**Symlink:** `ln -sf ~/.config/bin/xc-md ~/.local/bin/xc-md`

### CONVENTIONS

Each script follows the same structure:

```zsh
#!/usr/bin/env zsh

**Canonical dispatcher shape:** see `xc-fabric` `##?` (main block + sub blocks) and
`assets/specs/xc-usage/design.md` §11.5 ([docopt](http://docopt.org/)).

**Flat tool** (`xc-puts`, `xc-toast`, `xc-md`):

```text
##? xc-<name> - One-line description
##?
##? Usage:
##?   xc-<name> <arg>
##?   xc-<name> -h | --help
##?
##? Arguments:
##?   arg    What it is
##?
##? Examples:
##?   fzf --preview 'xc-<name> {}' | xargs meld

case "${1:-}" in
  -h|--help) command xc-usage "${0:a}"; exit $? ;;
esac

# implementation
```

For a complete worked example see [assets/specs/xc-usage/design.md §4.2](../../assets/specs/xc-usage/design.md#42-end-to-end-example-xc-foo).

#### RULES

- Shebang is always `#!/usr/bin/env zsh`
- Help lives in the `##?` header — no separate man page, no duplicated strings
- `-h`/`--help` handled with `case -h|--help` + `command xc-usage "${0:a}"` at the top of the script
- For missing required args use `command xc-usage "${0:a}" >&2`
- Scripts are self-contained — no sourcing of `~/.zshrc` or personal config
- All dependencies (`gum`, `delta`, `bat`, `fzf`, `xc-usage`, etc.) are assumed to be on `$PATH`

### ADDING SCRIPTS

```zsh
touch ~/.config/bin/xc-<name>
chmod +x ~/.config/bin/xc-<name>
ln -s ~/.config/bin/xc-<name> ~/.local/bin/xc-<name>
```

### HELP

```zsh
xc-<name> --help
# or (target-first API):
xc-usage xc-<name>
# with markdown rendering:
xc-usage xc-<name> --md
```

### TESTING (BUN + MISE)

- Some scripts here have automated checks driven by [mise][9] and [Bun][10].
- Specs live under [`tests/<script-name>.spec.ts`](tests/)
  - For example: [`tests/xc-git.spec.ts`](tests/xc-git.spec.ts)
- The mise task [`xc-git:specs`](mise.toml) sets:
  - `dir` to `{{ config_root }}` which is the directory that contains this `mise.toml`
    - For example: `config/bin` inside the dotfiles repo
  - `XC_GIT` to the absolute path of the script under test
- Then runs **`bunx bun test`** on the spec file

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
    - Example: `mise run xc-git:specs --scenario help` runs only the `help` suite

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

  # xc-git
  mise run xc-git:specs
  mise run xc-git:specs --scenario help
  mise run xc-git:specs --scenario fixup_suggest

  # xc-puts
  mise run xc-puts:specs
  mise run xc-puts:specs --scenario help

  # xc-toast
  mise run xc-toast:specs
  mise run xc-toast:specs --scenario help

  # xc-usage
  mise run xc-usage:specs
  mise run xc-usage:specs --scenario metadata

  # xc-fabric
  mise run setup
  mise run xc-fabric:specs
  mise run xc-fabric:specs --scenario help
  mise run xc-fabric:specs --scenario missing_fabric
  mise run xc-fabric:specs --scenario ls_raw
  mise run xc-fabric:specs --scenario ls_table
  mise run xc-fabric:specs --scenario run_raw
  mise run xc-fabric:specs --scenario run_youtube_url
  mise run xc-fabric:specs --scenario run_youtube_pattern
  mise run xc-fabric:specs --scenario run_copy
  mise run xc-fabric:specs --scenario run_output
  mise run xc-fabric:specs --scenario run_variable
  mise run xc-fabric:specs --scenario yt_flags
  mise run xc-fabric:specs --scenario render_fallback
  mise run xc-fabric:specs --scenario clip_macos
  mise run xc-fabric:specs --scenario clip_linux
  mise run xc-fabric:specs --scenario update
  mise run xc-fabric:specs --scenario show
  mise run xc-fabric:specs --scenario strategies
  mise run xc-fabric:specs --scenario strategy_passthrough
  mise run xc-fabric:specs --scenario scrape_url
  mise run xc-fabric:specs --scenario picker_fzf_preferred
  mise run xc-fabric:specs --scenario picker_fzf_stdin_lines
  mise run xc-fabric:specs --scenario picker_gum_fallback
  ```

##### WITHOUT MISE

1. Ensure Bun is on `PATH`
2. Run `cd config/bin` from the root of this repo.
3. Run the specs:

  ```sh
  # xc-git
  bunx bun test tests/xc-git.spec.ts

  # xc-fabric
  bunx bun test tests/xc-fabric.spec.ts
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
[20]: https://github.com/danielmiessler/Fabric "Fabric"
[21]: https://github.com/junegunn/fzf "fzf"
[22]: https://github.com/charmbracelet/gum "Gum"
[23]: https://github.com/charmbracelet/glow "Glow"
[24]: https://github.com/sharkdp/bat "bat"
