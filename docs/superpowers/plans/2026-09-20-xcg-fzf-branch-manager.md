# xcg fzf Branch Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `config/bin/xcg` as a single fzf list that opens on local branches, switches views by keystroke, and deletes, checks out or copies the selection in place.

**Architecture:** One `fzf` process that never exits until checkout or abort. Every key binds back into `xcg` through undocumented `__`-prefixed subcommands. All views emit one TSV row format, `kind<TAB>ref<TAB>display`, where fields 1–2 are hidden from fzf by `--with-nth=3..` but passed to actions as `{1}`/`{2}` — so each row carries its own kind and no view state has to be threaded into an action. The usage framework is dropped; dispatch is a plain `case` and help is a heredoc.

**Tech Stack:** zsh, git ≥2.36 (`for-each-ref --exclude`), fzf ≥0.38 (`become`), gum (confirmations), Bun test (integration specs).

**Spec:** [`docs/superpowers/specs/2026-09-20-xcg-fzf-branch-manager-design.md`](../specs/2026-09-20-xcg-fzf-branch-manager-design.md)

---

## Verified facts

These were confirmed against a real fixture repo before this plan was written. Trust them rather than re-deriving:

- `status` **is a read-only variable in zsh** (it aliases `$?`). Assigning `local status` inside a function fails at runtime with `read-only variable: status`. Use `mark` or any other name.
- `git for-each-ref refs/remotes` includes a bare `origin` row — that is `refs/remotes/origin/HEAD` shortened. Filter it with `--exclude='refs/remotes/*/HEAD'`.
- `%(upstream:track,nobracket)` yields bare `gone` / `ahead 1` / `ahead 1, behind 2` / empty — no bracket stripping needed.
- `git for-each-ref --merged <branch> refs/heads` **includes the branch itself**, so the protected filter is what excludes it.
- fzf applies `--nth` *after* `--with-nth` transforms the line. Passing both `--with-nth=3..` and `--nth=3..` matches nothing. Pass `--with-nth=3..` only; it already makes fields 1–2 unsearchable.
- `usage` supports `hide=#true`, but usage is being removed entirely, so this is moot.

## File structure

| File | Responsibility |
| ---- | -------------- |
| `config/bin/src/helpers` | Modify: add `h::has_bin`, repoint `h::needs_command` and `h::copy_to_clipboard` at it |
| `config/bin/xcg` | Rewrite: all branch logic, internal subcommands, fzf UI |
| `assets/integration/bin/support/git-fixture.ts` | Create: builds/tears down a throwaway git repo with known branch states |
| `assets/integration/bin/helpers.spec.ts` | Create: covers `h::has_bin` and the non-TTY fix |
| `assets/integration/bin/xcg.spec.ts` | Rewrite: covers every internal subcommand against the fixture |

`xcg` stays a single file. It is ~250 lines when done, consistent with `gitx` (322) and `xc` (314) in the same directory, and splitting a `$PATH` executable would require a sourcing dance the other bins don't use.

---

### Task 1: `h::has_bin` helper

The feature cannot work without this. `h::has_command` gates on `[[ -t 1 ]]`, so inside `execute-silent` — where stdout is not a TTY — `h::copy_to_clipboard` reports "No clipboard utility found" despite a working `pbcopy`, and `h::needs_command fzf` claims fzf is missing whenever `xcg` is piped.

**Files:**

- Modify: `config/bin/src/helpers:3-12` and `:55-68`
- Test: `assets/integration/bin/helpers.spec.ts`

- [ ] **Step 1: Write the failing test**

Create `assets/integration/bin/helpers.spec.ts`:

```ts
#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { join } from "node:path";
import { binRoot } from "./support/paths";

const helpers = join(binRoot, "src/helpers");

function runZsh(snippet: string, opts: { pipe: boolean } = { pipe: false }) {
  const script = `source ${helpers}\n${snippet}`;
  const cmd = opts.pipe ? ["zsh", "-c", `{ ${script} } | cat`] : ["zsh", "-c", script];
  const r = Bun.spawnSync(cmd, { stdout: "pipe", stderr: "pipe" });
  return {
    code: r.exitCode,
    out: new TextDecoder().decode(r.stdout).trim(),
    err: new TextDecoder().decode(r.stderr).trim(),
  };
}

describe("helpers", () => {
  describe("h::has_bin", () => {
    it("finds an existing binary", () => {
      expect(runZsh(`h::has_bin git && echo found`).out).toBe("found");
    });

    it("rejects a missing binary", () => {
      expect(runZsh(`h::has_bin definitely-not-a-real-binary || echo missing`).out).toBe("missing");
    });

    it("finds an existing binary even when stdout is not a TTY", () => {
      expect(runZsh(`h::has_bin git && echo found`, { pipe: true }).out).toBe("found");
    });
  });

  describe("h::needs_command", () => {
    it("succeeds for an existing binary when stdout is not a TTY", () => {
      expect(runZsh(`h::needs_command git && echo ok`, { pipe: true }).out).toBe("ok");
    });

    it("exits non-zero for a missing binary", () => {
      expect(runZsh(`h::needs_command definitely-not-a-real-binary`).code).not.toBe(0);
    });
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin helpers
```

Expected: FAIL — `h::has_bin: command not found`, and the `h::needs_command` non-TTY case reports "not installed".

- [ ] **Step 3: Add `h::has_bin` and repoint the two callers**

In `config/bin/src/helpers`, insert `h::has_bin` directly above `h::has_command`:

