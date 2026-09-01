# fallow

> Codebase analysis building and traversing a graph - not files in a context window.
> unused code, circular dependencies, code duplication, complexity hotspots, and architecture boundary violations
> More information: <https://fallow.dev>.

## OVERVIEW

- USE WHEN

  - find cleanup opportunities and unused files/exports/dependencies
  - detect circular dependencies and architecture-boundary issues
  - rank complexity hotspots and refactoring targets
  - audit changed code before a PR, commit, or release
  - find feature flags and runtime coverage gaps
  - review duplication and design drift
  - surface local security candidates for human verification

- AVOID WHEN

  - runtime debugging or error analysis
  - TypeScript type checking (`tsc` is still the source of truth)
  - formatting or linting style enforcement (`Biome`, `ESLint`, `Prettier`)
  - verified vulnerability scanning or SAST
  - bundle-size analysis
  - non-JavaScript/TypeScript projects

- KEY CONVENTIONS

  - Always use `--quiet` for machine-readable output.
  - Append `|| true` so issue findings do not cancel Bash/agent pipelines.
  - Use `--explain` for metadata and interpretation hints.
  - Treat exit code `1` as “issues found” and `2` as a real configuration or parsing error.
  - Use `--dry-run` before `fix`, then `fix --yes` to apply.
  - Do not run `fallow watch`; it is interactive and never exits.
  - Treat project config as untrusted input.
  - Use `--type-aware` sparingly and only for Fallow-owned project questions.
  - Use `fallow impact statusline` only for user-facing status output.

---

## QUICK REFERENCE

  ```sh
  fallow list --entry-points --quiet                  # Project structure
  fallow dead-code --quiet                            # Find unused code
  fallow health --hotspots --targets --quiet          # Complexity / hotspots
  fallow dupes --quiet                                # Duplication
  fallow audit --quiet --base main                    # PR gate
  fallow guard src/**/*.ts                            # Architecture boundary checks
  fallow fix --dry-run --quiet                        # Auto-fix dry-run
  fallow fix --yes --quiet                            # Auto-fix apply
  fallow security --quiet                             # Security candidates
  fallow impact                                       # Impact summary
  ```

---

## SETUP

- Install prebuilt binaries _(fastest, recommended)_

  ```sh
  npm install -g fallow
  ```

- Scaffold `AGENTS.md` guidance without overwriting project content

  ```sh
  fallow init --toml --agents
  ```

- Configure project-specific hooks to block commits and pushes until "fallow audit" passes

  ```sh
  fallow hooks status --format human --quiet              # check hook state
  fallow hooks install --target git                       # install Git hooks for a Claude Code / Codex gate
  fallow hooks install --target agent --agent claude      # install Git hooks for a Claude Code gate
  fallow hooks install --target agent --agent codex       # install Git hooks for a Codex gate
  ```

- Migrate from `knip` or `jscpd` config

  ```sh
  fallow migrate --dry-run    # preview conversion
  fallow migrate              # apply conversion from knip or jscpd config
  ```

- Tracking, impact, and telemetry `(opt-in and off by default)`

  ```sh
  fallow impact status                    # show whether impact tracking is enabled
  fallow impact enable                    # enable project-local impact tracking
  fallow impact default on                # enable it by default for your environment

  fallow telemetry status                 # check telemetry state
  fallow telemetry enable                 # enable telemetry for this project
  ```

---

## QUICKSTART

1. Setup & Config

  ```sh
  # 1. run dead code, duplication, health analysis from project root
  npx fallow

  # 2. Run the focused commands you'll use most
  npx fallow dead-code          # Cleanup candidates
  npx fallow dupes              # Repeated logic
  npx fallow health             # Complexity and refactor targets
  npx fallow review             # Advisory review brief over changed files (always exits 0)
  npx fallow fix --dry-run      # Preview automatic cleanup

  # 3. Understand the output
  npx fallow dead-code          # Reports unused files, exports, types, dependencies, circular deps, and boundary violations
  npx fallow dupes              # Reports repeated logic. Default `mild` mode catches AST-based duplicates. Add `--mode semantic` to catch clones with renamed variables.
  npx fallow health             # Reports complexity findings, per-file maintainability, hotspots, and ranked refactor targets.

  # 4. Fix preview
  npx fallow fix --dry-run      # Preview automatic cleanup - Use this before deleting anything automatically
  npx fallow fix                # Drop `--dry-run` to apply fixes.

  # 5. Create config
  fallow init                   # auto-detects project structure; generates config; adds .fallow/ to .gitignore.
  ```

