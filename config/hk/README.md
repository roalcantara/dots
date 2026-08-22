# hk Configuration

User-level configuration for [hk](https://hk.jdx.dev), the Rust-native git hook
manager, plus the shared [cocogitto](https://docs.cocogitto.io) commit policy.

## Files

- `config.pkl` - global hk config. hk **merges** it into every project's
  `hk.pkl`, so every repository inherits the commit-message rules with no
  per-repo configuration.
- `../cog/cog.toml` - the allowed Conventional Commits type set.

Both are surfaced through directory symlinks created by `mise run setup:hooks`:

```
~/.config/hk  -> ~/.local/share/dots/config/hk
~/.config/cog -> ~/.local/share/dots/config/cog
```

Because `~/.local/share/dots` points at the working copy, editing these files
changes the live configuration immediately - there is nothing to re-install.

## Installing hooks in a repository

```sh
mise run setup:hooks                        # in dots
hk install --mise --legacy --force-local    # in any other repo
```

`--legacy` is **required**. Without it hk writes config-based hooks
(`hook.<name>.command`), which git older than 2.54 - including Apple's
`/usr/bin/git` - ignores silently, so commits go unvalidated with no warning.
`--mise` makes hooks resolve hk through `mise x`, so mise need not be activated
in the shell that runs git.

## Per-repo customization

A repo customizes inherited rules from its own `hk.pkl`. The merge is
**per-property**, so an override only names what it changes.

| Intent | How |
| --- | --- |
| Add a rule | Declare a new step under `["commit-msg"]` |
| Override a rule | Redeclare the step **by the same name**, setting only what changes |
| Disable a rule | Redeclare by name with `step_condition = "false"` |
| Disable conditionally | Redeclare by name with `profiles = List("some-profile")` |

```pkl
// Relax the subject limit in one repository
hooks {
  ["commit-msg"] {
    steps {
      ["commit-style"] { step_condition = "false" }
    }
  }
}
```

For commit **types**, drop a `cog.toml` in the repo root - it takes precedence
over the shared one, so a repo can add types without losing the baseline.

## Self-contained repos

Repos shared with people who do not use these dotfiles should copy the two
`commit-msg` steps from `config.pkl` into their own `hk.pkl` and commit their own
`cog.toml`. The step definitions are identical in both modes; only their location
differs.

## Editing `config.pkl`

Three mechanics are load-bearing:

1. **`#"""..."""#` raw strings.** Plain `"""..."""` makes Pkl read `\(` as string
   interpolation, which is invalid. hk's embedded evaluator (`pklr`) tolerates
   it; the `pkl` CLI and `pkl-lsp` do not.
2. **`{% raw %}` / `{% endraw %}`.** hk renders commands through Tera, where
   shell's `${#var}` parses as the `{#` comment opener. hk's own `{{...}}`
   variables go outside the raw block.
3. **`{{ commit_msg_file | default(value=files) }}`.** Resolves to the message
   file under the hook and to the fixture under `hk test`, so one definition is
   both correct and testable.

Always run both after editing:

```sh
pkl eval config/hk/config.pkl   # must render the config, not an error
hk test --cd config/hk          # must be all `ok`
```

## Commands and environment

- `hk check` / `hk fix` - lint, with or without applying fixes
- `hk test` - run the step tests defined in the config
- `hk validate` - validate the config
- `HK=0 git commit ...` - bypass all hooks
- `HK_SKIP_STEPS=shfmt git commit ...` - skip one step
- `HK_SKIP_HOOK=pre-commit git commit ...` - skip one hook

The full list is at <https://hk.jdx.dev/environment_variables.html>.
