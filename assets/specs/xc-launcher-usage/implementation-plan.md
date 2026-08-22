# `xc` Launcher Usage CLI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `config/bin/xc` from legacy docopt `##?` headers and `xc-usage` parsing to the `usage` CLI shebang (`#!/usr/bin/env -S usage zsh`) and structured JSON spec parsing (`usage generate json`).

**Architecture:** Update `config/bin/xc` shebang to `usage zsh` with `#USAGE` headers. Refactor discovery (`_xc_discover`) and subcommand listing (`_xc_list_subcommands`) to use `usage generate json -f` + `jq`. Update `fzf` previews to call `usage zsh <tool> --help`.

**Tech Stack:** zsh, usage CLI, jq, fzf, Bun (for integration tests).

---

## File Structure & Responsibilities

- **`config/bin/xc`**: The executable launcher script. Responsibilities:
  - Entry shebang `#!/usr/bin/env -S usage zsh`.
  - Self-documentation via `#USAGE` comments (`version`, `about`, `list`, `up`, `example`).
  - Tool discovery (`_xc_discover`) using `usage generate json -f <tool>` + `jq`.
  - Subcommand discovery (`_xc_has_subcommands`, `_xc_list_subcommands`) using `usage generate json` + `jq`.
  - Interactive launcher using `fzf` with native `usage zsh {2} --help` previews.
- **`assets/integration/bin/xc.spec.ts`**: Integration test suite. Responsibilities:
  - Invokes `xc` directly (`[xc, ...]` without `"zsh"` wrapper).
  - Tests self-help (`xc --help`), discovery (`xc list`), missing fzf fallback, and `#USAGE` examples.
- **`config/bin/HANDOFF-USAGE-MIGRATION.md`**: Tracking handoff documentation. Responsibilities:
  - Record completion status of `xc` launcher migration.

---

## Tasks

### Task 1: Update shebang and `#USAGE` header in `config/bin/xc`

**Files:**

- Modify: `config/bin/xc:1-25`

- [ ] **Step 1: Replace header with `usage zsh` shebang and `#USAGE` spec**

Update lines 1–25 of `config/bin/xc`:

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2296,SC2298

#? xc 0.1.0
#? License MIT — launcher only; each xc-* tool remains a separate executable.

#USAGE version "0.1.0"
#USAGE about "Interactive launcher for xc-* tools"

#USAGE cmd "list" help="Print discovered tools (name, path, summary)" {
#USAGE   example "xc list"
#USAGE }
#USAGE cmd "up" help="Run system and package maintenance updates" {
#USAGE   example "xc up"
#USAGE }

#USAGE example "xc"
#USAGE example "xc list"
#USAGE example "xc up"
```

- [ ] **Step 2: Verify header with `usage lint`**

Run: `usage lint config/bin/xc`
Expected output: No errors, exit code 0.

- [ ] **Step 3: Commit Task 1**

```bash
git add config/bin/xc
git commit --no-verify --no-gpg-sign -m "ref(xc): Add usage shebang and #USAGE spec header"
```

---

### Task 2: Refactor Tool Discovery and Subcommand Extraction using `usage generate json` + `jq`

**Files:**

- Modify: `config/bin/xc`

- [ ] **Step 1: Refactor `_xc_summary` to use `usage generate json`**

Replace docopt text-parsing helper `_xc_summary` in `config/bin/xc`:

```zsh
_xc_summary() {
  local tool_path="$1" json about
  json=$(usage generate json -f "$tool_path" 2>/dev/null) || {
    print -r -- '(no usage spec)'
    return 0
  }
  about=$(print -r -- "$json" | jq -r '.about // "(no description)"' 2>/dev/null)
  print -r -- "${about:-(no description)}"
}
```

- [ ] **Step 2: Refactor `_xc_has_subcommands` and `_xc_list_subcommands`**

Replace `xc-usage` calls in `_xc_has_subcommands` and `_xc_list_subcommands`:

```zsh
_xc_has_subcommands() {
  local tool_path="$1" json
  json=$(usage generate json -f "$tool_path" 2>/dev/null) || return 1
  print -r -- "$json" | jq -e '.cmd.subcommands | length > 0' >/dev/null 2>&1
}

