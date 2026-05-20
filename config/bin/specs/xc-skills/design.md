# xc-skills `sync` Command — Design

## Overview

Adds a `sync` subcommand to `xc-skills` that mirrors symlinks from a source directory into one or more target directories. Targets can be specified as explicit paths (`-t`) or as agent names (`-a`) resolved via a built-in lookup table. Supports `--dry-run`, `--prune`, and `-l/--local` for project-relative vs global path resolution.

---

## Interface

```
xc-skills sync [--dry-run] [--prune] [-s|--source PATH]
               [-a|--agent <agent>]... [-t|--target <path>]... [-l|--local]
xc-skills -h | --help
```

### Flags

| Flag               | Repeatable                 | Default            | Description                                  |
| ------------------ | -------------------------- | ------------------ | -------------------------------------------- |
| `--dry-run`        | no                         | off                | Print actions, no filesystem changes         |
| `--prune`          | no                         | off                | Remove dest symlinks absent from source      |
| `-s/--source PATH` | **no** (error if repeated) | `~/.claude/skills` | Source directory                             |
| `-a/--agent NAME`  | **yes**                    | —                  | Agent name; resolved via lookup table        |
| `-t/--target PATH` | **yes**                    | —                  | Explicit destination directory               |
| `-l/--local`       | **no** (error if repeated) | off                | Use project-local paths for agent resolution |

### Destination resolution

```
if -a and -t are both absent:
    destinations = hardcoded default list   # backward-compat
else:
    for each -a <agent>:
        if --local: dest = $PWD/<project_path>
        else:       dest = $HOME/<global_path>
    for each -t <path>:
        dest = <path>
```

### Default destination list (backward-compat)

- `~/.gemini/antigravity/skills`
- `~/.codex/skills`
- `~/.kiro/skills`
- `~/.cursor/skills`
- `~/.gemini/skills`
- `~/.copilot/skills`
- `~/.config/opencode/skills`

---

## Agent lookup table

| Agent(s)                                 | Project/Local path   | Global path                    |
| ---------------------------------------- | -------------------- | ------------------------------ |
| `aider-desk`                             | `.aider-desk/skills` | `~/.aider-desk/skills`         |
| `amp`, `kimi-cli`, `replit`, `universal` | `.agents/skills`     | `~/.config/agents/skills`      |
| `antigravity`                            | `.agents/skills`     | `~/.gemini/antigravity/skills` |
| `augment`                                | `.augment/skills`    | `~/.augment/skills`            |
| `bob`                                    | `.bob/skills`        | `~/.bob/skills`                |
| `claude-code`                            | `.claude/skills`     | `~/.claude/skills`             |
| `openclaw`                               | `skills`             | `~/.openclaw/skills`           |
| `cline`, `dexto`, `warp`                 | `.agents/skills`     | `~/.agents/skills`             |
| `codex`                                  | `.agents/skills`     | `~/.codex/skills`              |
| `cursor`                                 | `.agents/skills`     | `~/.cursor/skills`             |
| `gemini-cli`                             | `.agents/skills`     | `~/.gemini/skills`             |
| `github-copilot`                         | `.agents/skills`     | `~/.copilot/skills`            |
| `opencode`                               | `.agents/skills`     | `~/.config/opencode/skills`    |
| _(…full table in script header)_         |                      |                                |

---

## Sync algorithm (per destination)

1. `mkdir -p <dest>` if not present
2. Skip dest if not writable (warn)
3. For each symlink in source:
   - If dest path doesn't exist → **create** (`ln -s`)
   - If dest path is a symlink with same target → **skip** (unchanged)
   - If dest path is a symlink with different target → **replace** (`rm -f` + `ln -s`)
   - If dest path is a regular file/dir → **skip** (warn: non-symlink exists)
4. If `--prune`: for each symlink in dest not present in source → **remove**

---

## Implementation

- **Shell**: `bash` (kept from original; no zsh-isms needed)
- **`resolve_agent_path(agent, local_flag, pwd)`**: pure function → prints path or exits 1
- **`cmd_sync()`**: parses sync-specific flags, builds dest list, runs sync loop
- **`main()`**: dispatches on first positional arg (`sync` | `-h/--help` | error)
- **`run_cmd()`**: respects `--dry-run`

---

## Tests

Spec: `tests/xc-skills.spec.ts`
Runner: `mise run xc-skills:specs`
Scenarios: 23 (see mise.toml `choices` list)

Key coverage:

- Help, no-args, unknown-cmd
- Source: default, explicit, missing, empty
- Symlink lifecycle: create, replace, unchanged, non-symlink skip
- `--prune` on/off
- Multi-target, multi-agent, mixed
- Agent resolution: global vs `--local`
- Error guards: `--source` once, `--local` once, unknown agent
- Backward-compat default target list
- Non-writable destination

---

## Examples

```sh
# Dry-run sync to antigravity's global skills dir
xc-skills sync --dry-run -s ~/.claude/skills -a antigravity

# Sync to two agents at once
xc-skills sync -a antigravity -a cursor

# Sync to project-local paths (relative to $PWD)
xc-skills sync -a antigravity -a cursor -l

# Sync to an agent AND an explicit path
xc-skills sync -a antigravity -t ~/.custom/skills

# Prune orphan symlinks
xc-skills sync --prune -s ~/.claude/skills -t ~/.gemini/antigravity/skills

# Backward-compat: no -a/-t → syncs to full default list
xc-skills sync
```
