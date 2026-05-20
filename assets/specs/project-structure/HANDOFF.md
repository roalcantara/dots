# HANDOFF: project structure migration

Task 1 (SDD + indexes) is complete. Implementation starts at **Task 2** in
[tasks.md](tasks.md).

## Goal

Migrate Dots verification layout to `assets/` (guides, specs, features,
integration, mise toolchain) per [design.md](design.md). Do not execute Tasks
3–8 until Task 2 gates pass.

## Current state

- SDD trio and indexes committed under `assets/specs/project-structure/`.
- Pilot BDD still at `assets/features/bin/`, root `package.json`, root
  `docs:bdd*` tasks — **unchanged until Tasks 3–6**.
- Canonical mise model: merged `bdd`, `integration`, `test` in `assets/mise.toml`
  with `usage` args; from repo root use `mise run -C assets …` (root `test` is
  Docker CST).

## Next task group

**Task 2: Guides merge** — follow [design.md § Per-file content contracts](design.md#per-file-content-contracts-task-2).

## Verification (after Task 6 only)

```bash
mise run -C assets test bin
mise run -C assets test all
```
