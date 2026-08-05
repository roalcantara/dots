<!-- markdownlint-disable-file -->

# DESIGN: project guidelines

Normative contract for rewriting `assets/guides/`, skill registry automation,
and sync targets. Implements [requirements.md](requirements.md);
decisions in [decisions.md](decisions.md).

## Scope

- Rewrite or create guides listed in Requirement 8–9.
- Add skill toolchain: `skills-lock.json`, `assets/scripts/skill-registry.ts`,
  `assets/mise.toml` `skill` task, owned `.agents/skills/*`.
- Update `assets/specs/README.md` to index `project-guidelines`.

## Non-goals

- Implementing hk migration (documented in `assets/specs/update-hooks/` only).
- Adding new verification tests beyond skill validate gates.
- Rewriting every line of `TESTING_GUIDE.md` (light pass only).
- Installing skills globally on maintainer machines (project install only).

## Skill registry schema

`assets/guides/SKILLS.yml` keeps kb-compatible v3 shape:

```yaml
schema_version: 3
description: Project skill registry for Dots.
locations:
  owned: Project-authored skill under .agents/skills/<skill-id>.
  project: External skill in skills-lock.json, restored to .agents/skills/<skill-id>.
  global: Companion from $HOME/.agents/skills/<skill-id> when available.
skills:
  <skill-id>:
    location: owned | project | global
    rationale: string
    policy:
      type: required | optional | reference | blocked
      usage: ...        # required, optional, reference
      reason: ...       # blocked
      redirect_to: ...  # blocked optional
      surfaces: ...     # optional only — claude_optional, dots_context_optional
      routing: ...      # optional — domain routing for sync
```

### Policy types in Dots

| Type        | Count (target)        | Notes                                      |
| ----------- | --------------------- | ------------------------------------------ |
| `required`  | 3 owned + 0–2 project | Standing skills for context, testing, gate |
| `optional`  | ~20 global            | Companion matrix                           |
| `reference` | ~5 global             | Read-only upstream                         |
| `blocked`   | ~15 global            | Wrong-project stacks                       |

Dots does **not** use `routed` policy type (no Electrobun). Domain selection
uses `policy.routing.domain` entries synced to `.cursor/dots-skill-routing.md`.

### Forbidden skill fields

Same as kb: no per-skill `source`, `install`, `link`, `decision`, or `load`.

## Owned skills

### dots-context

Path: `.agents/skills/dots-context/SKILL.md`

Must include:

- Stack: Bash/Zsh, mise, Flox, Docker, Bun (assets only), Neovim/Lua, SOPS, hk
- Paths: `config/bin`, `config/zsh`, `assets/{guides,specs,features,integration}`
- SDD: `assets/specs/<slug>/` not `docs/superpowers/`
- Managed block: `<!-- skills:optional-companions:start/end -->`
- Link: `assets/guides/SKILLS.md`, `AGENTS.md`

### dots-testing

Path: `.agents/skills/dots-testing/SKILL.md`

Must include:

- Layers: specs, features, integration
- Gates: `mise run -C assets test bin`, `mise run test` (root Docker CST)
- Bun: `bun test` under `assets/integration/` only
- Link: `assets/guides/TESTING_GUIDE.md`, `assets/guides/BDD_GUIDE.md`

### dots-quality-gate

Path: `.agents/skills/dots-quality-gate/SKILL.md`

Must include:

- `assets/guides/DoD.md` checklist
- Pre-commit: shellcheck, relevant mise gates
- No commit without user request (user rule reference)

## skills-lock.json

Location: repository root `/skills-lock.json`

Format: Skills CLI v1 (see kb lock file). Initial project skills:

| Skill ID                       | Source package (install via Skills CLI)                |
| ------------------------------ | ------------------------------------------------------ |
| `bun-development`              | sickn33/antigravity-awesome-skills                     |
| `bun-runtime`                  | affaan-m/everything-claude-code                        |
| `mise-expert`                  | (from global hash if available — populate on install)  |
| `mise-tasks`                   | (from global hash if available)                        |
| `github-actions-docs`          | anthropics or vercel-labs agent-skills bundle          |
| `docker-expert`                | user global — record hash from `skills list` after add |
| `docker-patterns`              | same                                                   |
| `docker-compose-orchestration` | same                                                   |
| `multi-stage-dockerfile`       | same                                                   |
| `bdd-gherkin-specification`    | same                                                   |
| `bdd-patterns`                 | same                                                   |
| `bdd-principles`               | same                                                   |
| `bdd-scenarios`                | same                                                   |
| `cucumber-gherkin`             | same                                                   |

**Install procedure:** maintainer runs `npx skills add <package> -s <skill> -a cursor -y`
(without `-g`) for each; lock file is generated/updated by CLI. Implementation
task seeds lock entries copied from known-good global installs where possible.

## skill-registry.ts

Path: `assets/scripts/skill-registry.ts`

Environment from mise task:

- `usage_cmd`: `validate` | `sync` | `install` | `report` | `all`
- `usage_dry_run`: boolean
- `usage_json`: boolean (report only)

Behavior (adapted from kb):

1. **validate** — load YAML from `assets/guides/SKILLS.yml` via Bun YAML import;
   check schema, policy shapes, lock/registry consistency; run `skills list --json`
   for project install drift.
