# `xc-skills collect` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `collect` subcommand to `xc-skills` that brings regular files from agent directories into a central source, then replaces each original with a symlink back to source.

**Architecture:** `cmd_collect()` mirrors `cmd_sync()` in structure — parses flags, builds inspection list, iterates entries. When no `-a`/`-t` is given it walks all entries in `AGENT_GLOBAL_PATH` (or `AGENT_PROJECT_PATH` with `-l`), silently skipping absent dirs. Tests are added as new `describe` blocks in the existing `tests/xc-skills.spec.ts`, new scenario IDs added to `mise.toml`.

**Tech Stack:** bash 5 (`#!/usr/bin/env bash`), Bun test runner, mise task runner.

---

### Task 1: Write failing tests for `collect`

**Files:**

- Modify: `tests/xc-skills.spec.ts`
- Modify: `mise.toml`

- [ ] **Step 1: Add 15 new `describe` blocks to `tests/xc-skills.spec.ts`**

Append inside the outer `describe("xc-skills", ...)` block, after the last sync scenario:

```typescript
// ── collect_no_source ────────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_no_source"))(
  "collect: when source dir does not exist",
  () => {
    it("creates source dir and completes", () => {
      const src = makeTmpSourceDir({ "skill.md": "/some/target.md" });
      const fakeHome = makeTmpDir("xc-skills-home-");
      // Build an agent dir with a real file in the resolved global path
      const agentDir = join(fakeHome, ".gemini/antigravity/skills");
      mkdirSync(agentDir, { recursive: true });
      writeFileSync(join(agentDir, "new-skill.md"), "content");
      const customSrc = join(fakeHome, "new-source");
      try {
        const r = run(["collect", "-s", customSrc, "-a", "antigravity"], {
          env: { HOME: fakeHome },
        });
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("copied=1");
      } finally {
        rmSync(fakeHome, { recursive: true, force: true });
        rmSync(src, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_copies_file ──────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_copies_file"))(
  "collect: when agent dir has a regular file",
  () => {
    it("copies to source and replaces with symlink", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const agentDir = makeTmpDir("xc-skills-agent-");
      writeFileSync(join(agentDir, "skill.md"), "my skill");
      try {
        const r = run(["collect", "-s", srcDir, "-t", agentDir]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("copied=1");
        expect(r.stdout).toContain("linked=0");
        // source now has the file
        expect(Bun.file(join(srcDir, "skill.md")).size).toBeGreaterThan(0);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(agentDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_conflict_links ───────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_conflict_links"))(
  "collect: when file already exists in source",
  () => {
    it("skips copy but still creates symlink in agent dir", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      writeFileSync(join(srcDir, "skill.md"), "source version");
      const agentDir = makeTmpDir("xc-skills-agent-");
      writeFileSync(join(agentDir, "skill.md"), "agent version");
      try {
        const r = run(["collect", "-s", srcDir, "-t", agentDir]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("linked=1");
        expect(r.stdout).toContain("copied=0");
        expect(r.stderr).toMatch(/conflict|already exists|skipping copy/i);
        // source retains original
        expect(await Bun.file(join(srcDir, "skill.md")).text()).toBe("source version");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(agentDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_skips_symlink ────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_skips_symlink"))(
  "collect: when entry in agent dir is already a symlink",
  () => {
    it("skips it entirely", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const agentDir = makeTmpDir("xc-skills-agent-");
      symlinkSync("/some/path.md", join(agentDir, "skill.md"));
      try {
        const r = run(["collect", "-s", srcDir, "-t", agentDir]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("skipped_symlink=1");
        expect(r.stdout).toContain("copied=0");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(agentDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_skips_missing_dir ────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_skips_missing_dir"))(
  "collect: when an agent directory does not exist",
  () => {
    it("silently skips it", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const fakeHome = makeTmpDir("xc-skills-home-");
      // antigravity global dir does NOT exist under fakeHome
      try {
        const r = run(["collect", "-s", srcDir, "-a", "antigravity"], {
          env: { HOME: fakeHome },
        });
        expect(r.exitCode).toBe(0);
        expect(r.stderr).toBe("");
        // no "Agent:" lines since dir was skipped
        expect(r.stdout).not.toContain("Agent:");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(fakeHome, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_dry_run ──────────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_dry_run"))(
  "collect: when --dry-run is passed",
  () => {
    it("prints actions and makes no filesystem changes", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const agentDir = makeTmpDir("xc-skills-agent-");
      writeFileSync(join(agentDir, "skill.md"), "content");
      try {
        const r = run(["collect", "--dry-run", "-s", srcDir, "-t", agentDir]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[dry-run]");
        // agent dir still has regular file (not replaced)
        const entries = Array.from(
          new Bun.Glob("*").scanSync({ cwd: srcDir, onlyFiles: false }),
        );
        expect(entries.length).toBe(0);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(agentDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_agent_global ─────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_agent_global"))(
  "collect: when -a antigravity is given (global)",
  () => {
    it("inspects $HOME/.gemini/antigravity/skills", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const fakeHome = makeTmpDir("xc-skills-home-");
      const agentDir = join(fakeHome, ".gemini/antigravity/skills");
      mkdirSync(agentDir, { recursive: true });
      writeFileSync(join(agentDir, "skill.md"), "content");
      try {
        const r = run(["collect", "-s", srcDir, "-a", "antigravity"], {
          env: { HOME: fakeHome },
        });
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain(agentDir);
        expect(r.stdout).toContain("copied=1");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(fakeHome, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_agent_local ──────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_agent_local"))(
  "collect: when -a antigravity -l is given",
  () => {
    it("inspects $PWD/.agents/skills", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const cwd = makeTmpDir("xc-skills-cwd-");
      const agentDir = join(cwd, ".agents/skills");
      mkdirSync(agentDir, { recursive: true });
      writeFileSync(join(agentDir, "skill.md"), "content");
      try {
        const r = run(["collect", "-s", srcDir, "-a", "antigravity", "-l"], { cwd });
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain(agentDir);
        expect(r.stdout).toContain("copied=1");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(cwd, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_multi_agent ──────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_multi_agent"))(
  "collect: when multiple -a agents are given",
  () => {
    it("inspects each resolved agent dir", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const fakeHome = makeTmpDir("xc-skills-home-");
      for (const rel of [".gemini/antigravity/skills", ".cursor/skills"]) {
        const d = join(fakeHome, rel);
        mkdirSync(d, { recursive: true });
        writeFileSync(join(d, `${rel.split("/")[1]}-skill.md`), "content");
      }
      try {
        const r = run(
          ["collect", "-s", srcDir, "-a", "antigravity", "-a", "cursor"],
          { env: { HOME: fakeHome } },
        );
        expect(r.exitCode).toBe(0);
        const agentLines = r.stdout.split("\n").filter((l) => l.startsWith("Agent:"));
        expect(agentLines.length).toBe(2);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(fakeHome, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_explicit_target ──────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_explicit_target"))(
  "collect: when -t is given",
  () => {
    it("inspects that explicit directory", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const targetDir = makeTmpDir("xc-skills-target-");
      writeFileSync(join(targetDir, "skill.md"), "content");
      try {
        const r = run(["collect", "-s", srcDir, "-t", targetDir]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain(targetDir);
        expect(r.stdout).toContain("copied=1");
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(targetDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_all_agents ───────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_all_agents"))(
  "collect: when no -a or -t is given",
  () => {
    it("inspects all known agent dirs, skipping absent ones", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const fakeHome = makeTmpDir("xc-skills-home-");
      // Create just one agent dir
      const agentDir = join(fakeHome, ".gemini/antigravity/skills");
      mkdirSync(agentDir, { recursive: true });
      writeFileSync(join(agentDir, "skill.md"), "content");
      try {
        const r = run(["collect", "-s", srcDir], { env: { HOME: fakeHome } });
        expect(r.exitCode).toBe(0);
        // At least one Agent: line for antigravity
        expect(r.stdout).toContain(agentDir);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(fakeHome, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_source_once ──────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_source_once"))(
  "collect: when --source is given more than once",
  () => {
    it("exits with error", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      try {
        const r = run(["collect", "-s", srcDir, "-s", srcDir]);
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toMatch(/source.*once|once.*source/i);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_local_once ───────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_local_once"))(
  "collect: when --local is given more than once",
  () => {
    it("exits with error", () => {
      const srcDir = makeTmpDir("xc-skills-src-");
      const targetDir = makeTmpDir("xc-skills-target-");
      try {
        const r = run(["collect", "-s", srcDir, "-t", targetDir, "-l", "-l"]);
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toMatch(/local.*once|once.*local/i);
      } finally {
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(targetDir, { recursive: true, force: true });
      }
    });
  },
);

// ── collect_unknown_agent ────────────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_unknown_agent"))(
  "collect: when an unknown agent is given",
  () => {
    it("exits with error mentioning the agent name", () => {
      const r = run(["collect", "-a", "no-such-agent-xyz"]);
      expect(r.exitCode).toBe(1);
      expect(r.stderr).toContain("no-such-agent-xyz");
    });
  },
);

// ── collect_source_not_writable ──────────────────────────────────────────────

describe.skipIf(skipWhenOtherScenario("collect_source_not_writable"))(
  "collect: when the source directory is not writable",
  () => {
    it("exits with error", () => {
      if (process.getuid?.() === 0) return;
      const srcDir = makeTmpDir("xc-skills-src-");
      const agentDir = makeTmpDir("xc-skills-agent-");
      writeFileSync(join(agentDir, "skill.md"), "content");
      chmodSync(srcDir, 0o555);
      try {
        const r = run(["collect", "-s", srcDir, "-t", agentDir]);
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toMatch(/not writable|cannot write/i);
      } finally {
        chmodSync(srcDir, 0o755);
        rmSync(srcDir, { recursive: true, force: true });
        rmSync(agentDir, { recursive: true, force: true });
      }
    });
  },
);
```

