<!-- markdownlint-disable -->
# gitx fza Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `gitx fza` an fzf picker that lists only the files `git add` would change. `Tab` toggles a file, a bordered `keys` box shows every shortcut, and the diff preview is open on start.

**Architecture:** All production code lives in `config/bin/gitx`. A new `_gitx_add_candidates` helper parses `git status --porcelain=v1 -z` into `XY<TAB>path` lines, and the `fza)` case pipes them into a single fzf call. Integration specs drive the real script with a stub `fzf` on `PATH`. The stub records fzf's argv and stdin and prints a scripted selection, so the tests don't need a TTY.

**Tech Stack:** zsh (run through the `usage` shebang), fzf ≥ 0.60 (0.74.4 installed), Bun test (`assets/integration`), mise tasks.

**Spec:** [`design.md`](design.md)

---

## File Structure

| Path | Action | Responsibility |
| ---- | ------ | -------------- |
| `config/bin/gitx` | Modify | Add the `_gitx_add_candidates` helper (before `_gitx_root_commit`), rewrite the `fza)` case, update the `fza` USAGE help |
| `assets/integration/bin/support/add-fixture.ts` | Create | Throwaway repos: one covering every status combination, one clean, one non-repo dir |
| `assets/integration/bin/gitx-fza.spec.ts` | Create | Stub fzf, a `runFza` helper, and the candidate, picker, staging and guard specs |

### Commands

From the repo root:

- Run only this spec: `mise run -C assets integration bin gitx-fza`
- Run the full bin gate, which is the Definition of Done for `config/bin/*`: `mise run -C assets test bin`

---

### Task 1: Candidate list

**Files:**
- Create: `assets/integration/bin/support/add-fixture.ts`
- Create: `assets/integration/bin/gitx-fza.spec.ts`
- Modify: `config/bin/gitx` (helper section near `_gitx_root_commit`, and the `fza)` case)

- [ ] **Step 1: Create the fixture**

`assets/integration/bin/support/add-fixture.ts`:

```ts
import { appendFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export interface AddFixture {
  work: string;
  cleanup: () => void;
}

export const gitEnv = { ...Bun.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_SYSTEM: "/dev/null" };

export function git(cwd: string, ...args: string[]): string {
  const r = Bun.spawnSync(["git", ...args], { cwd, stdout: "pipe", stderr: "pipe", env: gitEnv });
  if (r.exitCode !== 0) {
    throw new Error(`git ${args.join(" ")} failed: ${new TextDecoder().decode(r.stderr)}`);
  }
  return new TextDecoder().decode(r.stdout);
}

function initRepo(prefix: string): string {
  const work = mkdtempSync(join(tmpdir(), prefix));
  git(work, "init", "-q", "-b", "main");
  git(work, "config", "user.email", "test@example.com");
  git(work, "config", "user.name", "Test User");
  return work;
}

function fixture(work: string): AddFixture {
  return { work, cleanup: () => rmSync(work, { recursive: true, force: true }) };
}

/**
 * Working tree after setup (`git status -s`):
 *    D deleted.txt
 *    M modified.txt
 *   RM old-name.txt -> new-name.txt
 *   MM partial.txt
 *   M  staged.txt            <- fully staged, must NOT be a candidate
 *    M "with space.txt"
 *   ?? newdir/               <- expands to newdir/sub/n.txt
 */
export function makeAddFixture(): AddFixture {
  const work = initRepo("gitx-fza-");
  const p = (f: string) => join(work, f);

  for (const f of ["modified.txt", "deleted.txt", "old-name.txt", "partial.txt", "staged.txt", "with space.txt"]) {
    writeFileSync(p(f), "base\n");
  }
  git(work, "add", "-A");
  git(work, "commit", "-qm", "initial");

  appendFileSync(p("modified.txt"), "x\n");
  rmSync(p("deleted.txt"));
  git(work, "mv", "old-name.txt", "new-name.txt");
  appendFileSync(p("new-name.txt"), "x\n");
  appendFileSync(p("partial.txt"), "x\n");
  git(work, "add", "partial.txt");
  appendFileSync(p("partial.txt"), "y\n");
  appendFileSync(p("staged.txt"), "x\n");
  git(work, "add", "staged.txt");
  appendFileSync(p("with space.txt"), "x\n");
  mkdirSync(p("newdir/sub"), { recursive: true });
  writeFileSync(p("newdir/sub/n.txt"), "n\n");

  return fixture(work);
}

/** A repo with one commit and nothing to add. */
export function makeCleanRepo(): AddFixture {
  const work = initRepo("gitx-fza-clean-");
  writeFileSync(join(work, "a.txt"), "a\n");
  git(work, "add", "-A");
  git(work, "commit", "-qm", "initial");
  return fixture(work);
}

/** A plain directory outside any git repository. */
export function makeNonRepo(): AddFixture {
  return fixture(mkdtempSync(join(tmpdir(), "gitx-fza-norepo-")));
}

/** Paths currently in the index that differ from HEAD. */
export function stagedFiles(cwd: string): string[] {
  return git(cwd, "diff", "--cached", "--name-only").split("\n").filter(Boolean).sort();
}
```

