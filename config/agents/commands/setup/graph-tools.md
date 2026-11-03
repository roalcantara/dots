---
description: Port code-graph tooling patterns (CRG, Gortex, Graphify) into any repository with runnable tasks, health checks, agent wiring, and safe git-hook refresh
argument-hint: optional constraints (task runner, hook manager, CI limits, secrets backend, preferred tool versions)
---

<task>
You are a repository tooling integrator. Abstract and apply the graph-tools blueprint to the current repo so any agent can use code-review-graph (CRG), Gortex, and Graphify consistently.

Always produce:
1) an implementation plan adapted to this repo,
2) the concrete file changes,
3) a verification report,
4) a removal/rollback checklist.
</task>

<context>
Use this command when a user asks to install, port, standardize, or operationalize code graph tools for agent workflows.

Core outcomes:
- One command/task entry point for graph lifecycle (`setup`, `update`, `build`, optional `--force`, optional `--dry-run`).
- Health checks integrated into repo diagnostics (`doctor` equivalent).
- Agent wiring committed and reproducible (`.mcp.json`, skills/settings wiring).
- Automatic non-blocking refresh after git lifecycle events (commit/merge/checkout).
- Generated graph outputs and local state never committed.

The command must be repository-aware: reuse existing conventions, task systems, and hook systems before introducing new ones.
</context>

<lessons_learned>
Apply these rules extracted from prior graph-tools implementations:

1. Prefer committed, reviewable wiring over implicit installers.
   - Do not run installers that rewrite committed config with unpinned defaults.

2. Separate concerns clearly:
   - Install dependencies
   - Setup integrations
   - Update graph state
   - Build reports

3. Keep graph updates fast and safe by default.
   - Use background refresh for post-git events.
   - Never block commits/merges on graph refresh.
   - Use single-flight lock + log file.

4. Make diagnostics first-class.
   - Add explicit checks for: tools installed, config files present, MCP wiring valid, ignore rules, secrets resolution.

5. Treat secrets as references, never values.
   - Commit only secret lookup metadata (e.g., fnox/pass paths).
   - Keep local overrides ignored.

6. CI should not install or execute tools that no CI job uses.
   - Declare explicit CI disable/skip list for graph-only developer tooling.

7. Always provide dry-run and scoped execution.
   - Users must be able to test single tool actions and preview actions before changes.

8. Document global side effects and uninstall steps.
   - Especially daemons, tracking indexes, external caches, and local folders.

9. Verify behavior, not just file presence.
   - Confirm commands run, status checks pass, hooks fire, logs update, working tree stays clean.

10. Keep generated outputs and runtime state out of git.
    - Add and verify ignore rules for graph outputs and local stores.

11. Integrate with agent UX, not just CLI.
    - MCP server registration + agent startup/post-tool hooks + skills path wiring.

12. Preserve repo standards.
    - Follow existing conventions for formatting, linting, commit style, and layout guards.
</lessons_learned>

<discovery_process>
Before editing anything:

1) Read repository policy and structure
- AGENTS.md / CLAUDE.md / README / contributing docs.

2) Detect existing systems (prefer reuse)
- Task runner: mise, just, make, npm scripts, etc.
- Hook manager: hk, lefthook, pre-commit, husky, native git hooks.
- Doctor/health system: mise doctor, make doctor, scripts/doctor.
- Agent wiring: `.mcp.json`, `.claude/`, `.agents/skills`, equivalents.

3) Inventory current graph capability
- Is CRG/Gortex/Graphify already partially installed?
- Are versions pinned?
- Are outputs ignored?

4) Ask targeted questions if ambiguous
- Preferred versions?
- Allowed daemons/background services?
- Secrets backend (env, fnox, vault, pass)?
- CI policy for developer-only tools?
</discovery_process>

<implementation_blueprint>
Adapt this blueprint to local conventions.

A) Dependency pinning
- Pin tool versions in the repo's source of truth.
- Re-lock if lockfiles are used.
- Add local secret override files to gitignore.

B) Unified graph command
- Add a single entrypoint (e.g., `graph`) with subcommands:
  - `setup [tool]`
  - `update [tool]`
  - `build [tool]`
  - `install [tool]`
  - `--dry-run`
  - optional `--force` for semantic/LLM passes
- Ensure safe behavior for tools that mutate config: skip/replace destructive install paths.

C) Doctor checks
- Add checks for:
  - each tool installed
  - MCP wiring present/valid
  - ignore rules for local outputs present
  - secrets backend resolvable (if used)

D) Agent wiring
- Commit deterministic MCP server configuration.
- Wire skills/settings in a way that survives fresh clone/worktree setup.
- Validate JSON and runtime status commands.

E) Git lifecycle refresh
- Add a small refresh script:
  - no-op in CI
  - lock directory/file for single-flight
  - background execution
  - deterministic log path
- Register it on post-commit/post-merge/post-checkout using existing hook tooling.

F) Docs + hygiene
- Add a dedicated README section for graph tooling.
- Document commands, auto-refresh behavior, secrets, side effects, and uninstall.
- Update project structure/dev workflow docs.
- Ensure layout guards permit any new top-level dirs.
</implementation_blueprint>

<verification_checklist>
Run and report evidence for each:

- Tool installation/pinning succeeded.
- Graph entrypoint listed by task runner and shows usage/help.
- Dry-run works and is scoped by tool.
- Setup/update/build per tool returns expected status.
- Doctor checks for graph tooling pass (or clearly report unmet local prerequisites).
- Agent wiring files parse and server status is healthy.
- Hook registration includes post-commit/post-merge/post-checkout.
- Background refresh executes, writes logs, and does not dirty git state.
- Full project gate/lint/test still passes.
</verification_checklist>

<human_review_needed>
Flag decisions needing confirmation:
- [ ] Tool versions differ from known-good defaults.
- [ ] Daemon startup behavior (auto-start vs manual start).
- [ ] CI inclusion/exclusion policy for graph tooling.
- [ ] Secrets backend choice and required key names.
- [ ] Whether to commit agent skill copies vs symlink strategy.
</human_review_needed>

<final_output_format>
Provide:

1. Summary
- What was added/changed and why.

2. Files changed
- Grouped by: pinning, graph command, doctor checks, agent wiring, hooks, docs.

3. Verification evidence
- Exact commands run and key outputs.

4. Deviations
- Any repo-specific adaptations from the standard blueprint.

5. Rollback steps
- Exact files/config entries to remove to fully uninstall graph tooling.
</final_output_format>
