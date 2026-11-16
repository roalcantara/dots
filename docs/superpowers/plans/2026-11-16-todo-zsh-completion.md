# todo zsh Completion and fzf-tab Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `todo <Tab>` completes commands, flags, task IDs and tags through fzf-tab instead of erroring, and the
fzf-tab setup follows fzf-tab's README.

**Architecture:** two hand-written autoload helpers read `./TODO.yaml` through the `todo` CLI; a bash script
regenerates `_todo` from `todo completion zsh` and points its `_default` placeholders at the helpers or at fixed
value lists; the committed `_todo` sits in `config/zsh/opt/completions`, ahead of zsh's `_devtodo` on `$fpath`.
Then the zstyles are aligned and a `todo` preview is added.

**Tech Stack:** zsh completion system (`_arguments`, `_describe`, `_values`, compinit), fzf-tab, bash, mise tasks,
Bun test.

**Spec:** [`docs/superpowers/specs/2026-11-16-todo-zsh-completion-design.md`](../specs/2026-11-16-todo-zsh-completion-design.md)

## Global Constraints

- Branch `chore/add-todos` (already checked out). No worktree, no push, no PR.
- Every git call through `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`; stage named paths
  only (never `git add -A` / `.`); one commit per task; Conventional Commits with a capitalised description, ending
  with `Co-Authored-By: DeepSeek V4.1 Flash <noreply@deepseek.com>`.
- `todo` is RayanBO/todo 0.2.9 at `$CARGO_HOME/bin/todo` (`~/.local/share/cargo/bin/todo`). If your shell does not
  find it, prefix commands with `PATH="$PATH:$HOME/.local/share/cargo/bin"`; never install another `todo`.
- `todo` reads only `./TODO.yaml` (with `./.todo/config` = `yaml`) or `./TODO.md`; elsewhere it prints
  `Error: ./TODO.md not found. Run \`todo init\` first.` to stderr and exits 1.
- Do not edit or delete zsh's `_devtodo`, anything under `~/.local/state/zim/`, or `/opt/homebrew/`.
- Tab inside the fzf-tab list keeps its behaviour: `zstyle ':fzf-tab:*' continuous-trigger tab` stays.
- Before Task 1, capture the zsh parity baseline from the unchanged config: `mise run zsh:baseline`.

## Review Focus

1. **No TODO file in the current directory:** Tab must offer nothing and print nothing (no `Error: ./TODO.md not
   found` on the prompt). Task 1 Step 1 asserts empty stdout and stderr.
2. **Descriptions with colons or quotes** (`Series: account-wide…`, `Preflight: publish 'zsh doesn't split $vars'`):
   the ID must still map to the whole description. Task 1 Step 1 asserts the `S1` line verbatim.
3. **`todo` upgraded and a placeholder moved:** the generator must fail, naming the placeholder, not write a
   half-patched `_todo`. Task 2 Step 1 asserts it with a fake `todo`.
4. **A stale `.zcompdump` keeping `_devtodo`:** zim rebuilds its dump when `$fpath` files change; Task 4's manual
   check runs in a new terminal and Task 2 asserts the binding with a fresh `compinit`.
5. **`menu no` changing other completions** (`cd`, `git checkout`, `mise install`): covered only by Task 4's manual
   check, which the owner runs.

---

### Task 1: Task-ID and tag helpers

**Files:**

- Create: `config/zsh/opt/completions/_todo_task_ids`, `config/zsh/opt/completions/_todo_tags`
- Create: `test/integration/bootstrap/todo-completion.spec.ts`

**Interfaces:**

- Produces: zsh functions `_todo_task_ids` and `_todo_tags`, autoloadable from `$fpath` (first line `#autoload`, no
  `#compdef`), no arguments, run in the current directory.
  - `_todo_task_ids`: one entry per task of `todo list --tasks`, built as `"<id>:<description>"` in a local array,
    passed as `_describe -t tasks 'task' <array-name>`. Lines look like `[x] [high] P1 — Omarchy-ish macOS`
    (indented two spaces): a status in brackets, an optional `[priority]`, the id, an em dash (U+2014) between
    single spaces, the description.
  - `_todo_tags`: tag names from `todo tags` (lines like `post     1`, indented two spaces), passed as
    `_values -s , 'tag' <names…>`.
  - Both: stderr of `todo` discarded; with no tasks or tags, return 1 without calling `_describe` / `_values`.

