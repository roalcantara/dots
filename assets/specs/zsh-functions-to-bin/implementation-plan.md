# Zsh Functions to `config/bin/` Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port all 12 shell functions in `config/zsh/etc/functions/` (`barrel`, `recase`, `toast`, `yw`, `keyring`, `psc`, `pss`, `gen`, `zsys`, `dots`, `osx`, `gitx`) to standalone executable scripts in `config/bin/`.

**Architecture:** Each script is built as a self-contained executable on `$PATH` using the Usage CLI shebang (`#!/usr/bin/env -S usage zsh` or `usage bash`) with `#USAGE` headers for auto-generated `--help` and argument validation. User interfaces, prompts, logs, spinners, and menus leverage Charm Gum (`gum log`, `gum style`, `gum choose`, `gum filter`, `gum spin`, `gum confirm`, `gum input`) with non-TTY fallbacks.

**Tech Stack:** Usage CLI, Charm Gum, Zsh/Bash, Bun (`bun:test`), ShellCheck.

---

## File Structure & Touch Points

```
config/
├── bin/
│   ├── barrel            (NEW: TypeScript/JavaScript barrel export generator)
│   ├── recase            (NEW: file/directory casing converter)
│   ├── toast             (NEW / UNIFIED: terminal toast notification overlay)
│   ├── yw                (NEW: Yarn workspace interactive package/script runner)
│   ├── keyring           (NEW: agnostic macOS/Linux keychain manager)
│   ├── psc               (NEW: Gopass secret clipboard copier)
│   ├── pss               (NEW: Gopass secret revealer and exporter)
│   ├── gen               (NEW: Zsh completion generator from --help)
│   ├── zsys              (NEW: environment, path, and diagnostic utility)
│   ├── dots              (NEW: dotfiles manager and diagnostics)
│   ├── osx               (NEW: macOS maintenance and services CLI)
│   └── gitx              (NEW: git workflows and rebase helper dispatcher)
└── zsh/
    ├── etc/functions/    (DELETED: all 12 legacy functions removed on cutover)
    ├── .zimrc            (MODIFIED: update function autoloading)
    └── README.md         (MODIFIED: update documentation)

assets/
└── integration/
    └── bin/
        ├── barrel.spec.ts  (NEW: integration test)
        ├── recase.spec.ts  (NEW: integration test)
        ├── toast.spec.ts   (NEW: integration test)
        ├── yw.spec.ts      (NEW: integration test)
        ├── keyring.spec.ts (NEW: integration test)
        ├── psc.spec.ts     (NEW: integration test)
        ├── pss.spec.ts     (NEW: integration test)
        ├── gen.spec.ts     (NEW: integration test)
        ├── zsys.spec.ts    (NEW: integration test)
        ├── dots.spec.ts    (NEW: integration test)
        ├── osx.spec.ts     (NEW: integration test)
        └── gitx.spec.ts    (NEW: integration test)
```

---

## Phase 1: Tier 1 — Flat Utilities & Interactive Pickers

### Task 1: Port `barrel` to `config/bin/barrel`

**Files:**
- Create: `config/bin/barrel`
- Create: `assets/integration/bin/barrel.spec.ts`

- [ ] **Step 1: Write the failing integration test**

```typescript
// assets/integration/bin/barrel.spec.ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("barrel");

describe("barrel", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("Usage");
      expect(new TextDecoder().decode(r.stdout)).toContain("barrel");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("Usage");
    });

    it("exits with status 1 when required folder is missing", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test assets/integration/bin/barrel.spec.ts`
Expected: FAIL (command not found or exit code mismatch)

- [ ] **Step 3: Implement `config/bin/barrel`**

```zsh
#!/usr/bin/env -S usage bash
# shellcheck shell=bash disable=SC2154

#? barrel 0.1.0
#? License RIT (Robot Institute of Technology)

#USAGE version "0.1.0"
#USAGE about "Automatically generate and maintain barrel (index) exports"
#USAGE arg "<folder>" help="Target folder containing modules"
#USAGE flag "-r --recursive" help="Include index exports from subdirectories"
#USAGE flag "-t --ts" help="Use .ts extension for exports (default)" default="true"
#USAGE flag "-j --js" help="Use .js extension for exports"
#USAGE example "barrel ./src"
#USAGE example "barrel ./src -r"

set -euo pipefail

FOLDER="${usage_folder:-}"
RECURSIVE="${usage_recursive:-false}"
EXT="ts"
[[ "${usage_js:-false}" == "true" ]] && EXT="js"

if [[ -z "$FOLDER" || ! -d "$FOLDER" ]]; then
  echo "Error: Directory '$FOLDER' does not exist" >&2
  exit 1
fi

_log_info() {
  if command -v gum &>/dev/null && [[ -t 1 ]]; then
    gum log --level info "$1"
  else
    echo "✔ [INFO] $1"
  fi
}

INDEX_FILE="$FOLDER/index.$EXT"
EXPORTS=()

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  base=$(basename "$f" | sed -E "s/\.(ts|js)$//")
  [[ "$base" == "index" ]] && continue
  EXPORTS+=("export * from './$base.$EXT'")
done < <(find "$FOLDER" -maxdepth 1 -type f \( -name "*.ts" -o -name "*.js" \) ! -name "index.*" ! -name "*.spec.*" ! -name "*.test.*" | sort)

if [[ ${#EXPORTS[@]} -gt 0 ]]; then
  printf "%s\n" "${EXPORTS[@]}" > "$INDEX_FILE"
  _log_info "Saved barrel exports to $INDEX_FILE"
fi
```

