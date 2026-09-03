# USAGE CLI Migration for `config/bin` Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `xc-md`, `xc-puts`, `xc-toast`, `xc-skills`, and `xc-git` from legacy `##?` docopt comments and `xc-usage` parsing to the native USAGE CLI shebang (`usage zsh`/`usage bash`) and `#USAGE` specifications.

**Architecture:** Each script declares its version, about text, arguments, flags, subcommands, and examples using `#USAGE` comments at the head of the file. The `usage` binary runtime automatically intercepts `-h`/`--help` and exports arguments as `usage_*` variables. Tests invoke binaries directly and verify each `#USAGE example`.

**Tech Stack:** `usage` CLI, `zsh`, `bash`, `bun:test` (for integration specs in `assets/integration/bin/`), `shellcheck`.

---

## Task 1: Migrate `config/bin/xc-md` (Tier 1: Minimal Stdin Pipe)

**Files:**
- Modify: `config/bin/xc-md`
- Test: `assets/integration/bin/xc-md.spec.ts`

- [x] **Step 1: Update integration test to verify direct invocation and examples**

Update `assets/integration/bin/xc-md.spec.ts` to test all documented `#USAGE example` cases and direct binary execution.

```typescript
#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcMd = scriptPath("xc-md");

describe("xc-md", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given -h or --help", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([xcMd, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-md");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([xcMd, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-md");
    });
  });

  describe.skipIf(skipWhenOtherScenario("stdin"))("when given markdown on stdin", () => {
    it("renders piped markdown and exits 0", () => {
      const r = Bun.spawnSync([xcMd], {
        stdin: new TextEncoder().encode("# Title\n\nHello, world!\n"),
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out.length).toBeGreaterThan(0);
    });
  });
});
```

- [x] **Step 2: Update `config/bin/xc-md` to use USAGE**

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? dots 0.1.0
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Render markdown from stdin: glow → bat → plain"
#USAGE example "xc-md < input.md"
#USAGE example "echo '# Title' | xc-md"
#USAGE example "xc-usage <target> --md"

emulate -L zsh
setopt no_unset pipe_fail

if command -v glow >/dev/null 2>&1; then
  glow - 2>/dev/null || cat
elif command -v bat >/dev/null 2>&1; then
  bat -l md --paging=never 2>/dev/null || cat
else
  cat
fi
exit 0
```

- [x] **Step 3: Run tests and usage lint**

Run:
```bash
usage lint config/bin/xc-md
bun test assets/integration/bin/xc-md.spec.ts
```
Expected: PASS (all tests pass, 0 lint errors).

- [x] **Step 4: Commit**

```bash
git add config/bin/xc-md assets/integration/bin/xc-md.spec.ts
git commit -m "ref(xc-md): Adopt usage CLI for help and completions"
```

---

## Task 2: Migrate `config/bin/xc-puts` (Tier 1: Flat Output Formatter)

**Files:**
- Modify: `config/bin/xc-puts`
- Modify: `assets/integration/bin/xc-puts.spec.ts`

- [x] **Step 1: Update integration test to verify direct invocation and all examples**

Ensure `assets/integration/bin/xc-puts.spec.ts` executes `[xcPuts, ...]` directly (not `["zsh", xcPuts, ...]`) and tests:
- `--help` / `-h` exits 0.
- Missing message exits 1 with usage on stderr.
- Flags: `--green`, `--red`, `--yellow`, `--prefix`, `--warn`.

- [x] **Step 2: Update `config/bin/xc-puts` with USAGE**

Replace `zparseopts` and `_xc_usage_find` with:
```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? puts 0.1.0
#? Copyright (C) 200X Thomas Light
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Formats and prints a message"
#USAGE arg "[message]" help="The text message to print"
#USAGE flag "-p --prefix <prefix>" help="Print message with prefix"
#USAGE flag "-g --green" help="Print message in green"
#USAGE flag "-r --red" help="Print message in red"
#USAGE flag "-y --yellow" help="Print message in yellow"
#USAGE flag "-b --blue" help="Print message in blue"
#USAGE flag "-d --debug" help="Print log message in debug"
#USAGE flag "-e --error" help="Print log message in error"
#USAGE flag "-f --fatal" help="Print log message in fatal"
#USAGE flag "-i --info" help="Print log message in info"
#USAGE flag "-w --warn" help="Print log message in warn"
#USAGE example "xc-puts --green 'Success!'"
#USAGE example "xc-puts --red 'Error!'"
#USAGE example "xc-puts --yellow 'Warning!'"
#USAGE example "xc-puts --prefix 'SETUP' 'Message!'"
#USAGE example "xc-puts --prefix 'SETUP' --warn 'Message!'"

emulate -L zsh
setopt no_unset pipe_fail

if [[ -z "${usage_message:-}" ]]; then
  usage zsh "${0:a}" --help >&2
  exit 1