- [ ] **Step 2: Write the failing candidate spec**

`assets/integration/bin/gitx-fza.spec.ts`:

```ts
#!/usr/bin/env bun
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type AddFixture, gitEnv, makeAddFixture } from "./support/add-fixture";
import { scriptPath } from "./support/paths";

const script = scriptPath("gitx");

// fzf test double: records argv (one per line) and stdin, prints
// $FZF_STUB_SELECT as the selection, exits with $FZF_STUB_EXIT.
const STUB = `#!/bin/sh
log="\${FZF_STUB_LOG:?}"
: > "$log.args"
for a in "$@"; do printf '%s\\n' "$a" >> "$log.args"; done
cat > "$log.stdin"
[ -n "\${FZF_STUB_SELECT:-}" ] && printf '%s\\n' "$FZF_STUB_SELECT"
exit "\${FZF_STUB_EXIT:-0}"
`;

let stubDir = "";
let log = "";

beforeAll(() => {
  stubDir = mkdtempSync(join(tmpdir(), "gitx-fza-stub-"));
  writeFileSync(join(stubDir, "fzf"), STUB);
  chmodSync(join(stubDir, "fzf"), 0o755);
  log = join(stubDir, "log");
});

afterAll(() => rmSync(stubDir, { recursive: true, force: true }));

interface FzaRun {
  exitCode: number;
  output: string; // stdout + stderr
  stdin: string; // what gitx piped into fzf ("" if fzf never ran)
  args: string; // fzf argv, one arg per line
}

function read(path: string): string {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

function runFza(cwd: string, opts: { select?: string[]; exit?: number } = {}): FzaRun {
  rmSync(`${log}.stdin`, { force: true });
  rmSync(`${log}.args`, { force: true });
  const r = Bun.spawnSync([script, "fza"], {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
    env: {
      ...gitEnv,
      PATH: `${stubDir}:${Bun.env.PATH}`,
      FZF_STUB_LOG: log,
      FZF_STUB_SELECT: (opts.select ?? []).join("\n"),
      FZF_STUB_EXIT: String(opts.exit ?? 0),
    },
  });
  const dec = new TextDecoder();
  return {
    exitCode: r.exitCode,
    output: dec.decode(r.stdout) + dec.decode(r.stderr),
    stdin: read(`${log}.stdin`),
    args: read(`${log}.args`),
  };
}

describe("gitx fza", () => {
  let fx: AddFixture;
  beforeEach(() => {
    fx = makeAddFixture();
  });
  afterEach(() => fx.cleanup());

  describe("candidates", () => {
    it("lists only files git add would change, as XY<TAB>path", () => {
      const r = runFza(fx.work);
      expect(r.stdin).toBe(
        [
          " D\tdeleted.txt",
          " M\tmodified.txt",
          "RM\tnew-name.txt",
          "MM\tpartial.txt",
          " M\twith space.txt",
          "??\tnewdir/sub/n.txt",
        ].join("\n") + "\n",
      );
    });

    it("excludes fully staged files", () => {
      expect(runFza(fx.work).stdin).not.toContain("staged.txt");
    });
  });
});
```

