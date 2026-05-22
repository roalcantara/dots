# config/zsh — Zsh autoload functions

Help conventions, command reference, and worked examples for Zsh autoload functions
under `config/zsh/etc/functions/`.

## Zsh-only vs migrated

Some functions belong exclusively on `$fpath`; others have moved to `config/bin/`.
See [config/bin/README.md](../bin/README.md) for the PATH helpers.

| Status        | Examples           | Notes                                          |
| ------------- | ------------------ | ---------------------------------------------- |
| **Zsh-only**  | `gen`, `gitx`, `psc`, `osx` | Autoloaded from `$fpath`; never migrate to bin |
| **Migrated**  | `puts` → `xc-puts`, `toast` → `xc-toast` | Live in `config/bin/`; fpath copies deleted    |

**`gen`** stays on `$fpath` forever — it generates completions from external
commands and is not a candidate for `config/bin`.

## Help conventions

Every function uses docopt-shaped **`##?`** headers. Help is printed via **`show_usage`**
or `command xc-usage <name>`. The convention is the same as `config/bin` scripts.

### Canonical `##?` template

```text
##? <tool> - One-line summary
##?
##? Usage:
##?   <tool> [options] <args...>
##?   <tool> -h | --help
##?
##? Arguments:
##?   <name>    Description
##?
##? Options:
##?   -h, --help    Show this screen
##?
##? Examples:
##?   <tool> -h
```

See also: [assets/specs/xc-usage/design.md §4.2](../../assets/specs/xc-usage/design.md#42-end-to-end-example-xc-foo) for a complete end-to-end example.

## Three-layer help model

| Layer           | Mechanism                     | When                              |
| --------------- | ----------------------------- | --------------------------------- |
| Script help     | `##?` + `xc-usage`/`show_usage`| `xc-fabric -h`, `gitx -h`, always |
| CLI parsing     | `zparseopts` in the function  | real flags and positionals        |
| Mise tasks      | `usage = '''…'''` in mise.toml| `mise run tool:specs --scenario` |

**Rule:** never require `mise` to be installed for `show_usage` or `xc-usage` to work.

## Command reference

See [assets/specs/xc-usage/design.md §4.1](../../assets/specs/xc-usage/design.md#41-invocation-table) for the full `xc-usage` command table.

## Standalone `xc-usage`

`xc-usage` is a self-contained zsh script at `config/bin/xc-usage`. It does **not** invoke mise, parse KDL, or read `#USAGE` headers. The only dependency is `zsh`, `grep`, `sed`, and the executable bit on `config/bin/xc-usage`.

Symlink to `~/.local/bin/xc-usage` so it is on `$PATH`:
```sh
ln -sf ~/.config/bin/xc-usage ~/.local/bin/xc-usage
```

## `show_usage`

`show_usage` is the Zsh-facing entrypoint. It resolves a function name to its source
file and delegates to `command xc-usage <target>` (target-first API — no `print`
subcommand).

**Usage:**
```zsh
show_usage              # uses funcstack[2] for the calling function
show_usage gen          # prints help for the `gen` function
show_usage /path/file   # prints help for any readable file
```

After `zparseopts` in a function:
```zsh
if (( ${+opts[-h]} )) || (( ${+opts[--help]} )); then
  show_usage
  return 0
fi
```

**Or use `xc-usage` directly:**
```zsh
if [[ -n $help ]]; then
  command xc-usage gen
  return $?
fi
```

**Bin scripts:** use `case -h|--help` + `command xc-usage "${0:a}"` (see
`config/bin/README.md`).

## Out of scope

- Auto-parsing `##?` to generate `zparseopts` calls (see [design.md §13](../../assets/specs/xc-usage/design.md#13-out-of-scope))
- Inferring help from code or minimal `##?`
- `config/zsh/opt/completions/*` (generated or third-party completion scripts)

## Migrated to bin

`puts` and `toast` have moved from `config/zsh/etc/functions/` to `config/bin/` as
`xc-puts` and `xc-toast`. Use `command xc-puts` or `xc-toast` directly — no autoload
needed. `gen` is **not** migrated and stays on `$fpath`.

## Authoring checklist

Before committing a function file:
1. Add a `##?` docopt header (copy the template above)
2. Wire `show_usage` or `command xc-usage` on `-h`/`--help`
3. Run `command xc-usage <function-name>` to verify help extraction
4. Run `mise run -C assets integration bin xc-usage` for integration checks