- [ ] **Step 2: Add collect scenario IDs to `mise.toml`**

In the `xc-skills:specs` task, extend the `choices` line to include:

```
"collect_no_source" "collect_copies_file" "collect_conflict_links"
"collect_skips_symlink" "collect_skips_missing_dir" "collect_dry_run"
"collect_agent_global" "collect_agent_local" "collect_multi_agent"
"collect_explicit_target" "collect_all_agents" "collect_source_once"
"collect_local_once" "collect_unknown_agent" "collect_source_not_writable"
```

- [ ] **Step 3: Run tests to confirm all collect scenarios fail (not yet implemented)**

```sh
cd /Users/roalcantara/Work/dots/config/bin
mise run xc-skills:specs --scenario collect_copies_file
```

Expected: FAIL — `collect` subcommand not yet defined.

---

### Task 2: Implement `cmd_collect` in `xc-skills`

**Files:**

- Modify: `xc-skills`

- [ ] **Step 1: Update the `#?` docblock** — add `collect` to Usage and Subcommands sections:

```bash
#? Usage:
#?   xc-skills sync  [--dry-run] [--prune] [-s|--source PATH]
#?                   [-a|--agent <agent>]... [-t|--target <path>]... [-l|--local]
#?   xc-skills collect [--dry-run] [-s|--source PATH]
#?                   [-a|--agent <agent>]... [-t|--target <path>]... [-l|--local]
#?   xc-skills -h | --help
#?
#? Subcommands:
#?   sync     Mirror symlinks from source to one or more target or agent paths
#?   collect  Bring regular files from agent dirs into source; replace with symlinks
```