- [ ] **Step 3: Run the spec and confirm it fails**

Run: `mise run -C assets integration bin gitx-fza`
Expected: `candidates > lists only files…` FAILS. The current code pipes `git status -s`, so the received stdin has no tabs, shows `RM old-name.txt -> new-name.txt`, and lists `?? newdir/`. `excludes fully staged files` also FAILS, because `M  staged.txt` is in the list.

- [ ] **Step 4: Add the helper to `config/bin/gitx`**

Insert this immediately before `_gitx_root_commit() {`:

```zsh
# Files `git add` would change, one "XY<TAB>path" per line: entries whose
# worktree column (Y) is not blank. Renames/copies carry the original path in
# the next NUL field, which is skipped.
_gitx_add_candidates() {
  local -a entries=(${(0)"$(git status --porcelain=v1 -z --untracked-files=all 2>/dev/null)"})
  local i=1 xy file
  while (( i <= ${#entries} )); do
    xy=${entries[i][1,2]} file=${entries[i][4,-1]}
    (( i++ ))
    [[ $xy == ([RC]?|?[RC]) ]] && (( i++ ))
    [[ ${xy[2]} == ' ' ]] && continue
    print -r -- "${xy}"$'\t'"${file}"
  done
}
```

Don't name the loop variable `path`: in zsh, `path` is the array tied to `$PATH`.

- [ ] **Step 5: Point `fza)` at the helper (minimal)**

Replace:

```zsh
  fza)
    git status -s | fzf -m | awk '{print $2}' | xargs git add
    ;;
```

with:

```zsh
  fza)
    selected=$(_gitx_add_candidates | fzf --multi --delimiter=$'\t' --accept-nth=2) || exit 0
    [[ -z "$selected" ]] && exit 0
    git add -- "${(@f)selected}"
    ;;
```

- [ ] **Step 6: Run the spec and confirm it passes**

Run: `mise run -C assets integration bin gitx-fza`
Expected: `2 pass, 0 fail`.

- [ ] **Step 7: Commit**

```bash
git add config/bin/gitx assets/integration/bin/support/add-fixture.ts assets/integration/bin/gitx-fza.spec.ts
git commit -m "feat(bin): List only addable files in gitx fza"
```

---

### Task 2: Picker UI, keymap box, preview open on start, staging

**Files:**
- Modify: `assets/integration/bin/gitx-fza.spec.ts` (add `picker` and `staging` describes inside `describe("gitx fza")`)
- Modify: `config/bin/gitx` (`fza)` case)

- [ ] **Step 1: Write the failing picker and staging specs**

In `gitx-fza.spec.ts`, change the fixture import to:

```ts
import { type AddFixture, gitEnv, makeAddFixture, stagedFiles } from "./support/add-fixture";
```

Add these after the `candidates` describe, inside `describe("gitx fza")`:

```ts
  describe("picker", () => {
    it("multi-selects and returns only the path field", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--multi\n");
      expect(args).toContain("--delimiter=\t\n");
      expect(args).toContain("--accept-nth=2\n");
    });

    it("shows every shortcut in a bordered keys header", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--header-border=rounded\n");
      expect(args).toContain("--header-label= keys \n");
      for (const key of ["tab toggle", "⇧tab toggle↑", "^a all", "^d none", "enter add", "^p patch", "^/ preview", "esc cancel"]) {
        expect(args).toContain(key);
      }
    });

    it("opens the diff preview on start", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--preview-window=right,60%,border-left,nohidden\n");
      expect(args).toContain("git diff --no-index --color=always -- /dev/null {2}");
      expect(args).toContain("git diff --color=always -- {2}");
    });

    it("binds select-all, deselect-all, preview toggle and patch mode", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--bind=ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview\n");
      expect(args).toContain("--bind=ctrl-p:become(git add -p -- {+2})\n");
    });
  });

  describe("staging", () => {
    it("stages the selected paths, including spaces and untracked files", () => {
      const r = runFza(fx.work, { select: ["with space.txt", "newdir/sub/n.txt"] });
      expect(r.exitCode).toBe(0);
      const staged = stagedFiles(fx.work);
      expect(staged).toContain("with space.txt");
      expect(staged).toContain("newdir/sub/n.txt");
      expect(staged).not.toContain("modified.txt");
    });

    it("prints git status after staging", () => {
      const r = runFza(fx.work, { select: ["modified.txt"] });
      expect(r.output).toContain("M  modified.txt");
    });

    it("stages nothing when fzf is cancelled", () => {
      const before = stagedFiles(fx.work);
      const r = runFza(fx.work, { exit: 130 });
      expect(r.exitCode).toBe(0);
      expect(stagedFiles(fx.work)).toEqual(before);
    });

    it("stages nothing on an empty selection", () => {
      const before = stagedFiles(fx.work);
      const r = runFza(fx.work, { select: [] });
      expect(r.exitCode).toBe(0);
      expect(stagedFiles(fx.work)).toEqual(before);
    });
  });
```

