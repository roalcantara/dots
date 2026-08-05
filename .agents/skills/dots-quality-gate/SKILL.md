---
name: dots-quality-gate
description: Executable completion gate for Dots work. Load before declaring tasks complete or preparing commits. Combines DoD checklist with mise verification commands.
---

# Dots — quality gate

## Before marking work complete

1. Read [`assets/guides/DoD.md`](../../assets/guides/DoD.md).
2. Run relevant verification gates (see below).
3. Run `mise run -C assets skill validate` if `SKILLS.yml` changed.
4. Do **not** create git commits unless the user explicitly asked.

## Gates by change type

| Change                     | Gate                                                            |
| -------------------------- | --------------------------------------------------------------- |
| `config/bin/*`             | `mise run -C assets test bin`                                   |
| `assets/guides/SKILLS.yml` | `mise run -C assets skill validate` then `skill sync`           |
| `mise.toml` tasks          | `mise tasks` lists task; smoke-run affected task                |
| Docker / distros           | `mise run build --help`; CI workflows unchanged or docs updated |
| Zsh functions              | `zsh -n` on edited files; integration if behavior changed       |
| Guides only                | `rg -i 'kb                                                      | electrobun | kodexb' assets/guides` → zero |

## Definition of done

From [`assets/guides/DoD.md`](../../assets/guides/DoD.md):

- Requirements met and traceable to spec tasks
- Verification commands pass with zero errors
- No unrelated scope creep
- Conventional commit message ready (when user requests commit)

## Reminder skills

`verification-before-completion` is a optional reminder only —
**this skill and DoD.md are the executable authority for Dots.**
