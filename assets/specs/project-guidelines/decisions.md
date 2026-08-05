<!-- markdownlint-disable-file -->

# Decisions: project guidelines rewrite

Recorded decisions for the `assets/guides/` rewrite and skill registry automation.
See [requirements.md](requirements.md) and [design.md](design.md).

## Decision 1: Skill registry automation (Approach B)

**Context:** `SKILLS.md` and `SKILLS.yml` were copied from kb/Electrobun and
reference tooling that does not exist in Dots.

**Options considered:**

1. **Documentation-only registry** — rewrite guides without lock file or mise tasks.
2. **Full kb-style toolchain** — `skills-lock.json`, owned skills, `mise run skill validate|sync|install`.
3. **Delete SKILLS.\*** — rely on `.cursor/rules` only.

**Decision:** Option 2 (full toolchain), adapted for Dots.

**Rationale:** User explicitly chose B. Repeatable validation prevents registry
drift; sync keeps agent entry points aligned with `SKILLS.yml`.

## Decision 2: SDD location

**Context:** Brainstorming default path is `docs/superpowers/specs/`; Dots
already uses `assets/specs/`.

**Decision:** All SDD artifacts for this effort live under
`assets/specs/project-guidelines/`.

**Rationale:** Matches [project-structure design](../project-structure/design.md)
and user instruction.

## Decision 3: Owned project skills

**Context:** kb uses `kb-context`, `kb-testing`, `kb-quality-gate` as owned skills.

**Decision:** Dots owned skills:

| Skill ID            | Purpose                                                          |
| ------------------- | ---------------------------------------------------------------- |
| `dots-context`      | Mandatory orientation: stack, paths, SDD location, guide routing |
| `dots-testing`      | Verification layers, mise gates, Bun integration patterns        |
| `dots-quality-gate` | Definition of done and commit-readiness checklist                |

**Rationale:** Project-specific workflow cannot live in global skills alone.

## Decision 4: Project-managed external skills (skills-lock.json)

**Context:** Skills CLI pins external skills under `.agents/skills/` via
`skills-lock.json`.

**Decision:** Pin these as `location: project` in `SKILLS.yml` and lock file:

- `bun-development`, `bun-runtime`
- `mise-expert`, `mise-tasks`
- `github-actions-docs`
- `docker-expert`, `docker-patterns`, `docker-compose-orchestration`, `multi-stage-dockerfile`
- `bdd-gherkin-specification`, `bdd-patterns`, `bdd-principles`, `bdd-scenarios`, `cucumber-gherkin`

**Rationale:** Domains with dedicated guide rewrites; pinning ensures CI and
agents see consistent skill content.

## Decision 5: Global companions and blocked skills

**Context:** 213 skills exist under `~/.agents/skills`; most are irrelevant.

**Decision:**

- Register ~25 global `optional` / `reference` companions (workflow, git, docs, debugging).
- Block Electrobun, Elysia, Firebase, AWS serverless, Vercel deploy, and other
  stacks not used in Dots with `redirect_to` guide paths.

**Rationale:** Prevents agents from applying wrong-project patterns.

## Decision 6: Generated sync targets

**Context:** kb syncs into `CLAUDE.md`, `kb-context`, and
`.cursor/electrobun-skill-routing.md`.

**Decision:** Dots sync targets:

| File                                   | Marker                | Content                      |
| -------------------------------------- | --------------------- | ---------------------------- |
| `AGENTS.md`                            | `optional-companions` | Optional skill bullet list   |
| `.agents/skills/dots-context/SKILL.md` | `optional-companions` | Companion table              |
| `.cursor/dots-skill-routing.md`        | `domain-routing`      | Domain → skill routing table |

**Rationale:** No Electrobun; domain routing covers shell, docker, bdd, mise, ci.

## Decision 7: Skill runner placement

**Context:** kb embeds ~350 lines of Bun in root `mise.toml`.

**Decision:** Implement `assets/scripts/skill-registry.ts`; expose via
`assets/mise.toml` task `skill` with subcommands `validate`, `sync`, `install`, `report`.

**Rationale:** Keeps mise.toml readable; script is testable and lintable.

## Decision 8: Guide rewrite scope

**Context:** 13 guide files; varying fidelity to Dots.

**Decision:**

| File                                   | Action                                   |
| -------------------------------------- | ---------------------------------------- |
| `SKILLS.md`, `SKILLS.yml`              | Full rewrite                             |
| `CI_GUIDE.md`                          | Full rewrite from `.github/workflows/*`  |
| `GLOSSARY.md`                          | Extend                                   |
| `CODESTYLE_GUIDE.md`                   | Rewrite for shell/zsh + assets Bun       |
| `BDD_GUIDE.md`, `BDD_GHERKIN_GUIDE.md` | Refresh with skill references            |
| `DOCKER_GUIDE.md`                      | Create                                   |
| `MISE_GUIDE.md`                        | Rewrite (usage-first)                    |
| `README.md`                            | Update index                             |
| `TESTING_GUIDE.md`                     | Light pass (remove kb/SQLite/FCIS cruft) |

**Rationale:** User scope; BDD guides already mostly correct.

## Decision 9: Mise and usage documentation baseline

**Context:** User linked usage.jdx.dev and mise task docs.

**Decision:** `MISE_GUIDE.md` SHALL document:

- Root vs `assets/mise.toml` task split
- `usage` field and `${usage_*?}` in bash bodies
- File tasks vs TOML tasks
- `mise run` vs bare `mise <task>` (prefer `mise run` in docs)
- Link to official docs as reference, not replacement for Dots paths

**Rationale:** Aligns with existing root `build` task and assets verification tasks.

## Decision 10: Implementation workflow

**Context:** User requested subagent-driven-development with task marking.

**Decision:** Execute [tasks.md](tasks.md) sequentially; mark each task complete
in `tasks.md` only after gates pass; one conventional commit per task group.

**Rationale:** Matches project-structure task discipline and user instruction.
