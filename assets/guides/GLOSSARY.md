<!-- markdownlint-disable-file -->

# Dots glossary

This glossary defines terms used by Dots specs, guides, and living
documentation. Add terms only when a spec needs shared language.

## Terms

| Term | Definition |
| --- | --- |
| Dots | This dotfiles repository. |
| Guide | Shared project guidance under `assets/guides/`. |
| Spec | A feature specification under `assets/specs/<slug>/`. |
| Living documentation | Executable documentation written as Gherkin and verified by Cucumber. |
| Feature file | A `.feature` file under `assets/features/<domain>/`. |
| Scenario | One concrete behavior example in a feature file. |
| Step definition | TypeScript code that maps Gherkin steps to executable checks. |
| Screenplay | A BDD pattern where actors perform activities and ask questions about observable outcomes. |
| Actor | A named user in a Screenplay scenario, such as `Alice`. |
| Interaction | Screenplay code that performs low-level work, such as running a command. |
| Question | Screenplay code that reads observable state, such as stdout or exit code. |
| Integration spec | A Bun subprocess spec under `assets/integration/<domain>/` that verifies script exit codes and output. |
| `config/bin` | The Dots directory containing portable `xc-*` command-line tools. |
| `xc-*` tool | A command in `config/bin` with the `xc-` prefix. |
| `xc` launcher | The entry point that discovers and runs other `xc-*` tools. |
| `xc-usage` | The helper that reads `##?` docopt-shaped help from any resolvable target (bin scripts on `$PATH`, Zsh functions on `$fpath`, or explicit file paths). Supports target-first API, `--md` rendering, and scoped flags for dispatchers. |
| `xc-md` | A composable markdown renderer (`glow` → `bat` → plain `cat`) that reads from stdin. Used by `xc-usage --md` or standalone: `echo '# Title' \| xc-md`. |
| `gen` | A Zsh autoload function on `$fpath` that generates shell completions from external commands. Stays on `$fpath` forever; no `xc-gen` exists. |
| `show_usage` | The Zsh-facing entrypoint that resolves a function name to its source file and delegates to `command xc-usage <target>`. Prefer `show_usage` inside autoload functions, `xc-usage` in bin scripts. |
| Mise task | A task declared in `mise.toml` and run with `mise run <task>`. |
| Acceptance gate | A command or checklist item that must pass before work moves to the next task. |

### Bin ↔ Zsh architecture

`config/bin/xc-*` tools are small, composable helpers called by Zsh autoload
functions. `xc-usage` (target-first API) extracts `##?` docopt help from any
source; `xc-md` renders markdown with graceful fallback. Zsh-only functions like
`gen` and `gitx` stay on `$fpath` and delegate help to `show_usage` or
`command xc-usage <name>`. For detail see [config/bin/README.md](../../config/bin/README.md)
and [config/zsh/README.md](../../config/zsh/README.md).