- [ ] **Step 4: Make executable and verify tests and lint pass**

```bash
chmod +x config/bin/barrel
usage lint config/bin/barrel
bun test assets/integration/bin/barrel.spec.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add config/bin/barrel assets/integration/bin/barrel.spec.ts
git commit -m "feat(bin): Add barrel CLI with usage and gum"
```

---

### Task 2: Port `recase` to `config/bin/recase`

**Files:**
- Create: `config/bin/recase`
- Create: `assets/integration/bin/recase.spec.ts`

- [ ] **Step 1: Write the failing integration test**

```typescript
// assets/integration/bin/recase.spec.ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("recase");

describe("recase", () => {
  it("prints usage with -h and exits 0", () => {
    const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout)).toContain("recase");
  });

  it("exits with status 1 when target path is missing", () => {
    const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test assets/integration/bin/recase.spec.ts`
Expected: FAIL

- [ ] **Step 3: Implement `config/bin/recase`**

Port `config/zsh/etc/functions/recase` to `config/bin/recase` using `#!/usr/bin/env -S usage zsh`, `#USAGE` argument definitions (`arg "<path>"`, `flag "-f --files"`, `flag "-d --dirs"`, `flag "-r --recursive"`, `flag "--snake"`, `flag "--kebab"`, `flag "--camel"`, `flag "--pascal"`, `flag "--upper"`, `flag "--lower"`, `flag "--title"`), and `gum log` / `gum style` for visual rename feedback.

- [ ] **Step 4: Make executable and verify tests and lint pass**

```bash
chmod +x config/bin/recase
usage lint config/bin/recase
bun test assets/integration/bin/recase.spec.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add config/bin/recase assets/integration/bin/recase.spec.ts
git commit -m "feat(bin): Add recase CLI with usage and gum"
```

---

### Task 3: Unify and Port `toast` to `config/bin/toast`

**Files:**
- Create: `config/bin/toast`
- Create: `assets/integration/bin/toast.spec.ts`

- [ ] **Step 1: Write the failing integration test**

```typescript
// assets/integration/bin/toast.spec.ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("toast");

describe("toast", () => {
  it("prints usage with -h and exits 0", () => {
    const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout)).toContain("toast");
  });

  it("exits with status 1 when message is missing", () => {
    const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test assets/integration/bin/toast.spec.ts`
Expected: FAIL

- [ ] **Step 3: Implement `config/bin/toast`**

Create `config/bin/toast` adopting the `#USAGE` shebang pattern from `config/bin/xc-toast` and unifying both `xc-toast` and `ztoast`.

- [ ] **Step 4: Make executable and verify tests pass**

```bash
chmod +x config/bin/toast
usage lint config/bin/toast
bun test assets/integration/bin/toast.spec.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add config/bin/toast assets/integration/bin/toast.spec.ts
git commit -m "feat(bin): Add unified toast CLI with usage"
```

---

### Task 4: Port `yw` to `config/bin/yw`

**Files:**
- Create: `config/bin/yw`
- Create: `assets/integration/bin/yw.spec.ts`

- [ ] **Step 1: Write the failing integration test**

```typescript
// assets/integration/bin/yw.spec.ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("yw");

describe("yw", () => {
  it("prints usage with -h and exits 0", () => {
    const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout)).toContain("yw");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test assets/integration/bin/yw.spec.ts`
Expected: FAIL

- [ ] **Step 3: Implement `config/bin/yw`**

Port `config/zsh/etc/functions/yw` to `config/bin/yw` using `usage zsh`, `#USAGE arg "[package]"`, `#USAGE arg "[script]"`, `#USAGE flag "--dry-run"`, parsing `yarn workspaces list --json` and `package.json` scripts with `jq`, and presenting `gum choose` menus before executing `yarn workspace <pkg> <script>`.

- [ ] **Step 4: Make executable and verify tests pass**