- [ ] **Step 1: Write the failing spec.** Helpers: `TODO_BIN` = `Bun.which("todo", { PATH: process.env.PATH +
  ":" + (process.env.CARGO_HOME ?? HOME + "/.local/share/cargo") + "/bin" })`; `fixtureDir()` makes a temp dir with
  a copy of `test/integration/blog/fixtures/TODO.yaml` and `.todo/config` containing `yaml`; `run(dir, script)`
  spawns `zsh -fc` with `cwd: dir`, `PATH` including `dirname(TODO_BIN)`, and a prelude:
  `fpath=(<repo>/config/zsh/opt/completions $fpath); autoload -Uz _todo_task_ids _todo_tags;`
  `_describe() { print -rl -- "${(@P)argv[-1]}" }; _values() { print -rl -- "${@[4,-1]}" }`.
  `describe.skipIf(!TODO_BIN)("todo completion helpers", …)`:

```ts
it("_todo_task_ids lists every task as id:description", () => {
  const out = run(fixtureDir(), "_todo_task_ids").stdout.split("\n").filter(Boolean);
  const tasks = (Bun.YAML.parse(readFileSync(FIXTURE, "utf8")) as { tasks: unknown[] }).tasks;
  expect(out).toHaveLength(tasks.length);
  expect(out).toContain("P1:Omarchy-ish macOS");
  expect(out).toContain("S1:Series: account-wide numbers and decisions");
});
it("_todo_tags lists the tags in use", () => {
  expect(run(fixtureDir(), "_todo_tags").stdout.split("\n").filter(Boolean)).toEqual(
    expect.arrayContaining(["post", "series", "topic-1"]));
});
it("both stay silent without a TODO file", () => {
  const r = run(mkdtempSync(join(tmpdir(), "todo-none-")), "_todo_task_ids; a=$?; _todo_tags; print $a $?");
  expect(r.stdout.trim()).toBe("1 1");
  expect(r.stderr).toBe("");
});
```

- [ ] **Step 2: Run, expect FAIL** (functions not found).
  Run: `mise run -C test integration bootstrap todo-completion` → fails in all 3 cases.
- [ ] **Step 3: Write `_todo_task_ids` and `_todo_tags`** to the interface above (zsh; `local` everything; parse with
  a zsh pattern or `${(f)"$(todo … 2>/dev/null)"}` and `[[ $line =~ … ]]`).
- [ ] **Step 4: Run, expect PASS.** Same command → 3 pass.
- [ ] **Step 5: Commit**

```bash
g add config/zsh/opt/completions/_todo_task_ids config/zsh/opt/completions/_todo_tags test/integration/bootstrap/todo-completion.spec.ts
g commit -m "feat(zsh): Complete todo task IDs and tags from ./TODO.yaml"
```

### Task 2: Generated `_todo` and its task

**Files:**

- Create: `script/todo-completion.sh`, `config/zsh/opt/completions/_todo` (generated)
- Modify: `mise.toml` (a task after `[tasks."zsh:bench"]`), `test/integration/bootstrap/todo-completion.spec.ts`

**Interfaces:**

- Consumes: `_todo_task_ids`, `_todo_tags` (Task 1).
- Produces: `script/todo-completion.sh <out>` (bash, `set -euo pipefail`, shellcheck-clean): runs
  `todo completion zsh`, applies the substitutions below, keeps `#compdef todo` as line 1 and inserts as line 2
  ``# Generated by script/todo-completion.sh (mise run zsh:completions:todo) from `todo completion zsh`; do not edit.``,
  writes `<out>` only when every substitution matched at least once; otherwise exits 1 with
  `todo-completion: placeholder not found: <literal>` on stderr and leaves `<out>` untouched.
  Task `[tasks."zsh:completions:todo"]`, description `Regenerate config/zsh/opt/completions/_todo from the todo CLI`,
  run `./script/todo-completion.sh config/zsh/opt/completions/_todo`.

Substitutions (literal text of `todo completion zsh` 0.2.9 → replacement):