fi

local message="$usage_message"
local prefix_value="${usage_prefix:-}"
local level=""
local color=""
local zsh_color=""

if [[ -n "${usage_debug:-}" ]]; then
  level="debug"
elif [[ -n "${usage_error:-}" ]]; then
  level="error"
elif [[ -n "${usage_fatal:-}" ]]; then
  level="fatal"
elif [[ -n "${usage_info:-}" ]]; then
  level="info"
elif [[ -n "${usage_warn:-}" ]]; then
  level="warn"
fi

if [[ -n "${usage_green:-}" || -n "${usage_debug:-}" ]]; then
  color="#04B575"
  zsh_color="%F{green}"
elif [[ -n "${usage_red:-}" || -n "${usage_error:-}" || -n "${usage_fatal:-}" ]]; then
  color="#F44336"
  zsh_color="%F{red}"
elif [[ -n "${usage_yellow:-}" || -n "${usage_warn:-}" ]]; then
  color="#F4AC45"
  zsh_color="%F{yellow}"
elif [[ -n "${usage_blue:-}" || -n "${usage_info:-}" ]]; then
  color="#2196F3"
  zsh_color="%F{blue}"
fi

if command -v gum >/dev/null 2>&1; then
  if [[ -n "$level" ]]; then
    if [[ -n "$prefix_value" ]]; then
      gum log --time DateTime --level "$level" --prefix="$prefix_value" "$message"
    else
      gum log --time DateTime --level "$level" "$message"
    fi
  else
    if [[ -n "$prefix_value" ]]; then
      gum style --foreground "$color" --prefix "$prefix_value" "$message"
    else
      gum style --foreground "$color" "$message"
    fi
  fi
  exit 0
fi

if [[ -n "$level" ]]; then
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local level_upper=$(echo "$level" | tr '[:lower:]' '[:upper:]')
  if [[ -n "$prefix_value" ]]; then
    print -P "%F{white}${timestamp}%f ${zsh_color}${level_upper}%f %F{gray}${prefix_value}:%f ${message}"
  else
    print -P "%F{white}${timestamp}%f ${zsh_color}${level_upper}%f ${message}"
  fi
else
  if [[ -n "$zsh_color" ]]; then
    print -P "${zsh_color}${message}%f"
  else
    print "$message"
  fi
fi
```

- [x] **Step 3: Run tests and usage lint**

Run:
```bash
usage lint config/bin/xc-puts
bun test assets/integration/bin/xc-puts.spec.ts
```
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add config/bin/xc-puts assets/integration/bin/xc-puts.spec.ts
git commit -m "ref(xc-puts): Adopt usage CLI for help and completions"
```

---

## Task 3: Migrate `config/bin/xc-toast` (Tier 1: Positional & Flag Notification)

**Files:**
- Modify: `config/bin/xc-toast`
- Modify: `assets/integration/bin/xc-toast.spec.ts`

- [x] **Step 1: Update integration test to verify direct invocation and all examples**

Update `assets/integration/bin/xc-toast.spec.ts` to execute `[xcToast, ...]` directly without `zsh` wrapper.

- [x] **Step 2: Update `config/bin/xc-toast` with USAGE**

```zsh
#!/usr/bin/env -S usage zsh
# shellcheck shell=bash disable=SC2154

#? toast 0.1.0
#? License RIT (Robot Institute of Technology)
#? This is free software: you are free to change and redistribute it.
#? There is NO WARRANTY, to the extent permitted by law.

#USAGE version "0.1.0"
#USAGE about "Display a terminal toast notification overlay"
#USAGE arg "[message]" help="The message to display"
#USAGE arg "[duration_pos]" help="The duration of the toast in seconds"
#USAGE arg "[type_pos]" help="The type of toast to display (info|success|error|warning)"
#USAGE flag "-d --duration <duration>" help="Duration in seconds" default="3"
#USAGE flag "-t --type <type>" help="Type of toast (info|success|error|warning)" default="info"
#USAGE example "xc-toast 'Hello, world!'"
#USAGE example "xc-toast 'Hello, world!' 5"
#USAGE example "xc-toast 'Hello, world!' 5 error"
#USAGE example "xc-toast 'Process started' -d 3 -t info"

emulate -L zsh
setopt no_unset pipe_fail

if [[ -z "${usage_message:-}" ]]; then
  usage zsh "${0:a}" --help >&2
  exit 1
fi

local message="$usage_message"
local duration="${usage_duration_pos:-${usage_duration:-3}}"
local type="${usage_type_pos:-${usage_type:-info}}"

local bg fg icon
case "$type" in
  success)
    bg="\e[42m" fg="\e[37m" icon="✓"
    ;;
  error)
    bg="\e[41m" fg="\e[37m" icon="✗"
    ;;
  warning)
    bg="\e[43m" fg="\e[30m" icon="!"
    ;;
  *)  # info
    bg="\e[44m" fg="\e[37m" icon="i"
    ;;
esac

local reset="\e[0m"
tput sc
tput cup 0 $(($(tput cols) - ${#message} - 6))
echo -n "${bg}${fg} ${icon} ${message} ${reset}"
tput rc

(
  sleep "$duration"
  tput sc
  tput cup 0 $(($(tput cols) - ${#message} - 6))
  printf ' %.0s' $(seq 1 $((${#message} + 6)))
  tput rc
) &!
```

