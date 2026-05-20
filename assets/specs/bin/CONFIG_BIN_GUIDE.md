<!-- markdownlint-disable-file -->

# Dots config/bin guide

This guide captures practical conventions used by `config/bin`. It is not a
general shell guide, a shell architecture manifesto, or a repo-wide shell
cleanup plan.

## Scope

Use this guide when changing or specifying `config/bin` tools, especially
`xc`, `xc-usage`, and `xc-*` scripts. Keep changes local to the command under
test unless a spec explicitly expands the boundary.

## Script conventions

`config/bin` scripts are user-facing shell tools. Treat their command-line
contract, help text, exit code, stdout, and stderr as behavior.

- Use `zsh` for `config/bin` tools.
- Keep public help in `##?` docopt-shaped comments.
- Use `xc-usage` for help extraction when a tool supports it.
- Keep commands executable from a non-interactive shell with explicit
  arguments.
- Do not source personal shell startup files.
- Prefer explicit environment variables in tests and features, such as
  `XC_BIN_DIR` or `FABRIC_PATTERNS_DIR`, instead of depending on a personal
  `PATH`.
- Check optional dependencies near the command boundary and print a clear error
  before exiting non-zero.
- Keep read-only listing output deterministic. Prefer raw output modes for
  executable specs when a command supports them.

## Help conventions

Use `##?` comments as the public help source. A command that supports
`xc-usage` must keep its `Usage`, `Options`, `Environment`, `Subcommands`, and
`Examples` sections accurate enough for both humans and specs.

The help text is behavior. If a command changes flags, subcommands, or
environment variables, update both the `##?` block and the relevant specs.

## Verification

Use the focused gate for the changed tool:

```sh
mise run xc:specs
mise run xc-fabric:specs --scenario ls_raw
mise run xc-usage:specs
```

When zsh files change, also run:

```sh
mise exec -- shellcheck <changed-zsh-scripts>
zsh -n <changed-zsh-scripts>
git diff --check
```

## Non-goals

Do not use this guide to introduce a shell framework, enforce Functional Core,
Imperative Shell, or clean up unrelated shell files. The bins pilot exists to
make `config/bin` behavior executable and understandable before larger Dots
areas are touched.