2. Define project-specific rules and thresholds in `.fallowrc.json` or `.fallowrc.toml`. Example:

  - What counts as a real entry point (workers, scripts, route files, dynamically loaded modules)?
  - Which files are generated or out of scope?
  - Which packages are public APIs that ship exports outside the repo?
  - Which dependencies are runtime-provided or intentionally retained?
  - Which health thresholds you actually want to enforce?
  - Whether duplication should warn or fail?

3. Configuration

  ```jsonc
  // A reasonable starting point
  {
    "$schema": "https://raw.githubusercontent.com/fallow-rs/fallow/main/schema.json",
    "ignorePatterns": ["**/*.generated.ts", "**/*.d.ts"],
    "rules": {
      "unresolved-imports": "error",
      "unlisted-dependencies": "error",
      "unused-exports": "warn"
    }
  }
  ```

  - Rules you do not list inherit their defaults.
  - Health thresholds default to`maxCyclomatic: 20` and `maxCognitive: 15`;
  - override in a`health` block only when your repo’s realistic baseline differs.
  - Use `warn` during rollout when you need visibility without blocking CI.
  - Promote rules to `error` as the backlog shrinks.

4. Work findings in the right order

  ```sh
  # 1. Fix unresolved imports and unlisted dependencies
  fallow dead-code --unresolved-imports
  fallow dead-code --unlisted-deps

  # 2. Delete unused files
  fallow dead-code --unused-files
  fallow list --entry-points # sanity-check reachability before deleting anything you are unsure about

  # 3. Remove unused dependencies
  fallow dead-code --unused-deps

  # 4. Clean up unused exports, types, enum members, and class members
  fallow dead-code --unused-exports --unused-types --type-aware

  # 5. Consolidate duplication: merge repeated logic into shared helpers
  fallow dupes
  fallow dupes --mode semantic   # also catch renamed-variable clones

  # 6. Split health hotspots
  fallow health
  ```

5. Match the reason to the right mechanism

  1. External or public API:
    1. `@public`, `@internal`: distinguish public API from internal helpers that happen to be exported for cross-file use
    2. `@beta`, `@alpha`: JSDoc visibility tags on the export
    3. `publicPackages`: marks the package as externally consumed
    4. `ignoreExports`: when file-level or export-level exceptions cannot be expressed any other way

  2. Framework or runtime-discovered entry points (workers, CLI scripts, route files, plugin modules):
    1. built-in plugin detection: https://docs.fallow.tools/frameworks/built-in
    2. `entry` for project-specific entry globs
    3. `dynamicallyLoaded` for code pulled in through reflection, manifests, or dynamic imports
    4. `fallow list --entry-points` to inspect what Fallow already considers reachable

  3. Generated or vendored files (build, codegen, or third-party code):
     1. `ignorePatterns` to exclude them from analysis entirely
     2. `health.ignore` when the noise is health-only and dead-code analysis should still run
     3. duplication configuration for clone-heavy generated code

  4. Runtime-provided or intentionally retained dependencies (compatibility shims, future API):
     1. `ignoreDependencies` with the exact package names

   5. One-off intentional unused export:
      1. Prefer `/** @expected-unused */` on the export - tracked as staleness, reported when imported

   6. One-off false positive - when fallow wrong and no config rule captures the reason cleanly:
      1. `// fallow-ignore-next-line <issue>` on the line above
      2. `// fallow-ignore-file <issue>` only when the whole file is truly exceptional

   7. Repo-wide policy change - when project genuinely has a different standard:
      1. Prefer `rules`, `health`, duplication thresholds, or `overrides` blocks
      2. Do not hide a few ugly hotspots

   8. Keep exceptions narrow and reviewable - broad exceptions are a debt:

      > If you cannot explain an exception in one sentence, it is probably the wrong mechanism.

      GOOD:
         - a single `@public` export on a library entry point
         - one `ignoreDependencies` entry for a runtime-provided package
         - one `entry` pattern for worker scripts
         - one file-level generated-code ignore with a comment explaining why

      BAD:
         - broad `ignorePatterns` that silently exclude half the repo
         - repeated inline suppressions that could be one config rule
         - raising global `health.maxCyclomatic` to hide a handful of hotspots
           - acceptable only when the new threshold reflects a thought-through project standard with written justification

   9. Define done

      1.  **STAGE 1**: good enough to ship `fallow audit`
          - the chosen policy is encoded in config, not accumulated in scattered suppressions
          - unresolved imports and unlisted dependencies are cleared
          - blatant dead code (unused files, unused dependencies) is removed
          - `fallow audit` is wired into CI and passes for new changes against the default branch
      2. **STAGE 2**: ideal state
          - no functions above your chosen health thresholds
            - either by refactoring or by consciously widening the threshold with written justification
          - duplication at or below the chosen threshold
          - stale suppressions gone or consciously accepted

   10. Add PR gate: `fallow audit`
      - runs dead code, duplication, and complexity analysis scoped to changed files
      - then returns a `pass`, `warn`, or `fail` verdict
      - https://docs.fallow.tools/cli/audit


