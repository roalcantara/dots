---
name: dots-context
description: Load at the start of ANY Dots task — dotfiles layout, config/bin and Zsh architecture, assets verification, SDD paths, mise tasks, and guide routing. Without it you risk wrong paths, inline help instead of xc-usage, or specs under docs/superpowers/.
---

# Dots — project context

## When to load

At the start of **any** Dots task: shell helpers, Zsh, Docker, mise, BDD,
integration specs, guides, or CI.

## Skill locations

- **Owned skills** (`dots-context`, `dots-testing`, `dots-quality-gate`):
  `.agents/skills/<skill-id>/SKILL.md` in this repository.
- **Project skills** (Skills CLI): same folder, restored from `skills-lock.json`.
- **Global companions**: `$HOME/.agents/skills/<skill-id>` when listed as
  `location: global` in [`assets/guides/SKILLS.yml`](../../assets/guides/SKILLS.yml).
- **Ledger**: [`assets/guides/SKILLS.md`](../../assets/guides/SKILLS.md) and
  [`assets/guides/SKILLS.yml`](../../assets/guides/SKILLS.yml) — validated by
  `mise run -C assets skill validate`.
- **Domain routing**: [`.cursor/dots-skill-routing.md`](../../.cursor/dots-skill-routing.md).

## Stack

| Layer          | Role                                                            |
| -------------- | --------------------------------------------------------------- |
| **Bash/Zsh**   | User shell; `config/bin` on PATH, functions on `$fpath`         |
| **mise**       | Tool versions and tasks (root + `assets/mise.toml`)             |
| **mise bootstrap** | Machine setup in `config/mise/conf.d/`, entered through `install` |
| **Docker**     | Dev images under `distros/`; `mise run build`                   |
| **Bun**        | Test runner for `assets/integration/` and Cucumber support only |
| **Neovim/Lua** | `config/nvim/`                                                  |
| **SOPS**       | Encrypted secrets per `.sops.yaml`                              |
| **hk**         | Git hooks (see `assets/specs/update-hooks/`)                    |

Authoritative prose: [`AGENTS.md`](../../AGENTS.md) at repo root.

## Directory layout

```
config/bin/          xc-* helpers (composable; not the primary user API)
config/zsh/          Zsh functions, completions, themes
assets/guides/       Human guides (read GLOSSARY first)
assets/specs/        SDD: requirements, design, tasks per feature
assets/features/     Gherkin living documentation
assets/integration/  Bun subprocess specs
distros/             Dockerfiles (debian, ubuntu)
install              Bootstrap script
mise.toml            Docker, setup, CI tasks
assets/mise.toml     bdd, integration, test, skill tasks
```

## Bin ↔ Zsh help model

- User-facing commands stay on `$fpath` (e.g. `gen`, `gitx`).
- `config/bin/xc-*` are composable helpers called by Zsh functions.
- Help: `##?` header + `command xc-usage <name>` or `show_usage`.
- `xc-usage --md` pipes through `xc-md` (glow → bat → cat).

See [`config/bin/README.md`](../../config/bin/README.md).

## Feature specs

- **Canonical root:** `assets/specs/<feature-slug>/`
- **Superpowers redirect:** map `docs/superpowers/` to `assets/specs/`
- **Subagents:** include paths and mise gates explicitly

## Optional companions

<!-- skills:optional-companions:start -->
| Skill | When |
| --- | --- |
| **bun-development** | Implementing or testing Bun TypeScript under assets/. |
| **bun-runtime** | Bun runtime, package manager, or test-runner behavior under assets/. |
| **systematic-debugging** | Investigating failing tests, gate failures, regressions, or unexpected behavior. |
| **mise-expert** | Editing mise tool versions or environment setup. |
| **mise-tasks** | Editing mise.toml, task dependencies, or multi-step project workflows. |
| **bash-scripting** | Editing config/bin, install scripts, or shell-heavy hooks. |
| **bash-linux** | Bash/Linux terminal patterns during shell work. |
| **configuring-zsh** | Editing config/zsh, plugins, completions, or shell startup. |
| **github-actions-docs** | Editing GitHub Actions workflows or CI configuration. |
| **docker-expert** | Docker, Dockerfile, distros/, or container build work. |
| **docker-patterns** | Docker Compose, security, or orchestration patterns. |
| **bdd-gherkin-specification** | Writing Gherkin feature files or acceptance specifications. |
| **bdd-patterns** | BDD pattern questions during assets/features work. |
| **bdd-principles** | BDD concept or philosophy questions. |
| **bdd-scenarios** | Designing Gherkin scenarios or edge cases. |
| **cucumber-gherkin** | Cucumber or Gherkin syntax for assets/features. |
| **spec-driven-development** | Planning SDD artifacts under assets/specs/; load with using-superpowers. |
| **using-superpowers** | Starting work; pair with spec-driven-development for assets/specs/ SDD. |
| **writing-plans** | Multi-step implementation planning before coding. |
| **receiving-code-review** | Applying review feedback, especially when feedback is ambiguous or broad. |
| **requesting-code-review** | Preparing a review handoff, PR, or larger completed change for scrutiny. |
| **docs-writer** | Writing or reviewing guides and specs under assets/. |
| **ast-grep** | Authoring or debugging structural search and rewrite rules. |
| **verification-before-completion** | Final reminder only; dots-quality-gate is the executable authority. |
| **neovim-best-practices** | Editing config/nvim, LSP, plugins, or keymaps. |
| **lua** | Lua under config/nvim or Busted test work. |
<!-- skills:optional-companions:end -->

## Related guides

| Topic         | Guide                                                                    |
| ------------- | ------------------------------------------------------------------------ |
| Terminology   | [`assets/guides/GLOSSARY.md`](../../assets/guides/GLOSSARY.md)           |
| Skills policy | [`assets/guides/SKILLS.md`](../../assets/guides/SKILLS.md)               |
| Mise tasks    | [`assets/guides/MISE_GUIDE.md`](../../assets/guides/MISE_GUIDE.md)       |
| Testing       | [`assets/guides/TESTING_GUIDE.md`](../../assets/guides/TESTING_GUIDE.md) |
| BDD           | [`assets/guides/BDD_GUIDE.md`](../../assets/guides/BDD_GUIDE.md)         |
| Docker        | [`assets/guides/DOCKER_GUIDE.md`](../../assets/guides/DOCKER_GUIDE.md)   |
| CI            | [`assets/guides/CI_GUIDE.md`](../../assets/guides/CI_GUIDE.md)           |