```bash
# Does this binary exist? No TTY check - use for capability detection.
h::has_bin() {
  command -v "$1" >/dev/null 2>&1
}

# Is this binary usable for interactive/pretty output? TTY-gated by design.
h::has_command() {
  [[ -t 1 && "${TERM:-}" != "dumb" ]] && command -v "$1" >/dev/null 2>&1
}
```

Change `h::needs_command` to use it:

```bash
h::needs_command() {
  if ! h::has_bin "$1"; then
    echo "Error: $1 is not installed" >&2
    exit 1
  fi
}
```

Replace the body of `h::copy_to_clipboard` so every branch uses `h::has_bin`:

```bash
h::copy_to_clipboard() {
  if h::has_bin pbcopy; then
    printf '%s' "$1" | pbcopy
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && h::has_bin wl-copy; then
    printf '%s' "$1" | wl-copy
  elif h::has_bin xclip; then
    printf '%s' "$1" | xclip -selection clipboard
  elif h::has_bin xsel; then
    printf '%s' "$1" | xsel --clipboard --input
  else
    h::puts error "No clipboard utility found (pbcopy, xclip, xsel)"
    return 1
  fi
}
```

Leave `h::filter` and `h::puts` alone — they use `h::has_command` for presentation decisions, where the TTY check is correct.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin helpers
```

Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/src/helpers assets/integration/bin/helpers.spec.ts
git commit -m "feat(bin): Add h::has_bin for TTY-independent binary detection"
```

---

### Task 2: Git fixture for integration tests

Every later task asserts against a repo with known branch states. Build it once.

**Files:**

- Create: `assets/integration/bin/support/git-fixture.ts`

- [ ] **Step 1: Write the failing test**

Create `assets/integration/bin/xcg.spec.ts` with only the fixture check for now:

```ts
#!/usr/bin/env bun
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { type GitFixture, makeGitFixture } from "./support/git-fixture";

let fx: GitFixture;

beforeAll(() => { fx = makeGitFixture(); });
afterAll(() => { fx.cleanup(); });

describe("git-fixture", () => {
  it("creates the expected branch states", () => {
    const r = Bun.spawnSync(["git", "branch", "--format=%(refname:short)"], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    const branches = new TextDecoder().decode(r.stdout).trim().split("\n").sort();
    expect(branches).toEqual(["gone-branch", "main", "merged-branch", "unmerged-branch"]);
  });

  it("has a remote-only branch", () => {
    const r = Bun.spawnSync(["git", "for-each-ref", "--format=%(refname:short)", "refs/remotes"], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    expect(new TextDecoder().decode(r.stdout)).toContain("origin/remote-only");
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — cannot resolve `./support/git-fixture`.

- [ ] **Step 3: Write the fixture module**

Create `assets/integration/bin/support/git-fixture.ts`. The command sequence below was executed and verified; keep the order, because `gone-branch` must be pushed before it is deleted from the remote:

```ts
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export interface GitFixture {
  root: string;
  work: string;
  remote: string;
  cleanup: () => void;
}

function run(cwd: string, ...args: string[]): void {
  const r = Bun.spawnSync(args, {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
    env: { ...Bun.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_SYSTEM: "/dev/null" },
  });
  if (r.exitCode !== 0) {
    throw new Error(`git ${args.join(" ")} failed: ${new TextDecoder().decode(r.stderr)}`);
  }
}

/**
 * Builds a throwaway repo containing, by design:
 *   main            - default branch, protected
 *   merged-branch   - merged into main
 *   unmerged-branch - not merged, `git branch -d` must refuse it
 *   gone-branch     - upstream was deleted on the remote
 *   origin/remote-only - exists only on the remote
 */