- [ ] **Step 2: Run the spec and confirm it fails**

Run: `mise run -C assets integration bin gitx-fza`
Expected: all four `picker` specs FAIL (no header, preview or bind args yet), and `prints git status after staging` FAILS. The other `staging` specs already pass with the Task 1 code; they're regression guards.

- [ ] **Step 3: Write the full `fza)` picker**

Replace the whole `fza)` case in `config/bin/gitx` with:

```zsh
  fza)
    # The keymap lives in a bordered header so every binding is visible.
    keys='select  tab toggle  ⇧tab toggle↑  ^a all  ^d none'$'\n'
    keys+='act     enter add  ^p patch  ^/ preview  esc cancel'

    # Untracked files have no index entry, so diff them against /dev/null.
    preview='[[ {1} == "??" ]] && git diff --no-index --color=always -- /dev/null {2}; git diff --color=always -- {2}'

    selected=$(_gitx_add_candidates | fzf --multi --ansi \
      --delimiter=$'\t' --accept-nth=2 \
      --header="$keys" --header-border=rounded --header-label=' keys ' \
      --color='header:bold,header-border:dim' \
      --prompt='add ❯ ' \
      --preview="$preview" \
      --preview-window='right,60%,border-left,nohidden' \
      --bind='ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview' \
      --bind='ctrl-p:become(git add -p -- {+2})') || exit 0

    [[ -z "$selected" ]] && exit 0
    git add -- "${(@f)selected}" && git status -s
    ;;
```

`nohidden` keeps the preview open on start even if the user's `FZF_DEFAULT_OPTS` sets `hidden`.

- [ ] **Step 4: Run the spec and confirm it passes**

Run: `mise run -C assets integration bin gitx-fza`
Expected: `10 pass, 0 fail`.

- [ ] **Step 5: Commit**

```bash
git add config/bin/gitx assets/integration/bin/gitx-fza.spec.ts
git commit -m "feat(bin): Show keymap and diff preview in gitx fza"
```

---

### Task 3: Guards (no repo, nothing to add, missing fzf)

**Files:**
- Modify: `assets/integration/bin/gitx-fza.spec.ts` (new top-level `describe`)
- Modify: `config/bin/gitx` (`fza)` case)

- [ ] **Step 1: Write the failing guard specs**

In `gitx-fza.spec.ts`, change the fixture import to:

```ts
import { type AddFixture, gitEnv, makeAddFixture, makeCleanRepo, makeNonRepo, stagedFiles } from "./support/add-fixture";
```

Append at the end of the file, outside `describe("gitx fza")`:

```ts
describe("gitx fza guards", () => {
  it("says there is nothing to add in a clean repo without opening fzf", () => {
    const fx = makeCleanRepo();
    try {
      const r = runFza(fx.work);
      expect(r.exitCode).toBe(0);
      expect(r.output).toContain("Nothing to add");
      expect(r.args).toBe("");
    } finally {
      fx.cleanup();
    }
  });

  it("fails outside a git repository", () => {
    const fx = makeNonRepo();
    try {
      const r = runFza(fx.work);
      expect(r.exitCode).toBe(1);
      expect(r.output).toContain("Not a git repository");
      expect(r.args).toBe("");
    } finally {
      fx.cleanup();
    }
  });
});
```

