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
| `xc-usage` | The helper that reads `##?` docopt-shaped help from `config/bin` tools. |
| Mise task | A task declared in `mise.toml` and run with `mise run <task>`. |
| Acceptance gate | A command or checklist item that must pass before work moves to the next task. |
