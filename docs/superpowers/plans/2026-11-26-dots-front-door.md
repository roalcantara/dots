# dots front door Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `bootstrap:hook:*` hand-overs and loose tasks with one documented front door,
`mise run dots setup|backup|profile`. Bootstrap's hard-coded values move to `conf.d/vars.yaml`, `dotfiles.toml`
becomes a dotfile group, and each `conf.d` file gets one job.

**Architecture:**
- A global `dots` task in `config/mise/conf.d/tasks.toml` parses `usage` subcommands.
- `setup` runs, in a fixed order, the hidden repo tasks `dots:setup:<part>`. Each runs its hidden step file tasks.
- Hooks and the global `bootstrap` task call `dots setup --<parts>`.
- The profile is a validated `--profile` flag backed by `DOTS_PROFILE`.

**Tech Stack:** mise 2026.11.14 (`usage` cmd/flags/choices/`env=`, task templates or `.usage.kdl` flagsets, `hide`,
`[vars] _.file`, dotfile groups, `dotfiles.root`), bash step tasks, Bun specs, hk.

**Spec:** [`docs/superpowers/specs/2026-11-26-dots-front-door-design.md`](../specs/2026-11-26-dots-front-door-design.md),
the only source of architectural decisions. Read it, including its "Facts" table, before Task 1. Where this plan and
the spec disagree, the spec wins: stop and report.

## Global Constraints

