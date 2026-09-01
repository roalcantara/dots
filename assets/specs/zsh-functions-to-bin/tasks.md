# TASKS: Port Zsh Autoload Functions to `config/bin/`

## Phase 1: Tier 1 — Flat Utilities & Interactive Pickers

- [ ] **Task 1.1: Port `barrel` to `config/bin/barrel`**
  - Add `usage zsh` shebang and `#USAGE` specification header.
  - Integrate `gum log` and `gum confirm` for file changes.
  - Create `assets/integration/bin/barrel.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 1.2: Port `recase` to `config/bin/recase`**
  - Add `usage zsh` shebang and `#USAGE` specification for compound and composable flags.
  - Integrate `gum log` and `gum style` for rename diffs.
  - Create `assets/integration/bin/recase.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 1.3: Unify and Port `toast` to `config/bin/toast`**
  - Consolidate `config/bin/xc-toast` and `config/zsh/etc/functions/ztoast` into `config/bin/toast`.
  - Provide symlinks/compatibility for `xc-toast` and `ztoast`.
  - Create/update `assets/integration/bin/toast.spec.ts`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 1.4: Port `yw` to `config/bin/yw`**
  - Add `usage zsh` shebang and `#USAGE` specification.
  - Replace `print -z` with direct execution and `gum choose` / `gum filter` pickers.
  - Create `assets/integration/bin/yw.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

---

## Phase 2: Tier 2 — Credentials & Secrets Management

- [ ] **Task 2.1: Port `keyring` to `config/bin/keyring`**
  - Add `usage bash` shebang and `#USAGE cmd` subcommands (`get`, `set`, `rm`, `list`).
  - Integrate `gum input --password` for missing secrets and `gum confirm` for removals.
  - Create `assets/integration/bin/keyring.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 2.2: Port `psc` to `config/bin/psc`**
  - Add `usage zsh` shebang and `#USAGE` specification.
  - Integrate `gum filter` for gopass key selection when argument is omitted.
  - Create `assets/integration/bin/psc.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 2.3: Port `pss` to `config/bin/pss`**
  - Add `usage zsh` shebang and `#USAGE` specification (`--cp`, `--export`).
  - Integrate `gum filter` for interactive key selection and `gum spin` for bulk secret exports.
  - Create `assets/integration/bin/pss.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

---

## Phase 3: Tier 3 — Generators & Shell Inspection Utilities

- [ ] **Task 3.1: Port `gen` to `config/bin/gen`**
  - Add `usage zsh` shebang and `#USAGE` specification.
  - Integrate `gum spin` during command help parsing and `gum log` on completion file write.
  - Create `assets/integration/bin/gen.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 3.2: Port `zsys` to `config/bin/zsys`**
  - Add `usage zsh` shebang and `#USAGE cmd` subcommands (`path`, `cmd`, `file`, `setup`).
  - Output clean path and setup diagnostics using `gum style`.
  - Create `assets/integration/bin/zsys.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

---

## Phase 4: Tier 4 — Complex Multi-Command Dispatchers

- [ ] **Task 4.1: Port `dots` to `config/bin/dots`**
  - Add `usage zsh` shebang and `#USAGE cmd` subcommands (`env`, `path`, `fpath`, `cdpath`, `palette`, `xdg`, `setup`, `zsh`, `git`).
  - Integrate interactive `gum choose` menu when called without arguments; add `gum log` for XDG checks.
  - Create `assets/integration/bin/dots.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 4.2: Port `osx` to `config/bin/osx`**
  - Add `usage zsh` shebang and `#USAGE cmd` subcommands (`wifi`, `services`, `systemctl`, `launchctl`, `notify`, `plist`, `cache`, `exclusions`, `sleep`, `groups`, `users`, `system_profiler`, `dock`, `finder`, `export-defaults`, `enable-locate`).
  - Integrate `gum spin`, `gum filter`, and `gum confirm`.
  - Create `assets/integration/bin/osx.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

- [ ] **Task 4.3: Port `gitx` to `config/bin/gitx`**
  - Add `usage zsh` shebang and comprehensive `#USAGE cmd` subcommands.
  - Delegate shared git helper primitives to `xc-git`.
  - Integrate `gum choose` / `gum filter` for interactive branch and commit selection.
  - Create `assets/integration/bin/gitx.spec.ts` with `bun-test`.
  - Validate with `usage lint` and `shellcheck`.

---

## Phase 5: Cleanup & Deprecation

- [ ] **Task 5.1: Remove migrated functions from `config/zsh/etc/functions/`**
- [ ] **Task 5.2: Update `config/zsh/.zimrc` and Zsh configuration**
- [ ] **Task 5.3: Update documentation in `config/bin/README.md` and `config/zsh/README.md`**
- [ ] **Task 5.4: Run full integration suite gate (`mise run -C assets test:integration`)**