| Literal | Replacement |
| --- | --- |
| `:id -- ID of the item:_default` | `:id -- ID of the item:_todo_task_ids` |
| `:id -- ID of the item to delete:_default` | `:id -- ID of the item to delete:_todo_task_ids` |
| `:id -- ID of the task:_default` | `:id -- ID of the task:_todo_task_ids` |
| `:TASK_ID:_default` | `:TASK_ID:_todo_task_ids` |
| `:TAG:_default` | `:TAG:_todo_tags` |
| `:PRIORITY:_default` | `:PRIORITY:(low medium high)` |
| `:SET:_default` | `:SET:(todo en-cours done bloqued)` |
| `md or yaml:_default` | `md or yaml:(md yaml)` |

- [ ] **Step 1: Add the failing cases** to the spec:

```ts
it("compinit binds todo to _todo, not zsh's _devtodo", () => {
  const r = Bun.spawnSync(["zsh", "-fc",
    `fpath=(${COMPLETIONS} $fpath); autoload -Uz compinit; compinit -D -u; print $_comps[todo]`]);
  expect(r.stdout.toString().trim()).toBe("_todo");
});
it("the committed _todo is what the generator writes", () => {
  const out = join(mkdtempSync(join(tmpdir(), "todo-gen-")), "_todo");
  expect(gen(out).exitCode).toBe(0);
  expect(readFileSync(out, "utf8")).toBe(readFileSync(join(COMPLETIONS, "_todo"), "utf8"));
});
it("the generator fails, naming the placeholder, when todo's output changes", () => {
  // a fake `todo` first on PATH that prints only "#compdef todo"
  const out = join(mkdtempSync(join(tmpdir(), "todo-gen-")), "_todo");
  const r = gen(out, fakeTodoDir);
  expect(r.exitCode).toBe(1);
  expect(r.stderr.toString()).toContain("placeholder not found: :id -- ID of the item:_default");
  expect(existsSync(out)).toBe(false);
});
```

  `gen(out, prependDir?)` spawns `<repo>/script/todo-completion.sh out` with `PATH` = `prependDir` (if any), the
  `todo` dir, then `process.env.PATH`. The compinit case does not need `todo` (put it outside the `skipIf`, under
  `describe.skipIf(!Bun.which("zsh"))`).

- [ ] **Step 2: Run, expect FAIL** → the 3 new cases fail (`_devtodo`; script missing).
- [ ] **Step 3: Write `script/todo-completion.sh`**, make it executable (`chmod +x`), add the mise task.
- [ ] **Step 4: Generate:** `mise run zsh:completions:todo`, then
  `grep -c '_todo_task_ids\|_todo_tags\|(low medium high)\|(todo en-cours done bloqued)\|(md yaml)' config/zsh/opt/completions/_todo`
  → 12 (4 task-ID, 3 tag, 3 priority, 1 set, 1 format) and `grep -c ':_default' …/_todo` → 18 (of the 30
  generated; the free-text flags keep `_default`).
- [ ] **Step 5: Run, expect PASS.** `mise run -C test integration bootstrap todo-completion` → 6 pass.
- [ ] **Step 6: Commit**

```bash
g add script/todo-completion.sh config/zsh/opt/completions/_todo mise.toml test/integration/bootstrap/todo-completion.spec.ts
g commit -m "feat(zsh): Generate todo's completion, which replaces zsh's _devtodo"
```

### Task 3: fzf-tab alignment and the todo preview

**Files:**

- Modify: `config/zsh/opt/rc.d/zim.zsh:71-72` (in `zim::overrides`), `config/zsh/opt/rc.d/env.zsh:99`,
  `config/zsh/opt/plugins/fzf-tab.zsh` (lines 95, 105, 117, 158, and a new preview)
- Create: `test/integration/bootstrap/fzf-tab-styles.spec.ts`

**Interfaces:**

- Consumes: `todo list --tasks` output format (Task 1).
- Produces: effective zstyles of an interactive zsh, as asserted below.

- [ ] **Step 1: Write the failing spec.** `styles(script)` spawns
  `env -i HOME=$HOME TERM=xterm-256color ZDOTDIR=$HOME/.config/zsh zsh -ic "<script>"` (as
  `script/zsh-verify.sh` does) and returns stdout; `describe.skipIf(!existsSync(join(HOME, ".config/zsh/.zshrc")))`.

```ts
it("zsh's own menu is off, per fzf-tab", () =>
  expect(styles(`zstyle -s ':completion:*' menu m; print -r -- $m`).trim()).toBe("no"));
it("descriptions carry no escape sequences, so fzf-tab can group", () =>
  expect(styles(`zstyle -s ':completion:*:descriptions' format f; print -r -- $f`).trim()).toBe("[%d]"));
it("list-colors is split into entries", () =>
  expect(Number(styles(`zstyle -a ':completion:*' list-colors c; print $#c`).trim())).toBeGreaterThan(1));