- **Branch:** `feat/mise-bootstrap-tasks`, no worktree. Lida tasks `awGX` (previous plan) and `siXn` (this plan).
- **git:**
  - Always through the SOPS wrapper: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`.
  - Stage named paths only.
  - Conventional Commits with a capitalized description, ending with the session's `Co-Authored-By` line.
  - No push, no PR.
- **Owner authorization for two uncommitted files:**
  - The working-tree edits to `config/mise/conf.d/backup.toml` are the owner's pseudo-code sketch. You may overwrite
    and delete that file (Task 6).
  - `config/mise/conf.d/.env.sh` is untracked and git-ignored. Leave it alone; the owner deletes it.
- **Docs first:** before using any mise feature this plan names, read its page on mise.jdx.dev, or run
  `mise help …`, and test it on the installed mise. If it behaves differently from the spec's Facts table, stop and
  report.
- **Names:**
  - The front door is task `dots` with subcommands `setup`, `backup` and `profile`.
  - Parts are the hidden tasks `dots:setup:<part>`.
  - Steps keep their `bootstrap:<area>:<step>` names and become hidden.
- **Part flags, in run order:** `--brew --yabai --app-files --vscode --bat --lig --macos --swiftbar --git --shell
  --dev --secrets --tiling --ai --skills --nvim`. `brew:remind` always runs last and has no flag.
- **Profiles:** `desktop`, `dev` and `container`. `--profile` has `choices "desktop" "dev" "container"`,
  `env="DOTS_PROFILE"` and default `desktop`.
- **`conf.d` after this plan:** `bootstrap.toml`, `dotfiles.toml`, `macos.toml`, `system.toml`, `tasks.toml` and
  `vars.yaml`. `yabai.toml`, `backup.toml` and `setup.toml` are gone.
- **No global `[env]`** for dots values. Values reach hooks and tasks as `{{ vars.* }}`, and steps through flags.
- **Specs test behaviour,** never the owner's chosen config values.
- **Leave published blog posts alone** (`docs/blog/posts/**`). Their old command names are history.
- **Gates before each commit:** that task's specs and `hk check` on the touched files. Before the handoff: everything
  in Task 9.

## Review Focus

1. **A typo in a part or profile fails before anything runs.** `mise run dots setup --brw` and `--profile devv` exit
   non-zero with no step started. Test in Task 5.
2. **`mise_env` holding a name that isn't a profile** (a future platform environment such as `macos`) must not break
   bootstrap. The hand-over passes only `desktop`, `dev` and `container`. Test in Task 5 (hand-over spec,
   `-E desktop,macos`).
3. **`dots setup` with no part flags runs every part in order,** and `dots setup --git --brew` runs `brew` before
   `git` (fixed order, not flag order). Test in Task 5.
4. **Moving the checkout:** with `dots_dir` changed in `vars.yaml` and `dotfiles.root` changed to match, the hand-over
   and `dots` reach the new path, and the agreement spec fails when only one of them changes. Test in Task 1.
5. **A step run by hand** (`mise run bootstrap:gopass:store`, hidden) still gets the profile from `--profile`,
   `DOTS_PROFILE`, this run's filtered `mise_env` (e.g. `miserc.local.toml`), or `desktop`, and rejects an invalid one.
   Test in Task 3.

## Baseline (before Task 1)

Save to `B="$(g rev-parse --git-common-dir)/wip/front-door-baseline"`:

- [ ] `mise dot status > $B/dot-status.txt 2>&1`, `mise bootstrap plan > $B/plan.txt 2>&1`
- [ ] For each phase in `post-packages pre-dotfiles post-dotfiles post-defaults final`:
  `mise run -C ~/.local/share/dots --dry-run bootstrap:hook:$p 2>&1 | grep -o 'bootstrap:[a-z-]*:[a-z-]*' > $B/order-$p.txt`
- [ ] `mise tasks ls > $B/tasks.txt`. Per spec file in `test/integration/bootstrap/`, `bun test <file>` pass counts
  go to `$B/spec-counts.txt`.
- [ ] `g rev-parse HEAD > $B/base.txt`

---

### Task 1: `vars.yaml` and the dots location

**Files:**
- Create: `config/mise/conf.d/vars.yaml` (`dots_dir: .local/share/dots`, with a header comment)
- Modify: `config/mise/conf.d/bootstrap.toml` (`[vars]`), `config/mise/config.toml` (`[settings]`)
- Test: `test/integration/bootstrap/vars.spec.ts`

**Interfaces (Produces):**
- vars: `_.file = "{{ mise_config_dir }}/conf.d/vars.yaml"`, then `dots = "{{ env.HOME }}/{{ vars.dots_dir }}"`.
  Every later task uses `{{ vars.dots }}`, never a literal `.local/share/dots`.
- settings: `dotfiles.root = "{{ xdg_data_home }}/dots"`, `dotfiles.relative_symlinks = true`.
- Existing `dots_profile`/`dots_handover` keep working until Task 5 replaces them, now built on `vars.dots`.

- [ ] **Step 1: Failing `vars.spec.ts`.** Each case runs the real `mise` on a temp `MISE_CONFIG_DIR` holding copies
  of `bootstrap.toml`'s `[vars]` and `vars.yaml`, like `handover.spec.ts`:
  - `vars.dots renders $HOME plus dots_dir`: assert on `mise run --dry-run` output, or on a probe hook.
  - `vars.dots follows a changed dots_dir`: write `dots_dir: src/dots` and assert `<HOME>/src/dots`
    (Review Focus 4).
  - `dotfiles.root and vars.dots agree for the default XDG layout`: parse both files. With `XDG_DATA_HOME` unset,
    `dotfiles.root`'s template must resolve to `$HOME/` + `dots_dir`. Changing only one of them makes this fail;
    prove it with a temp copy.
  - `no literal .local/share/dots remains in config/mise/conf.d/*.toml or config/mise/config.toml`, except inside
    `vars.yaml`. The plain `[dotfiles]` entries Task 2 is allowed to keep are listed in the spec by target.
    Mark this case `it.todo` until Task 2.
- [ ] **Step 2:** It fails. **Step 3:** Implement. **Step 4:** It passes. `(cd ~ && mise bootstrap --dry-run)` prints
  no `WARN`.
- [ ] **Step 5: Commit:** `feat(bootstrap): Keep the dots location in conf.d/vars.yaml`.

### Task 2: `dotfiles.toml` as a dotfile group

**Files:** Modify `config/mise/conf.d/dotfiles.toml`. Test: `test/integration/bootstrap/dotfiles-group.spec.ts`.

- [ ] **Step 1: Failing spec:**
  - `every ~/.config/<name> link of the baseline comes from [dotfile_groups.config]`. Compare against the
    `~/.config/*` entries of the pre-change `dotfiles.toml`, read from `git show <base>:config/mise/conf.d/dotfiles.toml`.
  - `the group links nothing else`: for every name under `config/` that the old file did not link, the group excludes
    it, or the group has no walk that would link it.
  - `plain [dotfiles] entries outside ~/.config keep their targets and modes`: `~/.config/kb`, `~/.local/bin`, both
    skill-lock files, `~/.agents/commands`, `~/.claude/commands`, `~/.ssh`, `~/.gnupg`, and the vscode-* and
    claude-skills variants.
- [ ] **Step 2:** Write the group per the spec's Links section:
  - `root = "config"`, `target = "~/.config"`, `mode = "symlink-each"`, `relative = true`
  - one `{ mode = "symlink" }` entry per name, keeping each existing comment next to its entry
  - first check in mise's dotfiles docs whether entries outside the group target can drop the absolute path. If yes,
    use that; if not, keep them and list them in Task 1's spec.
- [ ] **Step 3:** Turn on Task 1's `it.todo`. Both specs pass.
- [ ] **Step 4: Behaviour unchanged.** `mise dot status` and `mise bootstrap plan`, diffed against the baseline.
  Expected: no diff. A difference means stop and fix it; do not apply.
- [ ] **Step 5: Commit:** `refactor(dotfiles): Declare the ~/.config links as one dotfile group`.

**Acceptance:**
- Both diffs are empty.
- `grep -c 'local/share/dots' config/mise/conf.d/dotfiles.toml` equals the number of allowed plain entries.

### Task 3: The `--profile` flag on every step

**Files:**
- Create: the shared definition, either `.mise/tasks/bootstrap/profile.usage.kdl` (a flagset `profile`) or a task
  template in the repo `mise.toml`. Pick one per the docs and use it on every step.
- Modify: every executable under `.mise/tasks/bootstrap/` (add the shared `--profile` and `#MISE hide=true`), and
  `.mise/tasks/bootstrap/_lib.sh`.
- Test: `bootstrap-lib.spec.ts`, `bootstrap-structure.spec.ts`, new `step-profile.spec.ts`.

**Interfaces (Produces):**
- Each step receives `usage_profile`.
- `has_profile <name>` returns 0 when `<name>` is in `usage_profile`, split on commas and spaces. It reads nothing
  else.
- `dots_profile` is deleted, together with `_lib.sh`'s `DOTS_PROFILE`, `MISE_ENV` and miserc fallbacks.

- [ ] **Step 1: Probe first** (record the result in the commit body). Does `--profile <p>` with `var=#true`,
  `choices`, `env="DOTS_PROFILE"` and `default="desktop"` accept `DOTS_PROFILE=desktop,dev`?
  - If yes, use that form.
  - If no, use the spec's fallback: a single `--profile <list>` whose comma list `has_profile` validates, exiting 2 on
    a name outside the three.
- [ ] **Step 2: Failing tests:**
  - `step-profile.spec.ts`, through the real `mise run` on the repo with a temp `HOME` and trust:
    - `a hidden step takes --profile dev`
    - `a hidden step takes DOTS_PROFILE=desktop,dev`
    - `a hidden step defaults to desktop`
    - `an invalid --profile fails before the step runs` (Review Focus 5). Pick a step with a cheap, visible effect,
      such as `bootstrap:git:home-config`, which warns when `~/.gitconfig` exists.
  - Lib spec: `has_profile` cases rewritten on `usage_profile`, with whole-name matching kept. The `dots_profile`
    cases are deleted.
  - Structure spec: `every step is hidden and uses the shared --profile definition`.
- [ ] **Step 3:** Implement. Specs that call `runStep` with `DOTS_PROFILE` switch to `usage_profile`.
- [ ] **Step 4:** All of `test/integration/bootstrap/` passes. Each migrated file's pass count is ≥ its baseline,
  minus the deleted `dots_profile` cases (state the number in the commit body).
- [ ] **Step 5: Commit:** `refactor(bootstrap): Give every step a validated --profile flag`.

### Task 4: Part tasks replace the phase tasks

**Files:**
- Rename: `.mise/tasks/bootstrap/phases.toml` → `.mise/tasks/bootstrap/parts.toml`
- Modify: the repo `mise.toml` `task_config.includes`
- Test: `bootstrap-structure.spec.ts`, new `part-order.spec.ts`

**Interfaces (Produces):** hidden tasks `dots:setup:<part>`, one per part flag (without `--`), plus
`dots:setup:remind`. Each has a `description` and runs its steps as ordered run steps, per the spec's part table.

- [ ] **Step 1: Failing `part-order.spec.ts`.**
  - `concatenating the parts in flag order gives the baseline order`. The baseline is the five `$B/order-*.txt`
    files joined. The only allowed difference is `bootstrap:zsh:warm-caches` moving after `bootstrap:git:hooks`.
  - Structure spec: `parts.toml defines exactly one task per part flag plus remind, all hidden, and every step
    belongs to exactly one part`.
- [ ] **Step 2:** It fails. **Step 3:** Implement. The `bootstrap:hook:*` tasks are deleted here, and the hooks still
  call them until Task 5, so do Tasks 4 and 5 back to back and commit them together if the hooks break between them.
  **Step 4:** It passes.
- [ ] **Step 5: Commit**, with Task 5 if needed: `refactor(bootstrap): Group the steps into dots:setup parts`.

### Task 5: The `dots` front door, `setup` subcommand, and the hooks

**Files:**
- Create: `config/mise/conf.d/tasks.toml` (`[tasks.dots]`)
- Modify: `bootstrap.toml` (vars, hooks, `[tasks.bootstrap]`)
- Test: `handover.spec.ts`, new `dots-setup.spec.ts`, `bootstrap-structure.spec.ts`

**Interfaces:**
- `dots` usage:
  - `cmd "setup"` with the 16 part flags, in order, each with the spec's help text, plus `--profile`
    (Task 3's definition).
  - `cmd "backup"` and `cmd "profile"` as stubs that exit 2 with "not yet" until Task 6.
  - The task's `description` is the spec's.
- `setup` behaviour: build the selected list (all if none), in the fixed order, then run
  `mise run -C "{{ vars.dots }}" dots:setup:<part>` for each, then `dots:setup:remind`. `DOTS_PROFILE` is exported
  from the parsed `--profile`, so the steps' flag backing picks it up.
- vars:
  - `dots_profiles` renders `--profile <name>` for each `mise_env` entry in `["desktop","dev","container"]`, or
    nothing when there are none.
  - `dots_setup = 'exec mise run dots setup {{ vars.dots_profiles }}'`.
  - Hooks: `run = "{{ vars.dots_setup }} --brew --yabai"` (post-packages), `--app-files`, `--vscode --bat --lig`,
    `--macos --swiftbar`.
  - `[tasks.bootstrap]` runs `--git --shell --dev --secrets --tiling --ai --skills --nvim`.
  - `dots_profile` and `dots_handover` are removed.

- [ ] **Step 1: Failing tests:**
  - `dots-setup.spec.ts`. It runs the real `mise run dots setup …` with the repo replaced by a temp copy, whose part
    tasks are stubs appending their name to a file:
    - `no flags runs every part in order, then remind`
    - `--git --brew runs brew then git then remind` (Review Focus 3)
    - `--brw fails before any part runs` and `--profile devv fails before any part runs` (Review Focus 1)
    - `--profile dev reaches the parts as DOTS_PROFILE=dev`
    - `mise run dots setup --help lists every part flag with its help, and --profile`
  - `handover.spec.ts`, rewritten for the new hooks:
    - `post-packages calls dots setup --brew --yabai`
    - `-E container gives --profile container`
    - `-E desktop,dev gives both`
    - `-E desktop,macos gives only desktop` (Review Focus 2)
    - `miserc env reaches the hook`
    - `no environment gives no --profile` (the flag default applies)
  - Structure spec: `each hook is {{ vars.dots_setup }} plus exactly its phase's part flags`, and
    `[tasks.bootstrap] carries the final parts`.
- [ ] **Step 2:** They fail. **Step 3:** Implement. **Step 4:** They pass. `(cd ~ && mise bootstrap --dry-run)` shows
  the five `dots setup` calls with no `WARN`. `mise tasks ls` lists `dots` and no `bootstrap:` or `dots:setup:` task.
- [ ] **Step 5: Commit:** `feat(dots): Add the dots front door and point the hooks at dots setup`.

### Task 6: `backup` and `profile` subcommands; `backup.toml` and `setup.toml` go

**Files:**
- Modify: `config/mise/conf.d/tasks.toml`
- Delete: `config/mise/conf.d/backup.toml` and `config/mise/conf.d/setup.toml`
- Modify: `script/backup.ts` (its printed commands), `test/integration/bootstrap/setup-task.spec.ts` → rename it
  `dots-profile.spec.ts`
- Test: new `dots-backup.spec.ts`

**Interfaces:**
- `cmd "backup"` takes `arg "<action>"` with choices `init backup snapshots restore forget audit`, each explained in
  `long_help`.
- Its flags: `--include <path>` (`var=#true`), `--snapshot <id>`, `--from-home <path>`, `--target <path>`,
  `--dry-run`, `--stdout`. Each has `help`, and each says which actions use it.
- It runs `bun "{{ vars.dots }}/script/backup.ts" <action> <flags as backup.ts expects>`, with tools `bun = "1.3.14"`.
- `cmd "profile"` takes `arg "<profile>"` with choices `desktop dev`. It runs
  `mise bootstrap -E <desktop|desktop,dev> --save-env --yes`.

- [ ] **Step 1: Failing tests.** `dots-backup.spec.ts` uses a stub `bun` that records its argv:
  - `restore --include Work --include Music --dry-run passes them to backup.ts restore`
  - `audit --stdout`
  - `an unknown action fails before bun runs`
  - `--help lists every action and flag`

  `dots-profile.spec.ts` keeps the old cases (exact `mise bootstrap` argv; the real `--save-env` behaviour) through
  `dots profile`.
- [ ] **Step 2:** It fails. **Step 3:** Implement, delete the two files, and update `script/backup.ts`'s messages to
  `mise run dots backup …`. **Step 4:** It passes, and so does `test/integration/backup/`.
- [ ] **Step 5: Commit:** `feat(dots): Move backup and profile under the dots front door`.

### Task 7: `yabai.toml` into `macos.toml`

**Files:** Modify `config/mise/conf.d/macos.toml`, delete `config/mise/conf.d/yabai.toml`, update `yabai.spec.ts`
(read the agents from `macos.toml`).

- [ ] Move both LaunchAgents with their comments, under a `# Tiling (docs/TILING.md)` heading in `macos.toml`.
- [ ] Run `yabai.spec.ts` and the `macos-defaults` spec. Diff `mise bootstrap plan` and `mise dot status` against the
  baseline: expected no diff.
- [ ] **Commit:** `refactor(macos): Keep yabai's LaunchAgents with the other macOS settings`.

### Task 8: Docs

**Files:** `docs/BOOTSTRAP.md`, `AGENTS.md` (layout row for `config/`, and the docs list if needed), `README.md`,
`docs/REINSTALL.md`, `docs/GLOSSARY.md`, `docs/TILING.md`, `docs/MACOS.md`, `config/hk/README.md`,
`config/bin/README.md`, `config/sops/README.md`, `config/kodexb/sources/dots.yml`, `config/homebrew/Brewfile`
comments, and `config/restic/backup.toml` comments. Test: `bootstrap-docs.spec.ts`.

- [ ] **Step 1: Failing doc spec cases:**
  - `BOOTSTRAP.md documents mise run dots and each subcommand and part flag`. Read the part flags from `tasks.toml`.
  - `no doc outside docs/blog/posts and docs/superpowers mentions bootstrap:hook:, mise run setup, reinstall:audit or
    backup:<action>`
  - `conf.d is described as six files with one job each`
- [ ] **Step 2:** Rewrite BOOTSTRAP.md's Overview, Steps and Recipes around `mise run dots`:
  - the phase diagram shows each hook's `dots setup` call
  - the Steps table gains a Part column
  - Recipes cover `dots setup --<part>`, `--profile`, running a hidden step by hand, `dots backup …` and
    `dots profile …`
  - Gotchas gain "settings can't read vars, so `dotfiles.root` mirrors `vars.yaml`"
  - Gotchas drop the ones this work made obsolete
- [ ] **Step 3:** Update every other listed file. **Step 4:** The spec and `hk check` pass.
- [ ] **Step 5: Commit:** `docs(bootstrap): Document the dots front door`.

### Task 9: Whole-branch verification, lida, handoff

- [ ] `mise run test:specs` passes, with a total ≥ the baseline total plus the new specs, minus the deleted
  `dots_profile` cases. `hk check --all` passes. `mise run zsh:verify` syntax passes.
- [ ] `mise doctor project` exits 0. `mise run mise:diagnostics` prints nothing.
- [ ] Final diffs against the baseline: `mise dot status` and `mise bootstrap plan` show no change. `mise tasks ls`
  shows the baseline's tasks minus the `bootstrap:*`, `backup*`, `reinstall:audit` and `setup` entries, plus `dots`.
- [ ] Containers: set `DOCKER_HOST` from `docker context inspect`. For `d` in `debian ubuntu`, run
  `mise run build --local --distro $d`, then
  `mise run test --image dots:$d-local --config distros/$d/container-structure-test.yml`. Expected: both pass.
- [ ] **Owner checkpoint.** Save the output of `mise run dots --help`, `mise run dots setup --help`,
  `(cd ~ && mise bootstrap --dry-run)` and `mise run dots setup --dry-run`, open each, and list them by path. Ask the
  owner to:
  1. read the help output
  2. run `mise bootstrap` twice on this Mac, and share `~/.local/state/dots/logs/latest.log`

  On the second run every step with an up-to-date check must skip, with no warnings beyond the baseline. Wait for the
  answer.
- [ ] After the owner answers: `lida done awGX` and `lida done siXn`. Commit `TODO.yaml` as
  `chore(todo): Close the bootstrap tasks and dots front door work`.
- [ ] `/wip:handoff`. No push, no PR.

**Definition of done:**
- Every task's checks pass.
- Both baseline diffs are empty.
- The owner checkpoint is answered and both lida tasks are Done.
- The only remaining uncommitted file is the owner's untracked `.env.sh`.
