# hk Configuration

User-level configuration for [hk](https://hk.jdx.dev), the Rust-native git hook manager.

## Files

- `config.pkl` - global hk defaults (`jobs`, `terminal_progress`). hk **merges** it into every project's
  `hk.pkl`. It defines **no hooks**: each repository declares its own in its `hk.pkl`, so a repo without one
  is never blocked by rules it did not ask for.

It is surfaced through a directory symlink created by `mise run setup:hooks`:

```
~/.config/hk -> ~/.local/share/dots/config/hk
```

Because `~/.local/share/dots` points at the working copy, editing the file changes the live configuration
immediately - there is nothing to re-install.

## Installing hooks in a repository

```sh
mise run setup:hooks                        # in dots
hk install --mise --legacy --force-local    # in any other repo with an hk.pkl
```

`--legacy` is **required**. Without it hk writes config-based hooks (`hook.<name>.command`), which git older
than 2.54 - including Apple's `/usr/bin/git` - ignores silently, so hooks never run, with no warning.
`--mise` makes hooks resolve hk through `mise x`, so mise need not be activated in the shell that runs git.

## Editing Pkl hook steps

Two mechanics are load-bearing in any `hk.pkl` step that embeds shell:

1. **`#"""..."""#` raw strings.** Plain `"""..."""` makes Pkl read `\(` as string interpolation, which is
   invalid. hk's embedded evaluator (`pklr`) tolerates it; the `pkl` CLI and `pkl-lsp` do not.
2. **`{% raw %}` / `{% endraw %}`.** hk renders commands through Tera, where shell's `${#var}` parses as the
   `{#` comment opener. hk's own `{{...}}` variables go outside the raw block.

Check after editing: `pkl eval <file>` must render the config, and `hk validate` must pass.

## Commands and environment

- `hk check` / `hk fix` - lint, with or without applying fixes
- `hk validate` - validate the config
- `HK=0 git commit ...` - bypass all hooks
- `HK_SKIP_STEPS=shfmt git commit ...` - skip one step
- `HK_SKIP_HOOK=pre-commit git commit ...` - skip one hook

The full list is at <https://hk.jdx.dev/environment_variables.html>.
