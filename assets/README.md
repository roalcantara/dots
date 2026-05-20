# Dots assets

This directory groups documentation and verification for the dotfiles project.
It is not an application package.

| Folder                      | Purpose                                    |
| --------------------------- | ------------------------------------------ |
| [guides](guides/)           | Canonical best practices and glossary      |
| [specs](specs/)             | SDD planning — requirements, design, tasks |
| [features](features/)       | BDD living documentation (Gherkin)         |
| [integration](integration/) | Subprocess and script verification         |

## Verification toolchain

Dependencies live in [`mise.toml`](mise.toml) and/or [`package.json`](package.json).
Run verification through mise from the repository root:

```bash
mise run -C assets test all    # all verification
mise run -C assets test bin    # bin domain only
```

Implementation code stays in `config/`. Neovim busted specs stay in
`config/nvim/specs/`.

## Agents

New features start in `assets/specs/<feature-slug>/`. Planning and implementation
rules are in the root [README.md](../README.md#agent-workflow).