export function makeGitFixture(): GitFixture {
  const root = mkdtempSync(join(tmpdir(), "xcg-fixture-"));
  const remote = join(root, "remote");
  const work = join(root, "work");

  run(root, "git", "init", "-q", "--bare", remote);
  run(root, "git", "init", "-q", "-b", "main", work);
  run(work, "git", "config", "user.email", "test@example.com");
  run(work, "git", "config", "user.name", "Test User");

  Bun.write(join(work, "a.txt"), "a\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "initial");
  run(work, "git", "remote", "add", "origin", remote);
  run(work, "git", "push", "-q", "-u", "origin", "main");

  run(work, "git", "checkout", "-qb", "merged-branch");
  Bun.write(join(work, "b.txt"), "b\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "merged work");
  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "merge", "-q", "merged-branch");

  run(work, "git", "checkout", "-qb", "unmerged-branch");
  Bun.write(join(work, "c.txt"), "c\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "unmerged work");

  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "checkout", "-qb", "gone-branch");
  Bun.write(join(work, "d.txt"), "d\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "gone work");
  run(work, "git", "push", "-q", "-u", "origin", "gone-branch");
  run(work, "git", "push", "-q", "origin", "--delete", "gone-branch");

  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "checkout", "-qb", "remote-only");
  Bun.write(join(work, "e.txt"), "e\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "remote only");
  run(work, "git", "push", "-q", "-u", "origin", "remote-only");
  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "branch", "-qD", "remote-only");

  run(work, "git", "fetch", "-q", "--prune");

  return { root, work, remote, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}
```

Note: the fixture repo has no `origin/HEAD` symref, so `xcg::default_branch` will fall through to the `main`/`master`/`develop` probe. That is deliberate — it exercises the fallback path.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add assets/integration/bin/support/git-fixture.ts assets/integration/bin/xcg.spec.ts
git commit -m "test(bin): Add git fixture for xcg integration specs"
```

---

### Task 3: Rewrite the xcg skeleton without usage

Replace the usage framework with a plain dispatcher, keeping every existing public subcommand working. Nothing wired depends on the usage spec: `xc` only discovers `xc-*` executables, there is no `_xcg` completion, and no `completion-init` is sourced.

**Files:**

- Modify: `config/bin/xcg` (full rewrite of lines 1-74)
- Test: `assets/integration/bin/xcg.spec.ts`

- [ ] **Step 1: Write the failing test**

Append to the `describe` block list in `assets/integration/bin/xcg.spec.ts`:

```ts
const script = scriptPath("xcg");

function xcg(args: string[], cwd = fx.work) {
  const r = Bun.spawnSync([script, ...args], { cwd, stdout: "pipe", stderr: "pipe" });
  return {
    code: r.exitCode,
    out: new TextDecoder().decode(r.stdout),
    err: new TextDecoder().decode(r.stderr),
  };
}

describe("xcg help and public subcommands", () => {
  it("prints help with -h and exits 0", () => {
    const r = xcg(["-h"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("xcg");
  });

  it("prints help with --help and exits 0", () => {
    const r = xcg(["--help"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("xcg");
  });

  it("documents the fzf keymap in help", () => {
    expect(xcg(["--help"]).out).toContain("ctrl-x");
  });

  it("lists local branches with branches", () => {
    const r = xcg(["branches"]);
    expect(r.code).toBe(0);
    expect(r.out.trim().split("\n").sort()).toEqual(
      ["gone-branch", "main", "merged-branch", "unmerged-branch"],
    );
  });

  it("prints the current branch with head-branch", () => {
    expect(xcg(["head-branch"]).out.trim()).toBe("main");
  });

  it("lists remote branches with remote-branches", () => {
    const out = xcg(["remote-branches"]).out;
    expect(out).toContain("remote-only");
    expect(out).not.toContain("HEAD");
  });

  it("falls back to branches when stdout is not a TTY and no args are given", () => {
    const r = Bun.spawnSync(["sh", "-c", `${script} | cat`], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout)).toContain("main");
  });

  it("exits non-zero for an unknown subcommand", () => {
    expect(xcg(["no-such-subcommand"]).code).not.toBe(0);
  });
});
```

Add `scriptPath` to the existing import from `./support/paths`:

```ts
import { scriptPath } from "./support/paths";
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — the current script has a `usage` shebang, no `--help` of its own, and no non-TTY fallback.

- [ ] **Step 3: Rewrite `config/bin/xcg`**

Replace the entire file:

```zsh
#!/usr/bin/env zsh
# xcg - fzf-driven git branch manager

emulate -L zsh
setopt no_unset pipe_fail
source /Users/roalcantara/Work/dots/config/bin/src/helpers

xcg::help() {
  cat <<'EOF'
xcg - git branch manager

Usage:
  xcg                      Open the fzf branch manager (local branches)
  xcg branches             List local branch names
  xcg remote-branches [r]  List remote branch names (default remote: origin)
  xcg head-branch          Print the current branch
  xcg cnb <branch>         Create and check out a branch
  xcg clear-merged         Delete merged branches
  xcg clear-gone           Delete branches whose upstream is gone
  xcg -h | --help          Show this help

fzf keys:
  ctrl-l   local branches (default view)
  ctrl-r   remote branches
  ctrl-m   merged branches
  ctrl-g   branches whose upstream is gone
  ctrl-x   delete selected (safe, confirms)
  alt-x    delete selected (force, confirms)
  ctrl-o   check out the branch under the cursor
  ctrl-y   copy selected branch names to the clipboard

Without a TTY, `xcg` with no arguments behaves as `xcg branches`.
EOF
}

xcg::in_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || h::puts fatal "not a git repository"
}

xcg::head_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || print -r -- main
}

xcg::default_branch() {
  local d
  if d=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); then
    print -r -- "${d#origin/}"
    return 0
  fi
  local b
  for b in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$b"; then
      print -r -- "$b"
      return 0
    fi
  done
  xcg::head_branch
}

main() {
  local subcmd="${1:-}"
  [[ $# -gt 0 ]] && shift

  case "$subcmd" in
    -h|--help) xcg::help; return 0 ;;
  esac

  xcg::in_repo

  case "$subcmd" in
    "")
      if [[ -t 1 ]] && h::has_bin fzf; then
        xcg::ui
      else
        xcg::branches
      fi
      ;;
    branches)        xcg::branches ;;
    remote-branches) xcg::remote_branches "${1:-origin}" ;;
    head-branch)     xcg::head_branch ;;
    cnb)
      [[ -n "${1:-}" ]] || h::puts fatal "cnb requires a branch name"
      git checkout -b "$1"
      ;;
    clear-merged)    xcg::clear_merged ;;
    clear-gone)      xcg::clear_gone ;;
    *)
      h::puts error "unknown subcommand: $subcmd"
      xcg::help >&2
      return 1
      ;;
  esac
}

xcg::branches() {
  git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null
}

xcg::remote_branches() {
  local remote="${1:-origin}"
  git for-each-ref --exclude="refs/remotes/*/HEAD" \
    --format='%(refname:short)' "refs/remotes/$remote" 2>/dev/null \
    | sed "s|^$remote/||"
}