`r.args` is `""` exactly when the stub fzf never ran, because `runFza` deletes the log files before each run.

- [ ] **Step 2: Run the spec and confirm it fails**

Run: `mise run -C assets integration bin gitx-fza`
Expected: both guard specs FAIL. fzf currently opens on empty input, the exit code is 0 outside a repo, and neither message is printed.

- [ ] **Step 3: Add the guards**

In `config/bin/gitx`, change the beginning of the `fza)` case from:

```zsh
  fza)
    # The keymap lives in a bordered header so every binding is visible.
```

to:

```zsh
  fza)
    h::needs_command fzf
    git rev-parse --git-dir &>/dev/null || { h::puts error "Not a git repository"; exit 1; }
    candidates=$(_gitx_add_candidates)
    [[ -z "$candidates" ]] && { h::puts info "Nothing to add"; exit 0; }

    # The keymap lives in a bordered header so every binding is visible.
```

Then change the head of the pipeline from:

```zsh
    selected=$(_gitx_add_candidates | fzf --multi --ansi \
```

to:

```zsh
    selected=$(print -r -- "$candidates" | fzf --multi --ansi \
```

- [ ] **Step 4: Run the spec and confirm it passes**

Run: `mise run -C assets integration bin gitx-fza`
Expected: `12 pass, 0 fail`.

- [ ] **Step 5: Commit**

```bash
git add config/bin/gitx assets/integration/bin/gitx-fza.spec.ts
git commit -m "feat(bin): Guard gitx fza against empty and non-repo runs"
```

---

### Task 4: Help text, full gate, manual pass

**Files:**
- Modify: `config/bin/gitx` (the `#USAGE cmd "fza"` line)

- [ ] **Step 1: Update the USAGE help**

Replace:

```zsh
#USAGE cmd "fza" help="Fzf git add"
```

with:

```zsh
#USAGE cmd "fza" help="Fzf picker: tab-toggle unstaged/untracked files to git add (keys shown in header)"
```

- [ ] **Step 2: Run the full bin gate**

Run: `mise run -C assets test bin`
Expected: the BDD and integration suites both pass, including `gitx.spec.ts` (4 pass, unchanged) and `gitx-fza.spec.ts` (12 pass).

- [ ] **Step 3: Manual pass with real fzf**

Build a scratch repo:

```bash
cd "$(mktemp -d)" && git init -q -b main && for f in a b c; do echo base > $f.txt; done \
  && git add -A && git commit -qm init && echo x >> a.txt && rm b.txt && mkdir -p d/e && echo n > d/e/n.txt
```

Run `gitx fza` and check each item:

- [ ] The `keys` box shows both lines, and the preview is **open on start**
- [ ] The preview shows the diff for `a.txt`, the deletion for `b.txt`, and the full new content of `d/e/n.txt`
- [ ] `Tab` / `Shift-Tab` toggle a file and move; `^a` / `^d` select all / none
- [ ] `^/` hides and reshows the preview
- [ ] `Enter` with `a.txt` and `d/e/n.txt` selected stages both and prints `git status -s`
- [ ] `^p` on `a.txt` hands over to `git add -p`
- [ ] `Esc` stages nothing

- [ ] **Step 4: Commit**

```bash
git add config/bin/gitx
git commit -m "docs(bin): Describe gitx fza picker in usage help"
```

---

## Spec Coverage

| design.md section | Task |
| ----------------- | ---- |
| §3.1 `_gitx_add_candidates` (Y filter, renames, untracked expansion) | 1 |
| §3.2 picker args, keys header, preview `nohidden` | 2 |
| §3.3 keymap bindings | 2 (args), 4 (manual) |
| §4 data flow (`Enter` stages and prints status, `Esc` exits) | 2 |
| §5 edge cases (no fzf, not a repo, nothing to add, empty selection, spaces) | 2, 3 |
| §5 `^p` skips untracked files | 4 (manual, documented limitation) |
| §6 testing and gate | 1–4 |