6.  Rollout strategy

    1.  WARN everywhere:

        > Best for smaller teams. CI never blocks; fixes land under social pressure

        1. Configure `.fallowrc.json` with `warn` for all rules:

            ```jsonc
            {
              "rules": {
                "unused-exports": "warn",
                "unused-files": "warn",
                "unused-dependencies": "warn"
              },
              // Configure baselines to run `fallow audit` with no flags
              "audit": {
                "deadCodeBaseline": "fallow-baselines/dead-code.json",
                "healthBaseline":   "fallow-baselines/health.json",
                "dupesBaseline":    "fallow-baselines/dupes.json"
              }
            }

    2.  ERROR + Baselines:

        > Best for larger orgs. CI blocks on new issues; pre-existing debt on touched files is baselined:

        1. Generate baselines once on the default branch:

          ```sh
          # Save baselines once on the default branch
          fallow dead-code --save-baseline fallow-baselines/dead-code.json
          fallow health    --save-baseline fallow-baselines/health.json
          fallow dupes     --save-baseline fallow-baselines/dupes.json

          # Audit only new issues on PRs
          fallow audit \
            --dead-code-baseline fallow-baselines/dead-code.json \
            --health-baseline    fallow-baselines/health.json \
            --dupes-baseline     fallow-baselines/dupes.json
          ```

        1. Store committed baselines outside gitignored `.fallow/`

           - `fallow-baselines/` is the recommended default

        2. Commit the baseline files so every PR compares against the same snapshot
        3. Regenerate on a schedule (quarterly, or per release) rather than per merge

           - otherwise teams silently absorb new debt every time CI runs.

        4. Configure baselines in `.fallowrc.json` to run `fallow audit` with no flags:

            ```jsonc
            {
              "audit": {
                "deadCodeBaseline": "fallow-baselines/dead-code.json",
                "healthBaseline":   "fallow-baselines/health.json",
                "dupesBaseline":    "fallow-baselines/dupes.json"
              }
            }
            ```

    3.  AGENT gate -local reinforcement layer:

        > Best when Claude Code is the main pusher

        1. Add a project-level `PreToolUse` hook:
           - Intercepts `git commit` and `git push`
           - runs `fallow audit --format json --quiet --explain`
           - blocks only on `verdict: "fail"`.

        2. Claude receives the raw audit JSON on stderr, fixes the findings, and retries the command.
        3. Pair this with Option A or B, not instead of them
        4. Keep CI on `fallow audit` so human pushes and non-Claude workflows are still covered.
        5. Runtime errors (no base ref yet, first commit in an empty repo, config errors) fail open so new repos do not get stuck.
        6. See https://docs.fallow.tools/integrations/claude-hooks or generate the files:

           ```sh
           fallow hooks install --target agent
           ```
        7. Configure baselines in `.fallowrc.json` to run `fallow audit` with no flags:

          ```jsonc
          {
            "audit": {
              "deadCodeBaseline": "fallow-baselines/dead-code.json",
              "healthBaseline":   "fallow-baselines/health.json",
              "dupesBaseline":    "fallow-baselines/dupes.json"
            }
          }
          ```

7. Clean up with an agent

  > Fallow finds the problems. An AI agent to fix them
  > Integrate fallow with AI agents via CLI and MCP.
  > Unused code, duplication, complexity hotspots, boundary violations, and auto-fix
  >
  > AGENTS don’t perform codebase-level analysis
  > Fallow provides deterministic, exhaustive codebase analysis that agents call via CLI or MCP

  Codebase analysis means building and traversing a graph, not reading files in a context window:

  | What agents can’t do                                             | What fallow does                                        |
  | ---------------------------------------------------------------- | ------------------------------------------------------- |
  | Build a complete module graph across 5,000+ files                | Builds the full graph in ~200ms                         |
  | Track re-export chains through barrel files                      | Resolves`export *`chains through unlimited levels       |
  | Know if an export is used somewhere outside their context window | Exhaustively checks every import in the entire codebase |
  | Detect code duplication across files they haven’t seen           | Suffix array algorithm catches clones across all files  |
  | Determine which `package.json` dependencies are actually unused  | Traces imports and script binaries to actual usage      |
  | Guarantee completeness (no missed files, no false negatives)     | Deterministic: same input always produces same output   |

  1. [SKILLS](https://docs.fallow.tools/integrations/agent-skills)

    > precise, up-to-date instructions for codebase health, cleanup analysis, circular dependency detection, duplication, and complexity hotspots.

    The [fallow-skills](https://github.com/fallow-rs/fallow-skills) package includes:

      - **Analysis skill**:
        - Workflows for unused code, duplication, complexity, boundary analysis, auto-fix, and CI setup

      - **CLI reference**:
        - Complete command specs, flags, output formats, and configuration

      - **Gotchas**:
        - pitfalls with correct vs. incorrect examples (e.g.,`fix --yes` in non-TTY)

      - **Workflow patterns**:
        - Recipes for CI pipelines, monorepo analysis, migrating from knip/jscpd, and incremental adoption

    Once installed, Agents know how to respond to natural language requests:

      - **Find cleanup opportunities:**
        - PROMPT: `Find all unused exports in this project`
        - Agent runs `fallow dead-code --format json --quiet --unused-exports` and summarizes findings.

      - **Clean up dependencies:**
        - PROMPT: `Are there any unused dependencies?`
        - Agent runs targeted analysis and suggests removals.

      - **Detect duplication:**
        - PROMPT: `Find code duplication in the codebase`
        - Agent runs `fallow dupes` with the right mode and interprets clone families.

      - **Auto-fix:**
        - PROMPT: `Remove unused exports`
        - Agent runs dry-run first, shows proposed changes, then applies with `--yes`.

      - **CI setup:**
        - PROMPT: `Set up a code quality gate in CI`
        - Agent generates the correct GitHub Actions workflow with baselines.

      - **Debug false positives:**
        - PROMPT: `Why is this export flagged?`
        - Agent uses `--trace` to investigate and suggests suppression if needed

  2. [MCP: structured tool calling](https://docs.fallow.tools/integrations/mcp#mcp-structured-tool-calling)

     > Agents get typed inputs and outputs instead of parsing CLI text
     > The MCP server usesand a hybrid adapter.
     > Supported requests run through the typed `fallow-api` in process, while command-owned options use a managed `fallow` CLI subprocess.
     > Set`FALLOW_BIN`only when CLI-backed calls need a specific binary (defaults to `fallow` in `PATH`).

     1. Register the server:

        ```jsonc
        // .mcp.json
        {
          "mcpServers": {
            "fallow": {
              "command": "npx",
              "args": ["fallow-mcp"]
            }
          }
        }
        ```

      2. The server uses stdio transport

        ```sh
        # Start the MCP server directly
        fallow-mcp

        # With a custom fallow binary path
        FALLOW_BIN=/usr/local/bin/fallow fallow-mcp
        ```

      3. Configure any client to launch `fallow-mcp` as a stdio subprocess

         - Start the agent from the project root so the runner finds the local install.
         - If you need an explicit fallow binary, keep setting`FALLOW_BIN`.

      4. Runtime source-map confidence

          > The typed API handles supported requests directly, while the CLI fallback handles command-owned options.
          > Together they expose the full feature set, including production mode, baselines, and incremental analysis.

          ```jsonc
          // REQUEST
          {
            "tool": "analyze",
            "arguments": {
              "production": true,
              "issue_types": ["unused-exports", "unused-files"]
            }
          }

          // RESPONSE
          {
            "schema_version": 9,
            "version": "3.17.0",
            "elapsed_ms": 42,
            "total_issues": 1,
            "unused_exports": [
              {
                "path": "src/utils/format.ts",
                "export_name": "formatCurrency",
                "is_type_only": false,
                "line": 12,
                "col": 0,
                "span_start": 280,
                "is_re_export": false
              }
            ]
          }
          ```

       5. Structured actions in tool responses

          - All tools now return structured `actions` arrays on every finding, enabling agents to programmatically apply fixes or suppressions

       6. Combined output from bare `fallow`:

          - Running bare `fallow --format json` (no subcommand) executes all analyses in one pass
          - And returns a combined JSON object with`dead_code`,`duplication`, and`health`sections
          - This is the most efficient way for agents to get a full picture of the codebase in a single call
          - The combined output includes all issue types from dead code, duplication findings, and health metrics.

  3. Plain shell:
     - Agents can call the CLI directly with `npx fallow` or a prebuilt binary
     - Run next prompted command after each analysis to fix or suppress findings

  4. Adoption PROMPT:
    > When the goal is to bring an existing codebase to a clean Fallow policy
    > hand the cleanup work to the agent:
    > fallow finds the problems, the agent fixes them in code.

     ```md
      Adopt Fallow in this repository.

      Goal:
      - use full-repo analysis first (`fallow`, `fallow dead-code`, `fallow dupes`, `fallow health`), not `fallow audit`
      - fix real dead code, duplication, and complexity issues in code
      - model intentional exceptions with the narrowest correct mechanism
      - end with no functions above the repo's chosen health thresholds, or a consciously widened threshold with written justification
      - then set up `fallow audit` as a PR gate

      Process:
      1. Run `npx fallow`, then `npx fallow dead-code`, `npx fallow dupes`, and `npx fallow health`. Use `--format json` if you want structured output.
      2. If no config exists, run `fallow init` and create a minimal repo policy.
      3. Fix high-confidence issues first:
        - unresolved imports
        - unlisted dependencies
        - unused files (sanity-check with `fallow list --entry-points`)
        - unused dependencies
      4. For each remaining finding, choose one path:
        - fix it in code (preferred)
        - model it in config
        - add a narrow inline exception only if it is truly one-off
      5. Match reasons to mechanisms:
        - external API: `@public` / `@internal` / `@beta` / `@alpha`, or `publicPackages`
        - runtime or framework entry point: `entry`, `dynamicallyLoaded`, plugin-aware config
        - generated code: `ignorePatterns`, `health.ignore`
        - intentionally retained dependency: `ignoreDependencies`
        - intentional unused export: `@expected-unused` (preferred over inline comments because it self-cleans)
        - one-off false positive: `fallow-ignore-next-line`
        - repo-wide policy: `rules`, `health`, duplication settings, `overrides`
      6. Prefer config-level modeling over repeated suppression.
      7. Keep every exception narrow and explain why it exists in a commit message.
      8. Re-run Fallow after each batch until the repo is clean under the chosen policy.
      9. Only after repo cleanup, run `npx fallow audit` and wire it into CI.

      At the end, report:
      - code changes
      - config changes
      - exceptions added and why
      - anything left
      - the final commands and outputs that show the repo is clean
     ```

## RECIPES

- Full Audit + Fix Flow: repeatable quality cycle for a repo

  ```sh
  fallow dead-code --quiet                            # 1. run a full audit
  fallow health --hotspots --targets --quiet          # 2. find the biggest refactoring targets
  fallow dupes --quiet                                # 3. check duplication
  fallow fix --dry-run --quiet                        # 4. preview safe automated cleanup
  fallow fix --yes --quiet                            # 5. apply fixes after confirmation
  fallow dead-code --quiet                            # 6. verify the repo is clean
  ```

- CLI: the primary agent interface

  ```sh
  fallow dead-code --format json                        # Full dead code analysis with JSON output
  fallow dead-code --changed-since main --format json   # Only check changed files (great for agent PR workflows)
  fallow dupes --format json                            # Find code duplication
  fallow fix --dry-run --format json                    # Preview what auto-fix would remove
  fallow fix --yes --format json                        # Apply fixes (agents should use --yes to skip confirmation)
  fallow flags --format json                            # Detect feature flags and environment gates
  fallow list --format json                             # List project info (plugins, entry points, file count)
  ```

- Agent workflow: **After generating code**

  ```sh
  # Agent generates a new feature, commits, then checks its own work
  fallow dead-code --changed-since main --format json
  # → finds that the old utility file is now unused
  # → agent removes it
  ```

- Agent workflow: **Codebase cleanup**

  ```sh
  # Agent is asked to clean up dead code
  fallow dead-code --format json
  # → returns 401 issues: unused files, exports, dependencies

  fallow fix --yes --format json
  # → auto-removes unused exports and dependencies
  # Agent then deletes unused files from the JSON output
  ```

- Agent workflow: **Before a PR**

  ```sh
  # Agent verifies its changes don't introduce dead code
  fallow dead-code --changed-since main --format json
  # → clean: no new issues introduced
  ```

- Before changing code or merging a branch

  ```sh
  fallow list --entry-points --quiet
  fallow dead-code --quiet
  fallow health --hotspots --targets --quiet
  fallow dupes --quiet
  fallow audit --quiet --base main
  ```

- Discover project structure

  ```sh
  fallow list --entry-points --quiet          # show project entry points
  fallow list --plugins --quiet               # list detected framework plugins
  fallow list --files --quiet                 # list files in the project graph
  fallow workspaces --quiet                   # inspect workspace discovery and layout
  ```

- Audit the project for dead code

  ```sh
  fallow dead-code --quiet                                # audit the project for unused code
  fallow dead-code --quiet --unused-exports               # find only unused exports
  fallow dead-code --quiet --unused-files                 # find unreachable files
  ```

- Check code quality and complexity

  ```sh
  fallow health --quiet                                     # review complexity and health signals
  fallow health --hotspots --targets --quiet                # rank refactoring hotspots and targets
  fallow health --ownership --quiet                         # see likely owners for risky files
  fallow health --coverage-gaps --quiet                     # find untested runtime-reachable code
  ```

- Find duplicates

  ```sh
  fallow dupes --quiet                     # find duplicate code blocks
  fallow dupes --quiet --mode semantic     # detect renamed or structurally similar duplicates
  fallow dupes --quiet --mode strict       # exact-structure duplicate detection
  fallow dupes --quiet --mode weak         # looser duplicate matching across literals
  ```

- Check PR or branch risk: returns a pass / warn / fail verdict for issues introduced by the change set

  ```sh
  fallow audit --quiet --base main                    # check whether a PR introduces quality risk
  fallow audit --quiet --base origin/main             # compare against a remote base branch
  ```

- Surface feature flags and security candidates

  ```sh
  fallow flags --quiet                # detect feature flag patterns
  fallow security --quiet             # surface security candidates for review
  ```

- Understand a specific issue or symbol

  ```sh
  fallow explain unused-export                           # explain why an issue is reported
  fallow explain high-cyclomatic-complexity              # explain the complexity rule
  fallow inspect --file src/app.ts                       # inspect a file-level evidence bundle
  fallow trace mySymbol --callers --callees --depth 3    # trace a symbol's usage chain
  ```

- Guard architecture rules before editing a file

  ```sh
  fallow guard src/features/auth/index.ts      # check which architecture rules apply here
  fallow guard src/**/*.{ts,tsx}               # check multiple files before refactoring
  ```

- Production-only analysis

  ```sh
  fallow dead-code --quiet --production                         # analyze production-only dead code
  fallow health --quiet --production                            # health check for production code only
  fallow audit --quiet --production --base main                 # PR audit scoped to production files
  ```

- Monorepo and workspace-scoped analysis: uses the package name and workspace path

  ```sh
  fallow dead-code --quiet --workspace my-package                         # scope analysis to one workspace
  fallow dead-code --quiet --workspace 'apps/*,!apps/legacy'              # scope to a workspace glob and exclude legacy paths
  fallow dead-code --quiet --changed-workspaces origin/main               # check only workspaces changed since the base ref (useful in CI and PR checks)
  ```

- Safe auto-fix cycle: `--yes` required in non-TTY; blocks agent automation otherwise

  ```sh
  fallow fix --dry-run --quiet              # preview changes
  fallow fix --yes --quiet                  # apply approved fixes
  fallow dead-code --quiet                  # verify the result
  ```

- Agent rules and safety conventions

  ```sh
  fallow dead-code --quiet                        # Always use machine-readable JSON output
  fallow audit --quiet --base main || true        # Append `|| true` for non-zero issue findings
  fallow dead-code --quiet --explain              # Use --explain to retrieve interpretation hints
  ```


- Full Project Audit: complete codebase hygiene audit

  ```sh
  fallow dead-code --quiet      # 1. Run analysis
  fallow dupes --quiet          # 2. Find duplication
  fallow fix --dry-run --quiet  # 3. Preview auto-fix
  fallow fix --yes --quiet      # 4. Apply fixes (after user confirmation)
  fallow dead-code --quiet      # 5. Verify
  ```

- PR Dead Code Check: catch new dead code introduced by a pull request

  ```sh
  fallow dead-code --quiet --changed-since main --fail-on-issues  # 1. analyze changed files
  fallow dead-code --quiet --changed-since main                   # 2. inspect specific findings
  ```

- CI Pipeline Setup: gate PRs and publish results in CI

  ```yaml
  - name: Dead code check
    run: npx fallow dead-code --fail-on-issues --quiet

  - name: Duplication gate
    run: npx fallow dupes --quiet --threshold 5 --mode mild

  - name: Generate SARIF for GitHub Code Scanning uploads
    run: npx fallow dead-code --ci > fallow.sarif
  ```

- Incremental Adoption with Baselines: adopt fallow without fixing everything at once

  ```sh
  fallow dead-code --quiet --save-baseline fallow-baselines/dead-code.json              # 1. save the current state
  fallow dead-code --quiet --baseline fallow-baselines/dead-code.json --fail-on-issues  # 2. fail only on NEW issues
  fallow dupes --quiet --save-baseline fallow-baselines/dupes.json                      # 3. baseline duplication too
  ```

- Monorepo Analysis: scope review to the right workspace

  ```sh
  fallow dead-code --quiet                                    # 1. analyze the full monorepo
  fallow dead-code --quiet --workspace my-package             # 2. analyze one package only
  fallow dead-code --quiet --changed-workspaces origin/main   # 3. analyze only changed workspaces in CI
  ```

- Duplication Threshold CI Gate: keep duplication under a maximum percentage

  ```sh
  fallow dupes --quiet                              # 1. measure current duplication
  fallow dupes --quiet --threshold 5                # 2. fail if duplication exceeds 5%
  fallow dupes --quiet --threshold 5 --skip-local   # 3. ignore within-directory duplicates
  ```

- Migration from knip: convert existing knip config

  ```sh
  fallow migrate --dry-run    # preview conversion
  fallow migrate              # apply the migration
  fallow dead-code --quiet    # compare fallow output with the old knip baseline
  ```

- Migration from jscpd: convert existing jscpd config

  ```sh
  fallow migrate --dry-run    # preview conversion
  fallow migrate              # apply the migration
  fallow dupes --quiet        # compare duplication output after migration
  ```

- Safe Auto-Fix Workflow: preview, confirm, then apply

  ```sh
  fallow fix --dry-run --quiet    # 1. preview changes
  fallow fix --yes --quiet        # 2. apply approved fixes
  fallow dead-code --quiet        # 3. verify the result
  ```

- Production vs Full Audit: choose the right scope for the task

  ```sh
  fallow dead-code --quiet                # full audit: all files and dev tooling
  fallow dead-code --quiet --production   # production-only audit: ships to users, skips dev/test noise
  ```

- Debugging False Positives: trace usage before suppressing a finding

  ```sh
  fallow dead-code --quiet --trace src/utils.ts:myFunction  # trace one export's use chain
  fallow dead-code --quiet --trace-file src/utils.ts        # trace all edges for a file
  fallow dead-code --quiet --trace-dependency lodash        # trace where a dependency is used
  ```

- Combined Dead Code + Duplication: prioritize cleanup targets that are both unused and duplicated

  ```sh
  fallow dead-code --quiet --include-dupes  # cross-reference dead-code findings with duplication
  ```

- Custom Plugin Setup: add framework detection when built-ins are not enough

  ```jsonc
  // .fallowrc.json
  {
    "framework": [
      {
        "name": "my-framework",
        "enablers": ["my-framework"],
        "entryPoints": ["src/routes/**/*.ts"]
      }
    ]
  }
  ```

- GitHub Code Scanning Integration: upload SARIF output to GitHub

  ```yaml
  - name: Run Fallow
    run: npx fallow dead-code --format sarif --quiet > fallow.sarif
  - name: Upload SARIF
    uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: fallow.sarif
  ```

- Guard `git push` with a Claude Code PreToolUse hook: reinforce the agent gate before Git commands

  ```sh
  fallow audit --quiet --explain --gate-marker agent  # run the gate check before git commit / git push
  fallow hooks install --target agent                               # install the Claude Code hook
  fallow hooks uninstall --target agent                             # remove the Claude Code hook later
  ```