xcg::clear_merged() {
  local -a protected; protected=(${(f)"$(xcg::protected)"})
  local -a doomed=()
  local ref
  while IFS= read -r ref; do
    (( ${protected[(Ie)$ref]} )) && continue
    doomed+=("$ref")
  done < <(git for-each-ref --merged "$(xcg::default_branch)" --format='%(refname:short)' refs/heads 2>/dev/null)
  (( ${#doomed} )) || return 0
  git branch -d "${doomed[@]}"
  h::puts info "Cleared merged branches"
}

xcg::clear_gone() {
  git fetch --prune 2>/dev/null || true
  local -a protected; protected=(${(f)"$(xcg::protected)"})
  local -a doomed=()
  local ref track
  while IFS='|' read -r ref track; do
    [[ "$track" == gone ]] || continue
    (( ${protected[(Ie)$ref]} )) && continue
    doomed+=("$ref")
  done < <(git for-each-ref --format='%(refname:short)|%(upstream:track,nobracket)' refs/heads 2>/dev/null)
  (( ${#doomed} )) || return 0
  git branch -D "${doomed[@]}"
  h::puts info "Cleared gone branches"
}

main "$@"
```

`xcg::protected` and `xcg::ui` land in Tasks 4 and 8. Until Task 4, stub `xcg::protected` so `clear-merged` runs:

```zsh
xcg::protected() {
  print -rl -- "$(xcg::default_branch)" main master develop "$(xcg::head_branch)" | sort -u
}
```

Until Task 8, stub the UI:

```zsh
xcg::ui() { h::puts fatal "fzf UI not implemented yet"; }
```

Note `extended_glob` was dropped from `setopt` — no glob in this file needs it. The full preamble review happens in Task 9.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 10 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg assets/integration/bin/xcg.spec.ts
git commit -m "ref(bin): Drop usage integration from xcg"
```

---

### Task 4: `__list` and protected branches

**Files:**

- Modify: `config/bin/xcg`
- Test: `assets/integration/bin/xcg.spec.ts`

- [ ] **Step 1: Write the failing test**

Append to `assets/integration/bin/xcg.spec.ts`:

```ts
interface Row { kind: string; ref: string; display: string }

function rows(view: string): Row[] {
  const r = xcg(["__list", view]);
  expect(r.code).toBe(0);
  return r.out.trim().split("\n").filter(Boolean).map((line) => {
    const [kind, ref, display] = line.split("\t");
    return { kind, ref, display };
  });
}

describe("xcg __list", () => {
  it("lists every local branch in the local view", () => {
    expect(rows("local").map((r) => r.ref).sort()).toEqual(
      ["gone-branch", "main", "merged-branch", "unmerged-branch"],
    );
  });

  it("tags local rows with kind local", () => {
    expect(rows("local").every((r) => r.kind === "local")).toBe(true);
  });

  it("excludes origin/HEAD from the remote view", () => {
    const refs = rows("remote").map((r) => r.ref);
    expect(refs).toContain("origin/remote-only");
    expect(refs).toContain("origin/main");
    expect(refs).not.toContain("origin");
  });

  it("tags remote rows with kind remote", () => {
    expect(rows("remote").every((r) => r.kind === "remote")).toBe(true);
  });

  it("excludes protected branches from the merged view", () => {
    expect(rows("merged").map((r) => r.ref)).toEqual(["merged-branch"]);
  });

  it("lists only gone branches in the gone view", () => {
    expect(rows("gone").map((r) => r.ref)).toEqual(["gone-branch"]);
  });

  it("puts the branch name in the display field", () => {
    const row = rows("local").find((r) => r.ref === "main");
    expect(row?.display).toContain("main");
  });

  it("defaults to the local view when no view is given", () => {
    const r = xcg(["__list"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("merged-branch");
  });

  it("remembers the last view in XCG_STATE", () => {
    const stateFile = join(fx.root, "state");
    const env = { ...Bun.env, XCG_STATE: stateFile };
    Bun.spawnSync([script, "__list", "gone"], { cwd: fx.work, env, stdout: "pipe", stderr: "pipe" });
    const r = Bun.spawnSync([script, "__list"], { cwd: fx.work, env, stdout: "pipe", stderr: "pipe" });
    const out = new TextDecoder().decode(r.stdout);
    expect(out).toContain("gone-branch");
    expect(out).not.toContain("unmerged-branch");
  });
});

describe("xcg __protected", () => {
  it("includes the default branch and HEAD", () => {
    const out = xcg(["__protected"]).out.trim().split("\n");
    expect(out).toContain("main");
  });
});
```

Add `join` to the node imports at the top of the spec:

```ts
import { join } from "node:path";
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — `unknown subcommand: __list`.

- [ ] **Step 3: Implement `__list`, `__protected` and the row formatter**

Replace the `xcg::protected` stub from Task 3 with the real one, and add the listing functions above `main`:

```zsh
xcg::protected() {
  local -a p
  p=("$(xcg::default_branch)" main master develop "$(xcg::head_branch)")
  print -rl -- "${p[@]}" | sort -u
}

# kind<TAB>ref<TAB>display  - fields 1-2 are hidden from fzf by --with-nth=3..
xcg::row() {
  local kind="$1" ref="$2" track="$3" date="$4" author="$5"
  local mark=""   # NOTE: `status` is read-only in zsh - do not use that name
  case "$track" in
    gone) mark=$'\e[31mgone\e[0m' ;;
    "")   mark="" ;;
    *)    mark="$track" ;;
  esac
  printf '%s\t%s\t%-40s %-16s %-14s %s\n' \
    "$kind" "$ref" "$ref" "$date" "$author" "$mark"
}

xcg::list() {
  local view="${1:-}"

  if [[ -z "$view" ]]; then
    if [[ -n "${XCG_STATE:-}" && -s "${XCG_STATE}" ]]; then
      view=$(<"${XCG_STATE}")
    else
      view=local
    fi
  elif [[ -n "${XCG_STATE:-}" ]]; then
    print -r -- "$view" > "${XCG_STATE}"
  fi

  local fmt='%(refname:short)|%(upstream:track,nobracket)|%(committerdate:relative)|%(authorname)'
  local ref track date author
  local -a protected; protected=(${(f)"$(xcg::protected)"})

  case "$view" in
    remote)
      while IFS='|' read -r ref track date author; do
        xcg::row remote "$ref" "$track" "$date" "$author"
      done < <(git for-each-ref --exclude='refs/remotes/*/HEAD' --format="$fmt" refs/remotes 2>/dev/null)
      ;;
    merged)
      while IFS='|' read -r ref track date author; do
        (( ${protected[(Ie)$ref]} )) && continue
        xcg::row local "$ref" "$track" "$date" "$author"
      done < <(git for-each-ref --merged "$(xcg::default_branch)" --format="$fmt" refs/heads 2>/dev/null)
      ;;
    gone)
      while IFS='|' read -r ref track date author; do
        [[ "$track" == gone ]] || continue
        (( ${protected[(Ie)$ref]} )) && continue
        xcg::row local "$ref" "$track" "$date" "$author"
      done < <(git for-each-ref --format="$fmt" refs/heads 2>/dev/null)
      ;;
    local|*)
      while IFS='|' read -r ref track date author; do
        xcg::row local "$ref" "$track" "$date" "$author"
      done < <(git for-each-ref --format="$fmt" refs/heads 2>/dev/null)
      ;;
  esac
}
```

Add the dispatch cases in `main`, directly above the `*)` catch-all:

```zsh
    __list)      xcg::list "${1:-}" ;;
    __protected) xcg::protected ;;
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 20 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg assets/integration/bin/xcg.spec.ts
git commit -m "feat(bin): Add xcg __list with local, remote, merged and gone views"
```

---

### Task 5: `__delete`

**Files:**

- Modify: `config/bin/xcg`
- Test: `assets/integration/bin/xcg.spec.ts`

- [ ] **Step 1: Write the failing test**

Append to `assets/integration/bin/xcg.spec.ts`. Each destructive case builds its own fixture so tests cannot interfere:

```ts
function row(cwd: string, view: string, ref: string): string {
  const r = Bun.spawnSync([script, "__list", view], { cwd, stdout: "pipe", stderr: "pipe" });
  const line = new TextDecoder().decode(r.stdout).split("\n").find((l) => l.split("\t")[1] === ref);
  if (!line) throw new Error(`no ${ref} row in ${view} view`);
  return line;
}

