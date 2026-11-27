# Mise Task Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every TOML task out of the root `mise.toml` into `<topic>/tasks.toml` files, included by glob, with
names and behaviour unchanged.

**Architecture:** `[task_config] includes` gains two globs; each topic file holds top-level task tables moved
verbatim. A guard spec keeps the root free of tasks; the specs that read tasks from `mise.toml` read the new files.

**Tech Stack:** mise 2026.11.14, Bun specs, hk (tombi, taplo, markdownlint).

**Spec:** `docs/superpowers/specs/2026-11-27-mise-task-layout-design.md`

## Global Constraints

- Task names, `run`, `usage`, `tools`, `env`, `dir` and comments move verbatim; only the table header changes
  (`[tasks."zsh:verify"]` → `["zsh:verify"]`).
- Includes: `[".mise/tasks", "*/tasks.toml", "config/*/tasks.toml"]`.
- Stage named paths only; commit through the SOPS git wrapper; no push.

## Review Focus

1. A task whose `run` uses a relative path (`./script/…`, `config/…`) must still work from any cwd: checked by running
   `mise run --dry-run` for one task per file from `~` with `-C`.
2. A comment that sat above a task header in `mise.toml` must move with its task, not stay orphaned in the root.
3. `config/mise/conf.d/tasks.toml` must not be matched by the globs (it is `config/mise/conf.d/…`, two levels deep).
4. `mise tasks ls --hidden` names and descriptions identical to the baseline.
5. Docs that say tasks live in `mise.toml` (README, CONTRIBUTING, DOCKER, GLOSSARY, THEME, AGENTS) are updated.

---

### Task 1: Move the tasks and guard the root

**Files:**
- Create: the ten `tasks.toml` files in the spec's mapping
- Modify: `mise.toml` (includes; tasks removed)
- Modify: `test/integration/bin/theme.spec.ts:194`, `test/integration/bootstrap/sops-diff.spec.ts:12`,
  `test/integration/bootstrap/sops-resmudge.spec.ts:10`, `test/integration/bootstrap/tuis.spec.ts:109` (read the
  task's new file)
- Create: `test/integration/bootstrap/task-layout.spec.ts`

- [ ] **Step 1: Baseline.** `mise tasks ls --hidden --json | jq -S 'map({name, description})'` saved to the scratchpad.
- [ ] **Step 2: Failing spec** `task-layout.spec.ts`:
  - `the root mise.toml declares no tasks`: `Bun.TOML.parse(mise.toml).tasks` is undefined.
  - `the includes find topic files, never mise's own config folder`: the globs match at least one file, none under
    `config/mise/`.
  - `every topic file uses top-level task tables, and mise loads each of its tasks`: no `tasks` key in any matched
    file; each task name is in `mise tasks ls --hidden --json`.
  - The spec checks behaviour, not the mapping itself, so adding a task or a topic needs no spec edit.
- [ ] **Step 3:** Move the tables per the mapping; set the includes.
- [ ] **Step 4:** Point the four specs at the new files; run `bun test test/integration`; expect all pass.
- [ ] **Step 5:** Baseline diff empty; `mise run --dry-run -C ~/.local/share/dots zsh:verify` from `~` prints the
  `./script/zsh-verify.sh` steps; `hk check --all` passes.
- [ ] **Step 6: Commit** `refactor(mise): Keep each repo task next to what it manages`.

### Task 2: Document the rule

**Files:** `docs/CONTRIBUTING.md` §4, `AGENTS.md` (layout and `mise-tasks` skill line), `README.md:78,235`,
`docs/DOCKER.md:15,49`, `docs/GLOSSARY.md:18`, `docs/THEME.md:182`.

- [ ] **Step 1:** CONTRIBUTING §4 states the rule (the spec's three bullets) with the mapping table and the
  top-level-names example; the other docs name the task's new file.
- [ ] **Step 2:** `hk check --all` and `mise run test:specs` pass.
- [ ] **Step 3: Commit** `docs(mise): Document where repo tasks live`.