2. **sync** — after validate, replace managed blocks:
   - `AGENTS.md` → optional companions bullet list from `policy.surfaces.claude_optional`
   - `.agents/skills/dots-context/SKILL.md` → companion table
   - `.cursor/dots-skill-routing.md` → domain routing table from `policy.routing.domain`
3. **install** — `skills experimental_install` at repo root
4. **report** — counts by location and policy type; JSON optional

Exit code 1 on validation failure.

## Mise task

In `assets/mise.toml`:

```toml
[tasks.skill]
description = "Validate, sync, install, and report skill registry"
usage = '''
cmd "validate" {}
cmd "sync" {}
cmd "install" {}
cmd "all" {}
cmd "report" {
  flag "--json" help="Machine-readable report"
}
flag "--dry-run" help="Validate writes without changing files"
'''
run = "bun run scripts/skill-registry.ts"
```

Add tool dependency if needed: `node` already in assets mise.toml.

Root `mise.toml` MAY add thin wrapper:

```toml
[tasks."skill:validate"]
run = "mise run -C assets skill validate"
```

(Optional — document direct `mise run -C assets skill validate` in SKILLS.md.)

## AGENTS.md (repository root)

Create with:

- Project summary for agents
- Pointer to `assets/guides/SKILLS.md`
- Managed block `<!-- skills:optional-companions:start/end -->`
- Pointer to `.cursor/rules/`

## dots-skill-routing.md

Path: `.cursor/dots-skill-routing.md`

Managed block `<!-- skills:domain-routing:start/end -->`

Table columns: When the task involves… | Read this skill first | Note

Example rows:

| Triggers                           | Skill                       | Note    |
| ---------------------------------- | --------------------------- | ------- |
| Docker, Dockerfile, CST, distros   | `docker-expert`             | project |
| mise.toml, usage field, task args  | `mise-expert`               | project |
| GitHub Actions, workflows          | `github-actions-docs`       | project |
| Gherkin, Cucumber, assets/features | `bdd-gherkin-specification` | project |
| config/bin, install, shell scripts | `bash-scripting`            | global  |

## Per-file guide contracts

### SKILLS.md

- Mirror SKILLS.yml schema explanation for Dots
- Commands: `mise run -C assets skill validate|sync|install`
- Current project skills table (owned + project)
- Optional companion matrix
- Blocked skills table
- Update workflow numbered list

### CI_GUIDE.md

Structure:

1. Overview — three workflows
2. Preview (PR) — lint, build, CST, matrix debian/ubuntu
3. Release — semantic-release on main
4. Publish — (read publish.yml for actual jobs)
5. Secrets table
6. Local parity commands
7. Troubleshooting

### DOCKER_GUIDE.md

Structure:

1. Layout — `distros/{debian,ubuntu,alpine}/`
2. Build — `mise run build` flags
3. Targets — remote vs local
4. CI — Preview workflow
5. CST — `container-structure-test.yml` per distro
6. Hadolint — `.hadolint.yaml`
7. Flox in image — pointer to `config/flox/`
8. Suggested improvements (≥3)

### CODESTYLE_GUIDE.md

Structure:

1. Core principles (keep DRY, minimal scope)
2. Shell — bash-scripting skill, ShellCheck, `##?` headers
3. Zsh — configuring-zsh, xc-usage delegation
4. TypeScript (assets/) — bun-development, table-driven tests
5. Lua (config/nvim) — brief, neovim-best-practices
6. Remove kodexb/TypeBox/Elysia sections

### MISE_GUIDE.md

Structure:

1. Root vs assets mise.toml
2. usage field and `${usage_*?}` patterns (link official docs)
3. Task groups: build, test, bdd, integration, skill
4. File tasks vs inline tasks
5. Completions
6. Skills: mise-expert, mise-tasks

### BDD guides

Add top section:

```markdown
## Skills to load

| Situation       | Skill                                       |
| --------------- | ------------------------------------------- |
| Writing Gherkin | bdd-gherkin-specification, cucumber-gherkin |
| Scenario design | bdd-scenarios, bdd-patterns                 |
| Philosophy      | bdd-principles                              |
```

### GLOSSARY.md

Add rows for: Hadolint, CST, DevContainer, Flox, SOPS, hk, usage CLI,
`usage_*`, skills-lock, dots-context.

### README.md

Add rows: SKILLS.md, CI_GUIDE.md, DOCKER_GUIDE.md; note agents read SKILLS first.

## Verification gates

| Gate                       | Command                                                    |
| -------------------------- | ---------------------------------------------------------- |
| No kb/electrobun in guides | `rg -i 'kb-context                                         | kodexb | electrobun                                                   | elysia | typebox' assets/guides` → 0 |
| Skill validate             | `mise run -C assets skill validate` → exit 0               |
| Skill sync idempotent      | `mise run -C assets skill sync` twice → no diff second run |
| Bin tests (unchanged)      | `mise run -C assets test bin` → pass                       |
| Placeholder scan           | `rg 'TBD                                                   | TODO   | pick one' assets/specs/project-guidelines assets/guides` → 0 |

## Error handling

- `skill validate` prints `skill validate: <message>` and exits 1
- Missing managed markers in sync targets → exit 1 with file path
- Skills CLI missing → validate fails with install instructions
