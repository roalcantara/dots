# Dots — agent instructions

Dots is a cross-platform dotfiles repository: shell helpers in `config/bin`,
Zsh functions in `config/zsh`, verification in `assets/`, Docker images in
`distros/`, and mise tasks at the repo root and under `assets/mise.toml`.

## Start here

1. Read [`assets/guides/GLOSSARY.md`](assets/guides/GLOSSARY.md) for terminology.
2. Load [`.agents/skills/dots-context/SKILL.md`](.agents/skills/dots-context/SKILL.md) for every task.
3. Follow [`assets/guides/SKILLS.md`](assets/guides/SKILLS.md) for skill routing.

## Specs and guides

- SDD artifacts: `assets/specs/<feature-slug>/` (`requirements.md`, `design.md`, `tasks.md`)
- Guides: `assets/guides/`
- Do **not** write to `docs/superpowers/` — redirect to `assets/specs/`

## Skill registry

[`assets/guides/SKILLS.yml`](assets/guides/SKILLS.yml) drives validation and sync:

```bash
mise run -C assets skill validate
mise run -C assets skill sync
mise run -C assets skill install
```

Domain routing table: [`.cursor/dots-skill-routing.md`](.cursor/dots-skill-routing.md)

## Optional companion skills

<!-- skills:optional-companions:start -->
- `bun-development` — for Bun TypeScript under assets/integration or assets/features
- `bun-runtime` — for Bun runtime or package-manager questions under assets/
- `systematic-debugging` — before fixing failing tests, gate failures, or unexpected behavior
- `mise-expert` — when editing mise tool versions or environment setup
- `mise-tasks` — when editing mise.toml or task orchestration
- `bash-scripting` — when editing config/bin, install scripts, or shell hooks
- `bash-linux` — for bash terminal patterns on macOS or Linux
- `configuring-zsh` — when editing config/zsh or zsh startup behavior
- `github-actions-docs` — when editing GitHub Actions workflows or CI
- `docker-expert` — for Docker, Dockerfile, or distro image work
- `docker-patterns` — for Docker Compose or container security patterns
- `bdd-gherkin-specification` — when writing Gherkin under assets/features
- `bdd-patterns` — for BDD pattern questions during feature work
- `bdd-principles` — for BDD philosophy or acceptance-test phrasing
- `bdd-scenarios` — when designing Gherkin scenarios or edge cases
- `cucumber-gherkin` — for Cucumber/Gherkin syntax under assets/features
- `spec-driven-development` — when planning SDD artifacts under assets/specs/ (with using-superpowers)
- `using-superpowers` — at conversation start and when selecting skills for SDD work
- `writing-plans` — before multi-step implementation work
- `receiving-code-review` — when applying review feedback
- `requesting-code-review` — when preparing a review handoff or PR
- `docs-writer` — when writing or reviewing assets/guides or assets/specs
- `ast-grep` — for structural search or rewrite rules
- `verification-before-completion` — as a reminder; dots-quality-gate remains the executable authority
- `flox-environments` — when editing config/flox or Flox environments
- `neovim-best-practices` — when editing config/nvim or Neovim Lua
- `lua` — for Lua under config/nvim or Busted tests
<!-- skills:optional-companions:end -->

## Cursor rules

Project rules live under [`.cursor/rules/`](.cursor/rules/).