it("Tab keeps continuing; the dead tab:accept bind is gone", () => {
  expect(styles(`zstyle -s ':fzf-tab:*' continuous-trigger t; print -r -- $t`).trim()).toBe("tab");
  expect(styles(`zstyle -a ':fzf-tab:*' fzf-flags f; print -rl -- $f`)).not.toContain("--bind=tab:accept");
});
it("no zstyles fzf-tab never reads", () => {
  expect(styles(`zstyle -L ':fzf-tab:complete:*' menu; zstyle -L ':fzf-tab:*' list-colors`).trim()).toBe("");
});
it("previews: todo task details and mise tool info", () => {
  expect(styles(`zstyle -L ':fzf-tab:complete:todo*:*' fzf-preview`)).toContain("todo list --tasks");
  expect(styles(`zstyle -L ':fzf-tab:complete:mise:argument-rest' fzf-preview`)).toContain("mise tool");
});
```

- [ ] **Step 2: Run, expect FAIL.** `mise run -C test integration bootstrap fzf-tab-styles` → all but the
  continuous-trigger half fail.
- [ ] **Step 3: Edit.**
  - `zim.zsh` `zim::overrides`: `zstyle ':completion:*' menu select=2` → `zstyle ':completion:*' menu no`, and add
    `zstyle ':completion:*:descriptions' format '[%d]'`; reword the comment above to say both follow fzf-tab's README
    (zsh's menu would compete with fzf-tab; escape sequences in the descriptions format disable its groups).
  - `env.zsh:99`: `list-colors "$LS_COLORS"` → `list-colors ${(s.:.)LS_COLORS}`.
  - `fzf-tab.zsh`: delete `zstyle ':fzf-tab:complete:*' menu no` (95) and `zstyle ':fzf-tab:*' list-colors …` (105);
    remove `--bind=tab:accept` from the `fzf-flags` line (117), keeping the other two binds; line 158's preview
    becomes `'mise tool $word'` (fix the two comment lines above it to match).
  - `fzf-tab.zsh`, new block after the brew preview: context `':fzf-tab:complete:todo*:*'`; preview prints the
    block of `todo list --tasks 2>/dev/null` from the line containing ` $word — ` up to the next task line, and
    otherwise `todo $word --help 2>/dev/null` (a subcommand); comment: a task ID shows the task, a subcommand its help.
- [ ] **Step 4: Run, expect PASS.** Same command → 6 pass. Then `mise run zsh:verify`: syntax OK; parity may report
  diffs only under `### FUNCTIONS` (new `_todo*` names); anything else is a failure to fix.
- [ ] **Step 5: Commit**

```bash
g add config/zsh/opt/rc.d/zim.zsh config/zsh/opt/rc.d/env.zsh config/zsh/opt/plugins/fzf-tab.zsh test/integration/bootstrap/fzf-tab-styles.spec.ts
g commit -m "fix(zsh): Align the fzf-tab setup with its README and preview todo tasks"
```

### Task 4: Gates and the owner's check

- [ ] **Step 1:** `mise run test:specs` → exit 0; `hk check --all` → exit 0; `mise run zsh:verify` → syntax OK and
  parity diffs only under `### FUNCTIONS` (quote the diff lines in the handoff).
- [ ] **Step 2: Owner checkpoint (stop and ask; do not tick for the owner).** Ask the owner to open a new terminal in
  the repo root and try, reporting what each shows: `todo <Tab>` (subcommands, no error), `todo status <Tab>`
  (tasks with descriptions, preview), `todo list --priority <Tab>` (`low medium high`), `todo add --tag <Tab>`,
  `git checkout <Tab>`, `cd <Tab>` (eza preview), `mise install <Tab>` (`mise tool` preview), and Tab inside a list
  (accepts and continues). Also `cd /tmp; todo status <Tab>`: nothing offered, no error.
- [ ] **Step 3:** Tick this plan's boxes except Step 2, commit (`docs(plans): Tick the todo completion plan`),
  then `/wip:handoff plan=docs/superpowers/plans/2026-11-16-todo-zsh-completion.md`.
