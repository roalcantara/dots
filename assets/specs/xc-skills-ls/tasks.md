# Implementation Tasks: `xc-skills ls`

## Task 1: Add Clipboard Helper & USAGE Header for `ls`

- [x] Add `#USAGE cmd "ls"` block to `config/bin/xc-skills` header.
- [x] Add `_copy_to_clipboard` helper and `__clip` internal handler to `config/bin/xc-skills`.
- [x] Verify with `usage lint config/bin/xc-skills`.

## Task 2: Implement `cmd_ls` in `config/bin/xc-skills`

- [x] Parse flags: `-s/--source`, `-l/--local`, `-r/--raw`.
- [x] Discover skill directories from resolved source path.
- [x] Handle non-interactive / `--raw` output mode.
- [x] Launch `fzf` with preview pipeline, multi-select, and keybindings (`ctrl-o`, `ctrl-n`, `ctrl-p`, `ctrl-u`).
- [x] Wire top-level `main` dispatch for `ls` subcommand.

## Task 3: Automated Integration Tests

- [x] Add `assets/integration/bin/xc-skills.spec.ts` test cases:
  - `xc-skills ls -h` / `--help` (exits 1 with usage text).
  - `xc-skills ls --raw` (lists skills from temp directory).
  - `xc-skills ls -l --raw` (lists skills from project-local directory).
  - `xc-skills ls -s <dir> --raw` (lists skills from custom directory).
  - Missing directory error handling (exits 1).
  - Empty directory handling (exits 0 with message).
- [x] Run `bun test assets/integration/bin/xc-skills.spec.ts` and `shellcheck config/bin/xc-skills`.

## Task 4: Documentation & Final Verification

- [x] Update `config/bin/README.md` and `config/bin/HANDOFF-USAGE-MIGRATION.md`.
- [x] Verify full test suite passes.
