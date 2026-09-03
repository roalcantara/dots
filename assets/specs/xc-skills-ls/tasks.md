# Implementation Tasks: `xc-skills ls`

## Task 1: Add Clipboard Helper & USAGE Header for `ls`

- [ ] Add `#USAGE cmd "ls"` block to `config/bin/xc-skills` header.
- [ ] Add `_copy_to_clipboard` helper and `__clip` internal handler to `config/bin/xc-skills`.
- [ ] Verify with `usage lint config/bin/xc-skills`.

## Task 2: Implement `cmd_ls` in `config/bin/xc-skills`

- [ ] Parse flags: `-s/--source`, `-l/--local`, `-r/--raw`.
- [ ] Discover skill directories from resolved source path.
- [ ] Handle non-interactive / `--raw` output mode.
- [ ] Launch `fzf` with preview pipeline, multi-select, and keybindings (`ctrl-o`, `ctrl-n`, `ctrl-p`, `ctrl-u`).
- [ ] Wire top-level `main` dispatch for `ls` subcommand.

## Task 3: Automated Integration Tests

- [ ] Add `assets/integration/bin/xc-skills.spec.ts` test cases:
  - `xc-skills ls -h` / `--help` (exits 0, shows about and examples).
  - `xc-skills ls --raw` (lists skills from temp directory).
  - `xc-skills ls -l --raw` (lists skills from project-local directory).
  - `xc-skills ls -s <dir> --raw` (lists skills from custom directory).
  - Missing directory error handling (exits 1).
  - Empty directory handling (exits 0 with message).
- [ ] Run `bun test assets/integration/bin/xc-skills.spec.ts` and `shellcheck config/bin/xc-skills`.

## Task 4: Documentation & Final Verification

- [ ] Update `config/bin/README.md` and `config/bin/HANDOFF-USAGE-MIGRATION.md`.
- [ ] Verify full test suite passes.
