<!-- markdownlint-disable-file -->

# TASKS: project guidelines

Execute task groups in order. Mark a group complete only when every gate is
green. One conventional commit per completed group.

Reference: [requirements.md](requirements.md), [design.md](design.md),
[decisions.md](decisions.md).

## Task 1: SDD artifacts

Deliverable: this spec folder exists before guide rewrites.

- [x] Create `assets/specs/project-guidelines/requirements.md`.
- [x] Create `assets/specs/project-guidelines/design.md`.
- [x] Create `assets/specs/project-guidelines/tasks.md`.
- [x] Create `assets/specs/project-guidelines/decisions.md`.
- [x] Create `assets/specs/project-guidelines/HANDOFF.md`.
- [x] Update `assets/specs/README.md` with `project-guidelines` row.
- [x] Run `rg -n 'TBD|TODO|pick one' assets/specs/project-guidelines`.

**Gate:** Spec files exist; placeholder scan clean.

## Task 2: Skill infrastructure

Deliverable: validate/sync/install toolchain and owned skills.

- [x] Create `assets/scripts/skill-registry.ts` per design.
- [x] Add `[tasks.skill]` to `assets/mise.toml`.
- [x] Create `AGENTS.md` with managed markers.
- [x] Create `.cursor/dots-skill-routing.md` with managed markers.
- [x] Create `.agents/skills/dots-context/SKILL.md`.
- [x] Create `.agents/skills/dots-testing/SKILL.md`.
- [x] Create `.agents/skills/dots-quality-gate/SKILL.md`.
- [x] Create initial `skills-lock.json` (project skills from design).
- [x] Run `mise run -C assets skill validate`.
- [x] Run `mise run -C assets skill sync`.
- [x] Commit: `feat(assets): Add Dots skill registry toolchain`.

**Gate:** `skill validate` and `skill sync` exit 0; owned skills exist.

## Task 3: SKILLS.yml and SKILLS.md rewrite

Deliverable: Dots skill registry content.

- [x] Rewrite `assets/guides/SKILLS.yml` (remove all kb/electrobun entries).
- [x] Rewrite `assets/guides/SKILLS.md` to match YAML.
- [x] Run `mise run -C assets skill validate`.
- [x] Run `mise run -C assets skill sync`.
- [x] Run `rg -i 'kb-context|kodexb|apps/kb' assets/guides/SKILLS.md assets/guides/SKILLS.yml`.
- [x] Commit: `docs(guides): Rewrite SKILLS registry for Dots`.

**Gate:** kb grep zero; validate passes.

## Task 4: CI_GUIDE rewrite

Deliverable: accurate CI documentation.

- [x] Rewrite `assets/guides/CI_GUIDE.md` from workflow files.
- [x] Cross-link `DOCKER_GUIDE.md`.
- [x] Run `rg -i 'electrobun|kb-' assets/guides/CI_GUIDE.md`.
- [x] Commit: `docs(guides): Rewrite CI_GUIDE for Dots workflows`.

**Gate:** CI guide matches three workflow files; no kb references.

## Task 5: GLOSSARY extension

Deliverable: new terms for guides.

- [x] Extend `assets/guides/GLOSSARY.md` per design.
- [x] Commit: `docs(guides): Extend GLOSSARY for project guidelines`.

**Gate:** New terms present; links valid.

## Task 6: CODESTYLE_GUIDE rewrite

Deliverable: Dots-scoped code style.

- [x] Rewrite `assets/guides/CODESTYLE_GUIDE.md`.
- [x] Run `rg -i 'kodexb|typebox|elysia' assets/guides/CODESTYLE_GUIDE.md`.
- [x] Commit: `docs(guides): Rewrite CODESTYLE for Dots stack`.

**Gate:** kodexb grep zero.

## Task 7: BDD guides refresh

Deliverable: skill references in BDD guides.

- [x] Update `assets/guides/BDD_GUIDE.md` with Skills section.
- [x] Update `assets/guides/BDD_GHERKIN_GUIDE.md` with Skills section.
- [x] Commit: `docs(guides): Add BDD skill references`.

**Gate:** Skills sections present; paths under `assets/`.

## Task 8: DOCKER_GUIDE creation

Deliverable: new Docker guide.

- [x] Create `assets/guides/DOCKER_GUIDE.md`.
- [x] Commit: `docs(guides): Add DOCKER_GUIDE for Dots`.

**Gate:** Documents build, CI, CST; ≥3 improvements.

## Task 9: MISE_GUIDE rewrite

Deliverable: usage-first mise guide.

- [x] Rewrite `assets/guides/MISE_GUIDE.md`.
- [x] Run `rg -i 'kodexb|apps/kb' assets/guides/MISE_GUIDE.md`.
- [x] Commit: `docs(guides): Rewrite MISE_GUIDE with usage patterns`.

**Gate:** kodexb grep zero.

## Task 10: Index, TESTING light pass, final gates

Deliverable: complete guide set.

- [x] Update `assets/guides/README.md` index.
- [x] Light pass on `assets/guides/TESTING_GUIDE.md`.
- [x] Run `rg -i 'kb-context|kodexb|apps/kb' assets/guides`.
- [x] Run `mise run -C assets test bin`.
- [x] Mark all tasks `[x]` in this file.
- [ ] Commit: `docs(guides): Update guide index and TESTING light pass`.

**Gate:** Full guides kb grep zero; bin tests pass.