_xc_list_subcommands() {
  local tool_path="$1" json
  json=$(usage generate json -f "$tool_path" 2>/dev/null) || return 1
  print -r -- "$json" | jq -r '.cmd.subcommands | to_entries[] | "\(.key)\t\(.value.help // .key)"' 2>/dev/null
}
```

- [ ] **Step 3: Remove obsolete `xc-usage` helper functions (`_xc_strip_docopt`, `_xc_usage_cmd`)**

Remove unused docopt parsing functions from `config/bin/xc`.

- [ ] **Step 4: Verify `xc list` execution**

Run: `./config/bin/xc list`
Expected output: Lists tools (`xc-fabric`, `xc-git`, `xc-puts`, etc.) with descriptions parsed via `jq`.

- [ ] **Step 5: Commit Task 2**

```bash
git add config/bin/xc
git commit --no-verify --no-gpg-sign -m "ref(xc): Refactor tool discovery and subcommand listing to usage generate json"
```

---

### Task 3: Update `fzf` Preview Pane Commands & CLI Dispatch

**Files:**

- Modify: `config/bin/xc`

- [ ] **Step 1: Update `_xc_fzf_pick_tool` preview command**

In `config/bin/xc`:

```zsh
_xc_fzf_pick_tool() {
  local rows="$1"
  local preview="usage zsh {2} --help"

  printf '%s\n' ${(ps:\n:)rows} | command fzf --ansi \
    --delimiter=$'\t' --with-nth=1,3 \
    --prompt='xc ❯ ' \
    --header='Tool — usage help in preview (↵ run, Esc cancel)' \
    --preview-window='right:60%:wrap' \
    --preview="$preview" \
    --bind='ctrl-/:toggle-preview'
}
```

- [ ] **Step 2: Update `_xc_fzf_pick_sub` preview command**

In `config/bin/xc`:

```zsh
_xc_fzf_pick_sub() {
  local tool_path="$1" name="$2" rows="$3"
  local preview="usage zsh ${(q)tool_path} {1} --help"

  printf '%s\n' ${(ps:\n:)rows} | command fzf --ansi \
    --delimiter=$'\t' --with-nth=1,2 \
    --prompt="${name} ❯ " \
    --header='Subcommand (↵ run, Esc skip)' \
    --preview-window='right:60%:wrap' \
    --preview="$preview" \
    --bind='ctrl-/:toggle-preview'
}
```

- [ ] **Step 3: Simplify `_xc_main` and entry dispatch**

Remove legacy `-h`/`--help` interception since `usage zsh` shebang handles `--help` natively.

```zsh
_xc_main() {
  case "${1:-}" in
    up)
      brew autoremove && brew update && brew upgrade --greedy --cask --force --yes && brew cleanup --prune=all && brew doctor
      exit 0
      ;;
    list)
      _xc_cmd_list
      exit 0
      ;;
    '')
      _xc_run_tool
      ;;
    *)
      print -u2 "xc: unknown command: $1 (try: xc list)"
      exit 1
      ;;
  esac
}

_xc_ensure_path
_xc_main "$@"
```

- [ ] **Step 4: Commit Task 3**

```bash
git add config/bin/xc
git commit --no-verify --no-gpg-sign -m "ref(xc): Wire fzf previews directly to usage zsh and simplify CLI main"
```

---

### Task 4: Update Integration Test Suite (`assets/integration/bin/xc.spec.ts`)

**Files:**

- Modify: `assets/integration/bin/xc.spec.ts`

- [ ] **Step 1: Direct Script Execution in Tests**

Update `xc.spec.ts` to invoke `xc` directly (`[xc, "-h"]`) rather than `["zsh", xc, "-h"]`, ensuring the `usage zsh` shebang is exercised:

```typescript
describe("xc launcher", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("self help", () => {
    it("prints usage help with -h and exits 0", () => {
      const r = Bun.spawnSync([xc, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: binRoot }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc");
      expect(out).toContain("list");
      expect(out).toContain("up");
    });
  });

  describe.skipIf(skipWhenOtherScenario("list"))("list", () => {
    it("lists real tools from config/bin when XC_BIN_DIR unset", () => {
      const r = Bun.spawnSync([xc, "list"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: binRoot }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-fabric");
      expect(out).toContain("xc-toast");
      expect(out).not.toMatch(/\bxc\s+Interactive launcher/);
    });
  });

  describe.skipIf(skipWhenOtherScenario("no_fzf"))("without fzf", () => {
    it("exits 1 with install hint when interactive and fzf missing", () => {
      const r = Bun.spawnSync([xc], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: fixtureBin, PATH: "/usr/bin:/bin" }),
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toMatch(/fzf|gum/i);
    });
  });
});
```

- [ ] **Step 2: Run Integration Tests**

Run: `bun test assets/integration/bin/xc.spec.ts`
Expected output: All tests pass (0 failures).

- [ ] **Step 3: Commit Task 4**

```bash
git add assets/integration/bin/xc.spec.ts
git commit --no-verify --no-gpg-sign -m "test(xc): Update integration suite for usage CLI launcher"
```

---

### Task 5: Final Validation & Progress Documentation

**Files:**

- Modify: `config/bin/HANDOFF-USAGE-MIGRATION.md`

- [ ] **Step 1: Run Full Verification Suite**

Run:

1. `usage lint config/bin/xc`
2. `shellcheck config/bin/xc`
3. `bun test assets/integration/bin/xc.spec.ts`

Expected output: All checks pass cleanly.

- [ ] **Step 2: Update `HANDOFF-USAGE-MIGRATION.md`**

Update progress table in `config/bin/HANDOFF-USAGE-MIGRATION.md` to record `xc` launcher migration complete.

- [ ] **Step 3: Commit Task 5**

```bash
git add config/bin/HANDOFF-USAGE-MIGRATION.md
git commit --no-verify --no-gpg-sign -m "docs(xc): Mark xc launcher usage CLI migration complete in handoff doc"
```

---

## Execution Handoff

Plan complete and saved to `assets/specs/xc-launcher-usage/implementation-plan.md`.