function localBranches(cwd: string): string[] {
  const r = Bun.spawnSync(["git", "branch", "--format=%(refname:short)"], {
    cwd, stdout: "pipe", stderr: "pipe",
  });
  return new TextDecoder().decode(r.stdout).trim().split("\n").filter(Boolean);
}

describe("xcg __delete", () => {
  it("deletes a merged branch under XCG_YES", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "merged", "merged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(localBranches(f.work)).not.toContain("merged-branch");
    } finally { f.cleanup(); }
  });

  it("refuses an unmerged branch in safe mode and keeps it", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "local", "unmerged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).not.toBe(0);
      expect(localBranches(f.work)).toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("deletes an unmerged branch in force mode", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "force", row(f.work, "local", "unmerged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(localBranches(f.work)).not.toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("refuses a protected branch and names it", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "force", row(f.work, "local", "main")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      const combined = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(combined).toContain("main");
      expect(localBranches(f.work)).toContain("main");
    } finally { f.cleanup(); }
  });

  it("deletes several branches in one call", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([
        script, "__delete", "force",
        row(f.work, "local", "merged-branch"),
        row(f.work, "local", "unmerged-branch"),
      ], { cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const left = localBranches(f.work);
      expect(left).not.toContain("merged-branch");
      expect(left).not.toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("deletes a remote branch under XCG_YES", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "remote", "origin/remote-only")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const refs = Bun.spawnSync(["git", "ls-remote", "--heads", "origin"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(new TextDecoder().decode(refs.stdout)).not.toContain("remote-only");
    } finally { f.cleanup(); }
  });
});
```

Add `makeGitFixture` to the existing import if it is not already named there.

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — `unknown subcommand: __delete`.

- [ ] **Step 3: Implement `__delete`**

Add above `main`:

```zsh
xcg::confirm() {
  local prompt="$1"
  [[ -n "${XCG_YES:-}" ]] && return 0
  if h::has_bin gum; then
    gum confirm "$prompt"
  else
    local reply
    print -n -- "$prompt [y/N] "
    read -k1 reply
    print
    [[ "$reply" == [yY] ]]
  fi
}