- [x] **Step 3: Run tests and usage lint**

Run:
```bash
usage lint config/bin/xc-toast
bun test assets/integration/bin/xc-toast.spec.ts
```
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add config/bin/xc-toast assets/integration/bin/xc-toast.spec.ts
git commit -m "ref(xc-toast): Adopt usage CLI for help and completions"
```

---

## Task 4: Migrate `config/bin/xc-skills` (Tier 2: Multi-Command Bash Dispatcher)

**Files:**
- Modify: `config/bin/xc-skills`
- Modify: `assets/integration/bin/xc-skills.spec.ts`

- [x] **Step 1: Update integration test to verify direct invocation and all examples**

Ensure `assets/integration/bin/xc-skills.spec.ts` invokes `[script, ...]` directly, verifying `sync` and `collect` commands with `--dry-run`, `-a`, `-t`, `-s`, etc.

- [x] **Step 2: Update `config/bin/xc-skills` with USAGE**

- Change shebang to `#!/usr/bin/env -S usage bash`.
- Add `#USAGE cmd "sync"` and `#USAGE cmd "collect"` headers.
- Update `usage()` to call `usage bash "$SCRIPT_PATH" --help`.
- Remove all `##?` docopt blocks.

- [x] **Step 3: Run tests and usage lint**

Run:
```bash
usage lint config/bin/xc-skills
bun test assets/integration/bin/xc-skills.spec.ts
```
Expected: PASS (all 38 tests pass).

- [x] **Step 4: Commit**

```bash
git add config/bin/xc-skills assets/integration/bin/xc-skills.spec.ts
git commit -m "ref(xc-skills): Adopt usage CLI for help and completions"
```

---

## Task 5: Migrate `config/bin/xc-git` (Tier 2: Multi-Command Zsh Dispatcher)

**Files:**
- Modify: `config/bin/xc-git`
- Modify: `assets/integration/bin/xc-git.spec.ts`

- [x] **Step 1: Update integration test to verify direct invocation and subcommands**

Ensure `assets/integration/bin/xc-git.spec.ts` invokes `[script, ...]` directly and verifies `branch-preview`, `fixup-suggest`, and `log-fzf`.

- [x] **Step 2: Update `config/bin/xc-git` with USAGE**

- Change shebang to `#!/usr/bin/env -S usage zsh`.
- Add `#USAGE cmd "branch-preview"`, `#USAGE cmd "fixup-suggest"`, `#USAGE cmd "log-fzf"` headers.
- Remove `_xc_git_xc_usage`, `_xc_git_subhelp`, and all `##?` docopt blocks.
- Update top-level dispatch to use `usage zsh "${0:a}" --help >&2`.

- [x] **Step 3: Run tests and usage lint**

Run:
```bash
usage lint config/bin/xc-git
bun test assets/integration/bin/xc-git.spec.ts
```
Expected: PASS (all tests pass).

- [x] **Step 4: Commit**

```bash
git add config/bin/xc-git assets/integration/bin/xc-git.spec.ts
git commit -m "ref(xc-git): Adopt usage CLI for help and completions"
```

---

## Task 6: Comprehensive Quality Gate & Documentation Sync

**Files:**
- Modify: `config/bin/README.md`
- Modify: `config/bin/HANDOFF-USAGE-MIGRATION.md`

- [x] **Step 1: Run whole-suite quality checks**

Run:
```bash
usage lint config/bin/xc-md config/bin/xc-puts config/bin/xc-toast config/bin/xc-skills config/bin/xc-git
shellcheck config/bin/xc-md config/bin/xc-puts config/bin/xc-toast config/bin/xc-skills config/bin/xc-git
bun test assets/integration/bin/xc-md.spec.ts assets/integration/bin/xc-puts.spec.ts assets/integration/bin/xc-toast.spec.ts assets/integration/bin/xc-skills.spec.ts assets/integration/bin/xc-git.spec.ts
```
Expected: All checks PASS with zero errors.

- [x] **Step 2: Update documentation**

Update progress tables in `config/bin/HANDOFF-USAGE-MIGRATION.md` and `config/bin/README.md`.

- [x] **Step 3: Commit**

```bash
git add config/bin/README.md config/bin/HANDOFF-USAGE-MIGRATION.md
git commit -m "docs(bin): Update usage migration status for xc-* tools"
```
