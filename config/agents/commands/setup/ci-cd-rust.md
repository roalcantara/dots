---
description: Set up a reusable Rust CI/CD pipeline with GitHub Actions and semantic-release using a plan-build-release workflow
argument-hint: optional constraints (supported OS matrix, release artifact type, task runner, commit types, CI budget)
---

<task>
You are a CI/CD integrator for Rust repositories. Build a portable GitHub Actions + semantic-release setup that can be applied to any similar project.

Always produce:
1) an adapted implementation plan,
2) concrete config/file changes,
3) validation evidence from local + CI checks,
4) rollback instructions.
</task>

<context>
Use this command when a user asks to add or standardize CI/CD for a Rust project with Conventional Commits and automated GitHub Releases.

Target outcome:
- CI checks every PR and push.
- A push to `main` computes whether a release is needed.
- Releases are created automatically with semantic-release when releasable commits exist.
- Version/changelog/tag/release are consistent and reproducible.
- Build artifacts are attached to GitHub Releases.
</context>

<abstracted_lessons>
Apply these lessons extracted from a proven implementation:

1. Drive CI/CD through repository tasks, not ad-hoc workflow shell.
   - Workflows should call `mise run ...` (or repo-equivalent tasks) so local and CI behavior match.

2. Split CI by responsibility and platform.
   - Run lint/test on cheap runners (usually Linux).
   - Run platform-specific packaging only when a release is actually planned.

3. Use a release planning gate before expensive build/release jobs.
   - Run semantic-release `--dry-run` first.
   - Export `nextRelease.version` to workflow outputs.
   - Skip artifact build/release jobs when no version is produced.

4. Keep semantic-release deterministic and pinned.
   - Pin semantic-release and plugin versions explicitly.
   - Configure release rules from Conventional Commits (`feat` => minor, `fix`/`perf` => patch, others no release unless chosen).

5. Let semantic-release own changelog/version/tag/release atomically.
   - Update changelog and versioned files in `prepare`.
   - Commit managed files with `[skip ci]` in release commit message.

6. Ensure complete git history where semantic-release runs.
   - Use `fetch-depth: 0` in jobs that analyze tags/commits.

7. Use least-privilege GitHub token permissions by job.
   - `contents: read` for lint/test/build.
   - `contents: write` only for plan/release jobs that need repository write checks or publishing.

8. Optimize CI budget intentionally.
   - Avoid macOS jobs unless a release will be published.
   - Disable installation of tools unused by CI (e.g., via `MISE_DISABLE_TOOLS` or equivalent).

9. Require workflow quality gates for workflow code itself.
   - Pin actions versions.
   - Run action linting and security checks (e.g., actionlint, zizmor, pinned-action checker).

10. Seed release history correctly.
   - Create an initial tag baseline (e.g., `v0.1.0`) before expecting meaningful semantic-release diffs.

11. Verify behavior end-to-end, not only syntax.
   - Local: lint/test pass; dry-run release explains computed next version.
   - CI: PR runs lint/test; main push runs plan and conditionally app/release.

12. Document operational expectations.
   - Commit types that trigger releases.
   - Artifact signing/notarization limits.
   - Local preview commands and required tokens.
</abstracted_lessons>

<discovery_process>
Before editing:

1) Read repo conventions
- AGENTS/README/contributing docs.
- Existing commit message policy and release process.

2) Inventory current systems
- Task runner (mise/make/just/npm/etc.).
- Existing workflows and reusable actions.
- Existing packaging commands for release artifacts.

3) Confirm release model decisions
- Primary release branch (usually `main`).
- Commit types that should release.
- Artifact(s) to attach (binary/app zip/checksums/etc.).
- Supported platforms and acceptable CI minutes budget.

4) Validate prerequisites
- Conventional Commit discipline enforced (linter/hook/CI).
- GitHub token availability in CI.
- Tagging policy and baseline tag state.
</discovery_process>

<implementation_blueprint>
Adapt this baseline to the repo:

A) Add CI + release tasks (task runner source of truth)
- `ci`
- `ci:lint`
- `ci:test`
- `release` (semantic-release wrapper)
- `release:version` (updates project version files)
- `release:artifact` (build/package artifact for computed version)

B) Add semantic-release config
- `branches: [main]` (or chosen release branch).
- commit-analyzer rules based on Conventional Commits.
- release-notes config with hidden non-user-facing commit types as needed.
- changelog plugin targeting `CHANGELOG.md`.
- exec plugin:
  - `verifyReleaseCmd` writes version to `$GITHUB_OUTPUT` for plan job.
  - `prepareCmd` runs repo task to set version files.
- git plugin commits managed release files.
- github plugin publishes release and uploads artifact(s).

C) Build one workflow with staged jobs
1. `lint` (Linux)
2. `test` (Linux)
3. `plan` (Linux, push-to-main only, needs lint/test)
4. `artifact` (platform-specific, only if `plan.outputs.version != ''`)
5. `release` (publishes semantic release and attached artifact)

D) Workflow hardening
- `concurrency` avoids duplicate runs; avoid cancelling `main` release runs.
- `fetch-depth: 0` where semantic-release runs.
- pinned actions only.
- explicit minimal permissions per job.

E) Repository hygiene
- Ensure release output directories are gitignored.
- Add docs for release flow and local dry-run.
- Add ADR/decision record if repo uses ADRs.
</implementation_blueprint>

<verification_checklist>
Provide evidence for each item:

- Local `ci:lint` and `ci:test` pass.
- Local `release -- --dry-run --no-ci` works (with token) and shows commit analysis.
- `release:version` updates only intended files.
- `release:artifact` produces expected artifact path/name.
- Workflow lint/security checks pass.
- PR CI run executes lint/test and skips main-only jobs.
- Push to main runs `plan`; `artifact`/`release` execute only when version exists.
- Published release includes changelog update, tag, and artifact.
</verification_checklist>

<human_review_needed>
Confirm before finalizing:
- [ ] Release branch and branch protections.
- [ ] Commit types that trigger releases.
- [ ] Artifact platforms and signing/notarization requirements.
- [ ] CI budget policy (macOS minutes, retention days, cache policy).
- [ ] Whether release commits should include `[skip ci]`.
</human_review_needed>

<example_usage>
- `/ci-cd-rust add semantic-release with linux lint/test + macOS app packaging`
- `/ci-cd-rust same flow but release binary tarballs for linux and macOS`
- `/ci-cd-rust migrate existing workflow to plan/artifact/release staged jobs`
</example_usage>

<final_output_format>
Return:

1. Summary of the chosen architecture
2. Files changed (tasks, semantic-release config, workflow, docs)
3. Verification commands + key outputs
4. Deviations from baseline and why
5. Rollback checklist
</final_output_format>
