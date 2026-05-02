---
name: kb
description: "Configure the knowledge base"
---

# kb

Configure the knowledge base

## kb skills

Manage agent skill files

### Subcommands

| Command | Description |
|---------|-------------|
| `sync` | Generate and install skill files for detected agents |
| `list` | List detected agents on this system |

## kb skills sync

Generate and install skill files for detected agents

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--global` | `boolean` | `true` | Install globally (default) or project-local |
| `--force, -f` | `boolean` | `false` | Force regeneration even if up to date |

## kb skills list

List detected agents on this system

## kb config

Show, setup, and sync configuration

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--setup` | `boolean` | `false` | Create paths and config file |
| `--sync` | `boolean` | `false` | Reload config from disk |

## kb ls

List and search entries

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--query, -q` | `string` |  | Full-text search query |
| `--tags, -t` | `string` |  | Filter by tags (a,b = AND) |
| `--types, -T` | `string` |  | Filter by entry types (a,b) |
| `--noLimit` | `boolean` | `false` | Disable result limit |
| `--limit, -l` | `number` | `50` | Result limit |
| `--offset, -o` | `number` | `0` | Result offset |

## kb view

View one entry by stable id

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--id` | `number` |  | Entry stable id |

## kb db

Database operations

### Subcommands

| Command | Description |
|---------|-------------|
| `stats` | Database statistics |
| `import` | Import YAML sources into SQLite |
| `seed` | Seed operations |
| `fixtures` | Test fixture operations |

## kb db stats

Database statistics

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |

## kb db import

Import YAML sources into SQLite

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -s` | `string` |  | Override sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |

## kb db seed

Seed operations

### Subcommands

| Command | Description |
|---------|-------------|
| `regen` | Regenerate SQL seed from database variations |

## kb db seed regen

Regenerate SQL seed from database variations

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--out` | `string` | `src/__tests__/fixtures/seeds/app.seed.sql` | Output seed SQL file path |
| `--dryRun` | `boolean` | `false` | Do not write file; print summary only |

## kb db fixtures

Test fixture operations

### Subcommands

| Command | Description |
|---------|-------------|
| `regen` | Regenerate YAML fixtures from database variations |

## kb db fixtures regen

Regenerate YAML fixtures from database variations

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--outA` | `string` | `src/__tests__/fixtures/fixture-s/git.yml` | First fixture YAML file path |
| `--outB` | `string` | `src/__tests__/fixtures/fixture-s/more.yml` | Second fixture YAML file path |
| `--dryRun` | `boolean` | `false` | Do not write files; print summary only |

## kb cache

Query cache statistics and invalidation

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--config, -c` | `string` | `/Users/roalcantara/.config/kodexb/config.yaml` | Config file path |
| `--source, -S` | `string` | `/Users/roalcantara/.config/kodexb/sources/` | Sources directory |
| `--db, -b` | `string` | `/Users/roalcantara/.config/kodexb/knowledge.sqlite` | SQLite database path |
| `--debug, -d` | `boolean` | `false` | Debug log to stderr |
| `--pretty, -P` | `boolean` | `true` | Pretty colored output (default) |
| `--json, -J` | `boolean` | `false` | JSON output |
| `--yaml, -Y` | `boolean` | `false` | YAML output |
| `--raw, -R` | `boolean` | `false` | Raw TSV output |
| `--invalidate` | `boolean` | `false` | Clear all query caches |
