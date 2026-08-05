<!-- markdownlint-disable-file -->

# HANDOFF: project guidelines

## Goal

Rewrite `assets/guides/` for the Dots dotfiles repository and add kb-style skill
registry automation (Approach B).

## Spec location

`assets/specs/project-guidelines/` — requirements, design, tasks, decisions.

## Execution order

Follow [tasks.md](tasks.md) Tasks 1–10 sequentially. Mark each task complete
before starting the next.

## Key commands

```bash
mise run -C assets skill validate
mise run -C assets skill sync
mise run -C assets skill install
mise run -C assets test bin
rg -i 'kb|electrobun|kodexb' assets/guides
```

## Skill registry

- Source of truth: `assets/guides/SKILLS.yml`
- Lock file: `skills-lock.json` (repo root)
- Owned skills: `.agents/skills/dots-{context,testing,quality-gate}/`
- Runner: `assets/scripts/skill-registry.ts`

## Do not

- Reference kb, Electrobun, kodexb, TypeBox, or Elysia in rewritten guides.
- Use `docs/superpowers/` for SDD output — use `assets/specs/<slug>/`.
- Skip `skill validate` after editing `SKILLS.yml`.

## References

- [project-structure design](../project-structure/design.md) — assets layout
- [usage.jdx.dev](https://usage.jdx.dev/) — task argument spec
- [mise tasks](https://mise.jdx.dev/tasks/) — task runner docs