```bash
chmod +x config/bin/yw
usage lint config/bin/yw
bun test assets/integration/bin/yw.spec.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add config/bin/yw assets/integration/bin/yw.spec.ts
git commit -m "feat(bin): Add yw Yarn workspace CLI with usage and gum"
```

---

## Phase 2: Tier 2 — Credentials & Secrets Management

### Task 5: Port `keyring` to `config/bin/keyring`

**Files:**
- Create: `config/bin/keyring`
- Create: `assets/integration/bin/keyring.spec.ts`

- [ ] **Step 1: Write integration tests**
- [ ] **Step 2: Verify test fails**
- [ ] **Step 3: Implement `config/bin/keyring` with `usage bash` and `#USAGE cmd` (`get`, `set`, `rm`, `list`)**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add keyring CLI with usage and gum"`

---

### Task 6: Port `psc` and `pss` to `config/bin/psc` and `config/bin/pss`

**Files:**
- Create: `config/bin/psc`
- Create: `config/bin/pss`
- Create: `assets/integration/bin/psc.spec.ts`
- Create: `assets/integration/bin/pss.spec.ts`

- [ ] **Step 1: Write integration tests for `psc` and `pss`**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `psc` and `pss` with `usage zsh`, `gopass show --clip`, and `gum filter` key selection**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add psc and pss Gopass CLIs with usage and gum"`

---

## Phase 3: Tier 3 — Generators & Shell Inspection Utilities

### Task 7: Port `gen` to `config/bin/gen`

**Files:**
- Create: `config/bin/gen`
- Create: `assets/integration/bin/gen.spec.ts`

- [ ] **Step 1: Write integration tests for `gen`**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `config/bin/gen` with `usage zsh`, `gum spin` parser, and `#compdef` file generation**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add gen completion generator CLI with usage and gum"`

---

### Task 8: Port `zsys` to `config/bin/zsys`

**Files:**
- Create: `config/bin/zsys`
- Create: `assets/integration/bin/zsys.spec.ts`

- [ ] **Step 1: Write integration tests for `zsys`**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `config/bin/zsys` with `usage zsh` and `#USAGE cmd` (`path`, `cmd`, `file`, `setup`)**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add zsys environment CLI with usage and gum"`

---

## Phase 4: Tier 4 — Complex Multi-Command Dispatchers

### Task 9: Port `dots` to `config/bin/dots`

**Files:**
- Create: `config/bin/dots`
- Create: `assets/integration/bin/dots.spec.ts`

- [ ] **Step 1: Write integration tests for `dots` subcommands**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `config/bin/dots` with `usage zsh`, `#USAGE cmd` (`env`, `path`, `fpath`, `cdpath`, `palette`, `xdg`, `setup`, `zsh`, `git`), and interactive `gum choose` fallback**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add dots CLI with usage and gum"`

---

### Task 10: Port `osx` to `config/bin/osx`

**Files:**
- Create: `config/bin/osx`
- Create: `assets/integration/bin/osx.spec.ts`

- [ ] **Step 1: Write integration tests for `osx` subcommands**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `config/bin/osx` with `usage zsh`, `#USAGE cmd` (`wifi`, `services`, `cache`, `dock`, `finder`, etc.), and `gum spin` / `gum confirm`**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add osx CLI with usage and gum"`

---

### Task 11: Port `gitx` to `config/bin/gitx`

**Files:**
- Create: `config/bin/gitx`
- Create: `assets/integration/bin/gitx.spec.ts`

- [ ] **Step 1: Write integration tests for `gitx` subcommands**
- [ ] **Step 2: Verify tests fail**
- [ ] **Step 3: Implement `config/bin/gitx` with `usage zsh`, comprehensive `#USAGE cmd` blocks, and `gum` interactive pickers**
- [ ] **Step 4: Verify tests pass with `bun test` and `usage lint`**
- [ ] **Step 5: Commit:** `git commit -m "feat(bin): Add gitx CLI with usage and gum"`

---

## Phase 5: Cleanup, Deprecation & Verification

### Task 12: Deprecate `config/zsh/etc/functions/` & Update Configuration

**Files:**
- Delete: `config/zsh/etc/functions/*` (all 12 legacy files)
- Modify: `config/zsh/.zimrc`
- Modify: `config/bin/README.md`
- Modify: `config/zsh/README.md`

- [ ] **Step 1: Remove migrated files from `config/zsh/etc/functions/`**
- [ ] **Step 2: Update `config/zsh/.zimrc` to handle autoloading cleanly**
- [ ] **Step 3: Update `config/bin/README.md` and `config/zsh/README.md` documentation**
- [ ] **Step 4: Run full integration suite gate:**
  ```bash
  bun test assets/integration/bin/
  ```
- [ ] **Step 5: Commit:** `git commit -m "ref(zsh): Remove migrated functions and update documentation"`
