# xc-skills `collect` Command — Design

_Date: 2026-05-08_

## Overview

`collect` is the inverse of `sync`. Where `sync` mirrors symlinks from a central source into agent directories, `collect` brings regular (non-symlink) files back from agent directories into the central source — then replaces each original with a symlink pointing to source. The end state is always identical to what `sync` would produce.

---

## Interface

```
xc-skills collect [--dry-run] [-s|--source PATH]
                  [-a|--agent <agent>]... [-t|--target <path>]... [-l|--local]
```

### Flags

| Flag               | Repeatable                 | Default            | Description                                  |
| ------------------ | -------------------------- | ------------------ | -------------------------------------------- |
| `-s/--source PATH` | **no** (error if repeated) | `~/.agents/skills` | Directory where collected files are written  |
| `-a/--agent NAME`  | **yes**                    | —                  | Agent name; resolved via lookup table        |
| `-t/--target PATH` | **yes**                    | —                  | Explicit directory to inspect                |
| `-l/--local`       | **no** (error if repeated) | off                | Resolve agent paths as `$PWD/<project_path>` |
| `--dry-run`        | no                         | off                | Print actions, no filesystem changes         |

### Inspection scope

```
if -a and -t are both absent:
    inspect ALL known agents' directories (global or local per -l)
    skip any directory that does not exist — silently
else:
    for each -a <agent>: resolve path, skip if directory does not exist
    for each -t <path>:  use path as-is, skip if directory does not exist
```

No new directories are created for agents — only the source directory is created if absent.

---

## Algorithm (per inspected directory)

For each regular file (non-symlink) found at `<dir>/<name>`:

| Condition                                                | Action                                                                                  |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `<source>/<name>` does not exist                         | Copy file to source, delete original, create symlink `<dir>/<name>` → `<source>/<name>` |
| `<source>/<name>` already exists                         | Warn (skip copy), delete original, create symlink `<dir>/<name>` → `<source>/<name>`    |
| `<dir>/<name>` is already a symlink                      | Skip entirely (already collected)                                                       |
| `<dir>/<name>` is a directory or other non-regular entry | Skip with warning                                                                       |

The end state in both cases (file exists or not in source) is that the agent dir holds a symlink to the source copy, matching what `sync` would produce.

---

## Output

One summary line per inspected directory:

```
Agent: <path> | copied=2 linked=3 skipped_conflict=1 skipped_symlink=4 errors=0
```

- **copied**: regular files copied to source and replaced with symlink
- **linked**: files that already existed in source; original replaced with symlink (no copy)
- **skipped_conflict**: entries skipped because source already has a non-file at that name (warn)
- **skipped_symlink**: entries already pointing elsewhere (already collected or foreign symlink)
- **errors**: failed copy, rm, or ln operations

Final line on success:

```
Collection completed successfully.
```

On any errors:

```
WARN: Completed with N operation error(s).
```

Exit 2 if any errors occurred, exit 0 otherwise.

---

## Error handling

| Situation                 | Behaviour                        |
| ------------------------- | -------------------------------- |
| Source dir missing        | Create with `mkdir -p`           |
| Source dir not writable   | Error and exit 1                 |
| Agent/target dir missing  | Silently skip                    |
| `-s` given more than once | Error and exit 1                 |
| `-l` given more than once | Error and exit 1                 |
| Unknown agent name        | Error and exit 1                 |
| Copy/rm/ln failure        | Warn, increment errors, continue |

---

## Relationship to `sync`

```
sync:    source ──symlinks──► agent dirs
collect: agent dirs ──files──► source, then agent dirs get symlinks back
```

Running `collect` followed by `sync` (or vice versa) is idempotent — the second run sees only symlinks and does nothing.

---

## Examples

```sh
# Collect from all agent global dirs into ~/.agents/skills
xc-skills collect

# Dry-run to see what would be collected
xc-skills collect --dry-run

# Collect from a specific agent
xc-skills collect -a antigravity

# Collect from project-local dirs
xc-skills collect -l

# Collect into a custom source dir
xc-skills collect -s ~/.claude/skills -a antigravity -a cursor

# Collect from an explicit directory
xc-skills collect -t ~/my-project/.agents/skills
```

---

## Tests

Spec: `tests/xc-skills.spec.ts` (added scenarios)
Runner: `mise run xc-skills:specs`

Key scenarios to cover:

| Scenario ID                   | Description                                                    |
| ----------------------------- | -------------------------------------------------------------- |
| `collect_no_source`           | Default source created if absent                               |
| `collect_copies_file`         | Regular file copied to source, replaced with symlink           |
| `collect_conflict_links`      | File already in source: skipped (warns), symlink still created |
| `collect_skips_symlink`       | Already-symlinked entries skipped                              |
| `collect_skips_missing_dir`   | Agent dir that doesn't exist is silently skipped               |
| `collect_dry_run`             | `--dry-run` prints actions, no filesystem changes              |
| `collect_agent_global`        | `-a antigravity` resolves to `~/.gemini/antigravity/skills`    |
| `collect_agent_local`         | `-a antigravity -l` resolves to `$PWD/.agents/skills`          |
| `collect_multi_agent`         | Multiple `-a` inspects each agent dir                          |
| `collect_explicit_target`     | `-t <path>` inspects that directory                            |
| `collect_all_agents`          | No `-a`/`-t` inspects all known agent dirs                     |
| `collect_source_once`         | `-s` given twice → error                                       |
| `collect_local_once`          | `-l` given twice → error                                       |
| `collect_unknown_agent`       | Unknown agent name → error                                     |
| `collect_source_not_writable` | Non-writable source → error                                    |