xcg::delete() {
  local mode="${1:-safe}"
  shift || true
  (( $# )) || return 0

  local -a protected; protected=(${(f)"$(xcg::protected)"})
  local -a skipped=() locals=() remotes=()
  local line kind ref

  for line in "$@"; do
    IFS=$'\t' read -r kind ref _ <<< "$line"
    [[ -n "$ref" ]] || continue
    if [[ "$kind" == local ]] && (( ${protected[(Ie)$ref]} )); then
      skipped+=("$ref")
      continue
    fi
    if [[ "$kind" == remote ]]; then
      remotes+=("$ref")
    else
      locals+=("$ref")
    fi
  done

  (( ${#skipped} )) && h::puts warn "Skipped protected: ${(j:, :)skipped}"
  (( ${#locals} + ${#remotes} )) || return 0

  local flag=-d
  [[ "$mode" == force ]] && flag=-D

  print -r -- "About to delete:"
  (( ${#locals} ))  && print -r -- "  local  (git branch $flag): ${(j:, :)locals}"
  (( ${#remotes} )) && print -r -- "  remote (git push --delete): ${(j:, :)remotes}"

  xcg::confirm "Proceed?" || { h::puts info "Aborted"; return 0; }

  local rc=0
  (( ${#locals} )) && { git branch "$flag" "${locals[@]}" || rc=$? }

  local remote branch
  for ref in "${remotes[@]}"; do
    remote="${ref%%/*}"
    branch="${ref#*/}"
    git push --delete "$remote" "$branch" || rc=$?
  done

  if (( rc != 0 )); then
    # Pause so the error survives fzf's redraw; skipped when non-interactive.
    if [[ -t 0 && -z "${XCG_YES:-}" ]]; then
      print -n -- "Press any key to continue..."
      read -k1
      print
    fi
    return $rc
  fi
  return 0
}
```

Add the dispatch case in `main`, above the catch-all:

```zsh
    __delete) xcg::delete "$@" ;;
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 26 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg assets/integration/bin/xcg.spec.ts
git commit -m "feat(bin): Add xcg __delete with confirmation and protected branches"
```

---

### Task 6: `__preview`

**Files:**

- Modify: `config/bin/xcg`
- Test: `assets/integration/bin/xcg.spec.ts`

- [ ] **Step 1: Write the failing test**

Append to `assets/integration/bin/xcg.spec.ts`:

```ts
describe("xcg __preview", () => {
  it("shows the ref name and metadata for a local branch", () => {
    const out = xcg(["__preview", "local", "unmerged-branch"]).out;
    expect(out).toContain("unmerged-branch");
    expect(out).toContain("last:");
    expect(out).toContain("Test User");
  });

  it("reports an unmerged branch as not merged", () => {
    expect(xcg(["__preview", "local", "unmerged-branch"]).out).toContain("not merged");
  });

  it("reports a merged branch as merged", () => {
    const out = xcg(["__preview", "local", "merged-branch"]).out;
    expect(out).toMatch(/status:\s+merged into main/);
  });

  it("reports a gone upstream", () => {
    expect(xcg(["__preview", "local", "gone-branch"]).out).toContain("gone");
  });

  it("shows commits for an unmerged branch", () => {
    expect(xcg(["__preview", "local", "unmerged-branch"]).out).toContain("unmerged work");
  });

  it("falls back to plain log when the range is empty", () => {
    expect(xcg(["__preview", "local", "merged-branch"]).out).toContain("merged work");
  });

  it("previews a remote branch", () => {
    const out = xcg(["__preview", "remote", "origin/remote-only"]).out;
    expect(out).toContain("origin/remote-only");
    expect(out).toContain("remote only");
  });

  it("exits 0 for a ref that no longer exists", () => {
    expect(xcg(["__preview", "local", "no-such-branch"]).code).toBe(0);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — `unknown subcommand: __preview`.

- [ ] **Step 3: Implement `__preview`**

Add above `main`:

```zsh
xcg::full_ref() {
  local kind="$1" ref="$2"
  [[ "$kind" == remote ]] && print -r -- "refs/remotes/$ref" || print -r -- "refs/heads/$ref"
}

xcg::preview() {
  local kind="${1:-local}" ref="${2:-}"
  [[ -n "$ref" ]] || return 0

  local full; full=$(xcg::full_ref "$kind" "$ref")
  git show-ref --verify --quiet "$full" || { print -r -- "$ref (no longer exists)"; return 0 }

  local default_branch base
  default_branch=$(xcg::default_branch)
  if [[ "$kind" == remote ]]; then
    base="origin/$default_branch"
  else
    base="$default_branch"
  fi

  local upstream track date author
  IFS='|' read -r upstream track date author <<< \
    "$(git for-each-ref --format='%(upstream:short)|%(upstream:track,nobracket)|%(committerdate:relative)|%(authorname)' "$full")"

  local mark
  if [[ "$track" == gone ]]; then
    mark="gone"
  elif [[ -n "$track" ]]; then
    mark="$track"
  else
    mark="up to date"
  fi

  print -r -- $'\e[1m'"$ref"$'\e[0m'
  print -r -- "upstream: ${upstream:-none}  ${mark}"
  print -r -- "last:     ${date} · ${author}"
  if git rev-parse --verify --quiet "$base" >/dev/null 2>&1 \
     && git merge-base --is-ancestor "$ref" "$base" 2>/dev/null; then
    print -r -- "status:   merged into ${default_branch}"
  else
    print -r -- "status:   not merged into ${default_branch}"
  fi
  print -r -- "────────────────────────────────────────"

  local log
  log=$(git log --oneline --graph --color=always -n 20 "${base}..${ref}" 2>/dev/null)
  [[ -z "$log" ]] && log=$(git log --oneline --graph --color=always -n 20 "$ref" 2>/dev/null)
  print -r -- "$log"
}
```

Add the dispatch case in `main`, above the catch-all:

```zsh
    __preview) xcg::preview "${1:-local}" "${2:-}" ;;
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 34 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg assets/integration/bin/xcg.spec.ts
git commit -m "feat(bin): Add xcg __preview with branch metadata and log"
```

---

### Task 7: `__checkout` and `__copy`

**Files:**

- Modify: `config/bin/xcg`
- Test: `assets/integration/bin/xcg.spec.ts`

- [ ] **Step 1: Write the failing test**

Append to `assets/integration/bin/xcg.spec.ts`:

```ts
function currentBranch(cwd: string): string {
  const r = Bun.spawnSync(["git", "rev-parse", "--abbrev-ref", "HEAD"], {
    cwd, stdout: "pipe", stderr: "pipe",
  });
  return new TextDecoder().decode(r.stdout).trim();
}

describe("xcg __checkout", () => {
  it("switches to a local branch", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__checkout", "local", "unmerged-branch"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(currentBranch(f.work)).toBe("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("creates a tracking branch for a remote-only ref", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__checkout", "remote", "origin/remote-only"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(currentBranch(f.work)).toBe("remote-only");
      const up = Bun.spawnSync(["git", "rev-parse", "--abbrev-ref", "remote-only@{upstream}"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(new TextDecoder().decode(up.stdout).trim()).toBe("origin/remote-only");
    } finally { f.cleanup(); }
  });

  it("switches to the existing local branch when the remote ref already has one", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__checkout", "remote", "origin/main"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(currentBranch(f.work)).toBe("main");
    } finally { f.cleanup(); }
  });

  it("exits non-zero for a ref that does not exist", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__checkout", "local", "no-such-branch"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).not.toBe(0);
    } finally { f.cleanup(); }
  });
});

describe("xcg __copy", () => {
  it("prints the branch name when XCG_COPY_STDOUT is set", () => {
    const r = Bun.spawnSync([script, "__copy", row(fx.work, "local", "unmerged-branch")], {
      cwd: fx.work, env: { ...Bun.env, XCG_COPY_STDOUT: "1" }, stdout: "pipe", stderr: "pipe",
    });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout).trim()).toBe("unmerged-branch");
  });

  it("strips the remote prefix", () => {
    const r = Bun.spawnSync([script, "__copy", row(fx.work, "remote", "origin/remote-only")], {
      cwd: fx.work, env: { ...Bun.env, XCG_COPY_STDOUT: "1" }, stdout: "pipe", stderr: "pipe",
    });
    expect(new TextDecoder().decode(r.stdout).trim()).toBe("remote-only");
  });

  it("joins several selections with newlines", () => {
    const r = Bun.spawnSync([
      script, "__copy",
      row(fx.work, "local", "merged-branch"),
      row(fx.work, "local", "unmerged-branch"),
    ], { cwd: fx.work, env: { ...Bun.env, XCG_COPY_STDOUT: "1" }, stdout: "pipe", stderr: "pipe" });
    expect(new TextDecoder().decode(r.stdout).trim().split("\n")).toEqual(
      ["merged-branch", "unmerged-branch"],
    );
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd assets && mise run integration bin xcg
```

Expected: FAIL — `unknown subcommand: __checkout`.

- [ ] **Step 3: Implement `__checkout` and `__copy`**

Add above `main`:

```zsh
xcg::checkout() {
  local kind="${1:-local}" ref="${2:-}"
  [[ -n "$ref" ]] || return 1
  # become() replaces the process, so traps never fire - clean up here.
  [[ -n "${XCG_STATE:-}" ]] && rm -f "${XCG_STATE}"

  if [[ "$kind" == remote ]]; then
    local short="${ref#*/}"
    if git show-ref --verify --quiet "refs/heads/$short"; then
      git switch "$short"
    else
      git switch --track "$ref"
    fi
  else
    git switch "$ref"
  fi
}

xcg::copy() {
  (( $# )) || return 0
  local -a names=()
  local line kind ref
  for line in "$@"; do
    IFS=$'\t' read -r kind ref _ <<< "$line"
    [[ -n "$ref" ]] || continue
    [[ "$kind" == remote ]] && ref="${ref#*/}"
    names+=("$ref")
  done
  (( ${#names} )) || return 0

  local payload="${(j:\n:)names}"
  if [[ -n "${XCG_COPY_STDOUT:-}" ]]; then
    print -r -- "$payload"
    return 0
  fi
  h::copy_to_clipboard "$payload"
}
```

Add the dispatch cases in `main`, above the catch-all:

```zsh
    __checkout) xcg::checkout "${1:-local}" "${2:-}" ;;
    __copy)     xcg::copy "$@" ;;
```

`XCG_COPY_STDOUT` exists so the spec can assert on payload shape without depending on a clipboard being present in CI.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 41 tests.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg assets/integration/bin/xcg.spec.ts
git commit -m "feat(bin): Add xcg __checkout and __copy actions"
```

---

### Task 8: Wire up the fzf UI

The binding layer is the one part no harness can reach, so it is verified by hand.

**Files:**

- Modify: `config/bin/xcg` (replace the `xcg::ui` stub)

- [ ] **Step 1: Replace the stub**

```zsh
xcg::ui() {
  h::needs_command fzf

  export XCG_STATE="${XCG_STATE:-$(mktemp -t xcg-state)}"
  trap 'rm -f "${XCG_STATE}"' EXIT INT TERM
  print -r -- local > "${XCG_STATE}"

  local self="${0:a}"
  local keys='^l local  ^r remote  ^m merged  ^g gone  |  ^x del  M-x del!  ^o checkout  ^y copy'

  command fzf --ansi --multi \
    --delimiter=$'\t' --with-nth=3.. \
    --header-first --header="LOCAL — $keys" \
    --prompt='branch ❯ ' \
    --preview="$self __preview {1} {2}" \
    --preview-window='right,55%,border-left,wrap' \
    --bind="start:reload($self __list local)" \
    --bind="ctrl-l:change-header(LOCAL — $keys)+reload($self __list local)" \
    --bind="ctrl-r:change-header(REMOTE — $keys)+reload($self __list remote)" \
    --bind="ctrl-m:change-header(MERGED — $keys)+reload($self __list merged)" \
    --bind="ctrl-g:change-header(GONE — $keys)+reload($self __list gone)" \
    --bind="ctrl-x:execute($self __delete safe {+})+reload($self __list)" \
    --bind="alt-x:execute($self __delete force {+})+reload($self __list)" \
    --bind="ctrl-o:become($self __checkout {1} {2})" \
    --bind="ctrl-y:execute-silent($self __copy {+})" \
    --bind='ctrl-/:toggle-preview'
}
```

`--with-nth=3..` is passed without `--nth`: fzf applies `--nth` to the already-transformed line, so adding `--nth=3..` would match nothing.

`execute` rather than `execute-silent` for deletes — it hands the terminal to the child so `gum confirm` can draw.

- [ ] **Step 2: Verify the script parses**

```bash
zsh -n config/bin/xcg
```

Expected: no output, exit 0.

- [ ] **Step 3: Verify the automated suite still passes**

```bash
cd assets && mise run integration bin xcg
```

Expected: PASS, 41 tests.

- [ ] **Step 4: Manual verification**

Run `xcg` in a repo with a few branches and confirm each item:

- [ ] Opens on local branches with the LOCAL header
- [ ] `ctrl-r`, `ctrl-m`, `ctrl-g`, `ctrl-l` each swap the list and header
- [ ] The preview pane shows metadata plus commits, and tracks the cursor
- [ ] `ctrl-x` on an unmerged branch prompts, then reports git's refusal and pauses
- [ ] `alt-x` on that branch prompts, deletes it, and the list reloads in the same view
- [ ] If `alt-x` does not fire, rebind force delete to `ctrl-d` (see the spec's Open risk) and note it in the commit
- [ ] Tab-marking several branches then `ctrl-x` confirms once and deletes all of them
- [ ] `ctrl-o` exits fzf and lands on the chosen branch, with git's output in the scrollback
- [ ] `ctrl-o` from the remote view on a remote-only branch creates a tracking branch
- [ ] `ctrl-y` puts the name on the clipboard — verify with `pbpaste`
- [ ] `Esc` exits cleanly and leaves no `xcg-state` file in `$TMPDIR`

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg
git commit -m "feat(bin): Wire up the xcg fzf branch manager UI"
```

---

### Task 9: Shell option review and final gate

Settle the preamble deliberately rather than carrying it over, and run the full suite.

**Files:**

- Modify: `config/bin/xcg:4-5`

- [ ] **Step 1: Decide each option**

Read the finished script and record a decision for each. Expected outcomes, to be confirmed against the actual file:

- `emulate -L zsh` — **keep**. `-L` is near-inert at top level, but it pins zsh-native behaviour regardless of the invoking environment now that `usage` no longer controls the interpreter, and it costs nothing.
- `no_unset` — **keep**. The `usage_*` variables it was guarding are gone, but the script reads `XCG_STATE`, `XCG_YES` and `XCG_COPY_STDOUT` from the environment, and `no_unset` is what forces the `${VAR:-}` guards that keep those safe.
- `pipe_fail` — **drop unless a pipeline needs it**. The old `git | grep | sed` chains are gone; `__list` is a single `for-each-ref`. Grep the finished file: `grep -n '|' config/bin/xcg`. Keep it only if a surviving pipeline's exit status is actually checked.
- `extended_glob` — **drop**. Already removed in Task 3; confirm no glob in the file needs it.

Apply the decisions, then add a one-line comment recording why each surviving option is there.

- [ ] **Step 2: Verify the script parses**

```bash
zsh -n config/bin/xcg
```

Expected: no output, exit 0.

- [ ] **Step 3: Confirm no usage residue remains**

```bash
grep -n 'USAGE\|usage_' config/bin/xcg
```

Expected: no matches.

- [ ] **Step 4: Run the full gate**

```bash
mise run -C assets test bin
```

Expected: BDD suite passes unchanged, integration suite passes including `helpers` and `xcg`.

- [ ] **Step 5: Commit**

```bash
git add config/bin/xcg
git commit -m "ref(bin): Settle xcg shell options after the usage removal"
```

---

## Self-review

**Spec coverage:** command surface → Task 3; data layer and row format → Task 4; protected branches → Tasks 4, 5; the four views → Task 4; usage removal → Task 3, confirmed clean in Task 9; shell option review → Task 9; fzf UI and bindings → Task 8; view state via `XCG_STATE` → Tasks 4, 8, cleaned up in Task 7; delete with confirmation → Task 5; checkout → Task 7; copy → Task 7; preview → Task 6; `h::has_bin` → Task 1; error handling → Tasks 3 (`xcg::in_repo`, unknown subcommand), 5 (protected, failure pause), 6 (missing ref); testing → Tasks 2 and 5–7, gate in Task 9.

**Naming consistency:** `xcg::` prefix throughout; `mark` never `status`; `XCG_STATE`, `XCG_YES`, `XCG_COPY_STDOUT` used identically in script and specs; row order `kind`, `ref`, `display` everywhere; `__delete <mode> <row>...`, `__copy <row>...`, `__checkout <kind> <ref>`, `__preview <kind> <ref>`, `__list [view]` consistent between Task 8's bindings and Tasks 4–7's implementations.

**Deviation from the spec:** the spec did not mention `XCG_COPY_STDOUT`. It was added in Task 7 so the copy payload can be asserted without a clipboard in CI. `__protected` was also exposed as an internal subcommand so the protected set is directly testable.