- [ ] **Step 2: Add `cmd_collect()` function** — insert before `main()`:

```bash
# ── collect command ───────────────────────────────────────────────────────────

cmd_collect() {
  local dry_run=0
  local local_flag=0
  local local_flag_count=0
  local explicit_source=""
  local explicit_source_count=0
  local agents=()
  local explicit_targets=()

  while (($# > 0)); do
    case "$1" in
      --dry-run) dry_run=1 ;;
      -s|--source)
        shift
        if (($# == 0)); then err "--source requires a PATH argument"; usage >&2; exit 1; fi
        explicit_source_count=$((explicit_source_count + 1))
        if ((explicit_source_count > 1)); then err "--source can only be given once"; exit 1; fi
        explicit_source="$1"
        ;;
      -a|--agent)
        shift
        if (($# == 0)); then err "--agent requires a NAME argument"; usage >&2; exit 1; fi
        agents+=("$1")
        ;;
      -t|--target)
        shift
        if (($# == 0)); then err "--target requires a PATH argument"; usage >&2; exit 1; fi
        explicit_targets+=("$1")
        ;;
      -l|--local)
        local_flag_count=$((local_flag_count + 1))
        if ((local_flag_count > 1)); then err "--local can only be given once"; exit 1; fi
        local_flag=1
        ;;
      -h|--help) usage; exit 0 ;;
      -*) err "Unknown option: $1"; usage >&2; exit 1 ;;
      *)  err "Unexpected argument: $1"; usage >&2; exit 1 ;;
    esac
    shift
  done

  # ── resolve source ──────────────────────────────────────────────────────────

  local source_dir="${explicit_source:-$HOME/.agents/skills}"

  if ! run_cmd /bin/mkdir -p "$source_dir"; then
    err "Cannot create source directory: $source_dir"
    exit 1
  fi

  if [[ ! -w "$source_dir" ]]; then
    err "Source directory is not writable: $source_dir"
    exit 1
  fi

  # ── validate agents ─────────────────────────────────────────────────────────

  local base_pwd="$PWD"
  for agent in "${agents[@]}"; do
    if ! resolve_agent_path "$agent" "$local_flag" "$base_pwd" >/dev/null 2>&1; then
      err "Unknown agent: $agent"
      exit 1
    fi
  done

  # ── build inspection list ───────────────────────────────────────────────────

  local inspect_dirs=()

  if [[ ${#agents[@]} -eq 0 && ${#explicit_targets[@]} -eq 0 ]]; then
    # All known agents — global or local; skip absent dirs
    local table_ref
    if ((local_flag)); then
      declare -n table_ref=AGENT_PROJECT_PATH
    else
      declare -n table_ref=AGENT_GLOBAL_PATH
    fi
    for agent in "${!table_ref[@]}"; do
      local resolved
      resolved=$(resolve_agent_path "$agent" "$local_flag" "$base_pwd")
      [[ -d "$resolved" ]] && inspect_dirs+=("$resolved")
    done
  else
    for agent in "${agents[@]}"; do
      local resolved
      resolved=$(resolve_agent_path "$agent" "$local_flag" "$base_pwd")
      [[ -d "$resolved" ]] && inspect_dirs+=("$resolved")
    done
    for target in "${explicit_targets[@]}"; do
      [[ -d "$target" ]] && inspect_dirs+=("$target")
    done
  fi

  # ── collect ─────────────────────────────────────────────────────────────────

  local overall_errors=0

  for inspect_dir in "${inspect_dirs[@]}"; do
    local copied=0 linked=0 skipped_symlink=0 skipped_other=0 errors=0

    shopt -s nullglob
    local entries=("$inspect_dir"/*)
    shopt -u nullglob

    for entry in "${entries[@]}"; do
      local name="${entry##*/}"
      local src_file="$source_dir/$name"

      # Already a symlink — skip
      if [[ -L "$entry" ]]; then
        skipped_symlink=$((skipped_symlink + 1))
        continue
      fi

      # Not a regular file — skip with warning
      if [[ ! -f "$entry" ]]; then
        skipped_other=$((skipped_other + 1))
        warn "Not a regular file, skipping: $entry"
        continue
      fi

      # Copy to source if not already there
      if [[ ! -e "$src_file" ]]; then
        if run_cmd /bin/cp "$entry" "$src_file"; then
          copied=$((copied + 1))
        else
          errors=$((errors + 1)); overall_errors=$((overall_errors + 1))
          continue
        fi
      else
        warn "File already exists in source (skipping copy): $src_file"
        linked=$((linked + 1))
      fi

      # Remove original and create symlink
      if run_cmd /bin/rm -f "$entry" && run_cmd /bin/ln -s "$src_file" "$entry"; then
        :
      else
        errors=$((errors + 1)); overall_errors=$((overall_errors + 1))
      fi
    done

    log "Agent: $inspect_dir | copied=$copied linked=$linked skipped_symlink=$skipped_symlink skipped_other=$skipped_other errors=$errors"
  done

  if ((overall_errors > 0)); then
    warn "Completed with $overall_errors operation error(s)."
    exit 2
  fi

  log "Collection completed successfully."
}
```

- [ ] **Step 3: Add `collect` to `main()` dispatch**

```bash
main() {
  if (($# == 0)); then usage; exit 1; fi
  case "$1" in
    sync)    shift; cmd_sync "$@" ;;
    collect) shift; cmd_collect "$@" ;;
    -h|--help) usage; exit 0 ;;
    -*) err "Unknown option: $1"; usage >&2; exit 1 ;;
    *)  err "Unknown subcommand: $1"; usage >&2; exit 1 ;;
  esac
}
```

- [ ] **Step 4: Run all collect tests**

```sh
mise run xc-skills:specs --scenario collect_copies_file
mise run xc-skills:specs --scenario collect_conflict_links
mise run xc-skills:specs --scenario collect_skips_symlink
# … run each scenario, then:
mise run xc-skills:specs
```

Expected: all 38 tests pass (23 sync + 15 collect).

- [ ] **Step 5: Commit**

```sh
git add xc-skills tests/xc-skills.spec.ts mise.toml specs/xc-skills/
git commit -m "feat(xc-skills): add collect command"
```
