# SPECKIT

## COMMAMNDS

1. `/speckit.constitution` **Project ground rules**

   Establishes the project's guiding principles, which every later step is evaluated against. _(once)_
   In enterprise development environments, constitutions often encode:
   - Security requirements mandated by corporate policies.
   - Performance and scalability targets for enterprise workloads.
   - Technology choices aligned with Azure services and internal tooling.
   - Coding standards and architectural patterns from engineering best practices.
   - Compliance obligations such as accessibility standards, personal data protection, and audit requirements.

   ```md
   /speckit.constitution Create principles focused on code quality, testing standards, user experience consistency, and performance requirements
   /speckit.constitution Taskify is a "Security-First" application. All user inputs must be validated. We use a microservices architecture. Code must be fully documented.
   ```

2. `/speckit.specify` **Describe what to build**

   Creates the feature specification from a natural-language description `spec.md`. Focus on the what and why, not the tech stack:
   - checklists/requirements.md: lists the requirements for the feature, including functional and non-functional requirements.
   - spec.md: describes the feature, its purpose, and its requirements.

   ```md
   /speckit.specify Build an application that can help me organize my photos in separate photo albums. Albums are grouped by date and can be re-organized by dragging and dropping on the main page. Albums are never in other nested albums. Within each album, photos are previewed in a tile-like interface.
   /speckit.specify Develop Taskify, a team productivity platform where predefined users create projects, assign tasks, comment, and move tasks across Kanban columns (To Do, In Progress, In Review, Done). Five users (one product manager, four engineers), three sample projects, no login for this first phase.
   ```

3. `/speckit.clarify` **Resolve ambiguities** _Run it before planning, optionally with a focus area._

   Asks targeted questions about anything underspecified and folds your answers back into the spec, so you're not planning on top of ambiguity.

   ```
   /speckit.clarify Focus on task card behavior — status changes, comment permissions, and user assignment.
   ```

4. `/speckit.plan` **Choose the tech stack**

   Generates the design artifacts from the spec `plan.md`. This is where implementation detail belongs — provide your tech stack and architecture:
   - research.md: captures research findings and technology decisions for the document upload and management feature.
   - quickstart.md: provides setup instructions and a high-level overview of how to get started with the implementation.
   - data-model.md: defines the data entities, properties, and relationships needed for the document upload and management feature.
   - plan.md: outlines the technical implementation plan for the document upload and management feature.

   ```
   /speckit.plan Use .NET Aspire with Postgres. The frontend is Blazor Server with drag-and-drop boards and real-time updates. Expose REST APIs for projects, tasks, and notifications.
   ```

5. `/speckit.checklist` **Create a checklist of tasks | validate the spec**

   Generates a quality checklist — `"unit tests for your requirements"` — to confirm the spec is complete, clear, and consistent before you break the work down.

   ```
   /speckit.checklist
   ```

6. `/speckit.tasks` **Break down the work into tasks**

   Generates an actionable, dependency-ordered `tasks.md` from the design artifacts.

   ```
   /speckit.tasks
   ```

7. `/speckit.analyze` **Analyze the spec for risks and gaps**

   Reports conflicts, gaps, and ambiguities across `spec.md`, `plan.md`, and `tasks.md`. It's read-only — if it flags issues, fix them at the source and re-run before implementing.

   ```
   /speckit.analyze
   ```

8. `/speckit.implement` **Implement the features**

   Executes the tasks in tasks.md in dependency order. Run it once to build everything, or scope it to one phase at a time for large features.

   ```sh
   /speckit.implement
   // Please execute all concrete remediation edits for ALL issues until `/speckit.analyze` is green
   ```

9. `/speckit.converge` **verify completeness**

   Checks the codebase against the spec, plan, and tasks. If it finds gaps, it appends new tasks to `tasks.md`; run `/speckit.implement` and converge again until it reports converged. Otherwise you're done — proceed to review or open a PR.

   ```
   /speckit.converge
   ```

## PROMPTS

- Scorecard Summary

  ```md
  Path: .specify/assessments/omp-practice/decision.md

  Criterion, Rating, Justification

  - **Problem validity** | _strong_: Friction in manual OMP discovery, LLM passivity, and worktree/model-routing inefficiencies are confirmed by practitioner experience and repository analysis.
  - **Evidence strength** | _strong_: Grounded in 10+ ecosystem repositories including author dogfooding (can1357/oh-my-pi), modular user configs (sakuradairong/omp-config), and cross-agent setups (makoMakoGo/fish-claude).
  - **Value vs. inaction** | _strong_: Adopting worktree build artifact symlinking, model role routing, and subagent orchestration vastly outweighs the token waste and 30s+ build latency of default status quo.
  - **Feasibility / appetite** | _strong_: Fits a small appetite (2–3 days), focusing on workspace AGENTS.md and .omp/commands/ without complex custom TS hooks or external binary dependencies.
  - **Strategic fit** | _strong_: Directly aligns with project principle of adopting proven, working approaches over in-house re-invention.
  - **Risk posture** | _strong_: Keeping the blueprint minimal and focused on standard .omp/ commands and AGENTS.md avoids CLI API drift risks across OMP releases.
  ```

- Roadmap

  ```md
      ### AUTHORING SPECS | Feature specification

      # small features (shorter)

      # Creates the feature specification from a natural-language description
      # Focus on the what and why, not the tech stack
      # OUTPUT: specs/NNN-slug/spec.md

      /speckit.specify

      #  _`/speckit.plan`_ → `plan.md` — technical design
      # ✅ _`/speckit.tasks`_ → `tasks.md` — dependency-ordered work items
      # - `## Phase N:` headers — **OMP turns these into its todo list**
      # - `**T###:**` ids — unique, required by the structure gate
      # - `[P]` marks — **dispatched as one parallel `task` batch**

      2. Author the spec set → _(specs/NNN-slug/)_

      1. Shorter path — small features

          1.
          2.
          3.




      2. Full path — adds upstream quality gates

          1. 🪝 _`/speckit.constitution`_ → governing principles (one-time)
          2. ✅ _`/speckit.specify`_ → `spec.md`
          3. 🪝 _`/speckit.clarify`_ → resolves ambiguities back into `spec.md`
          4. ✅ _`/speckit.plan`_ → `plan.md`
          5. ⚪ _`/speckit.checklist`_ → requirement-verification checklist
          6. ✅ _`/speckit.tasks`_ → `tasks.md`
          7. 🪝 _`/speckit.analyze`_ → cross-artifact consistency report
          8. 🔁 _`/speckit.implement`_ → the slash-command is not invoked; **step 2 loads the same
              `speckit-implement` skill** into the OMP session via `read skill://speckit-implement`
          9. ⚪ _`/speckit.converge`_ → verifies implementation against spec/plan/tasks
          10. ⚪ _`/speckit.taskstoissues`_ → exports tasks to an issue tracker

      3. Implement on OMP _`/speckit.implement`_

      > Runs SpecKit Implementation on OMP instead of coding agent

      1. 🏠 **`mise run spec:run specs/<slug> [--interactive] [--model <m>] [--max-time <n>] [--dry-run]`**
          1. 🏠 **`mise run spec:preflight structure <slug> --strict`** — launch gate
              - checks `spec.md` · `plan.md` · `tasks.md` present
              - checks `## Phase N` headers
              - checks unique `T###` ids
              - ❌ if red → **refuses to launch**
          2. `rm -f manifest.json stats-*.json *.jsonl` — clears the pass boundary so the record
              describes **this** pass only, not a previous one
          3. `omp stats --json` — cumulative, machine-global usage; **no per-session filter**, which is
              why it is snapshotted before and after and the delta attributed to the run
              - 📄 `stats-before.json`
          4. `omp --model … --advisor --tools read,edit,bash,write,search,find,grep,glob,lsp,ast_grep,ast_edit,task,todo --approval-mode yolo --auto-approve --session-dir … --max-time …`
              - adds `-p` (headless) unless `--interactive`
              - the prompt opens with `read skill://speckit-implement`
              - ⚠️ that vendored skill is **40 lines diverged** from upstream and still instructs a
                  bare `mise run spec:preflight` plus `lint` / `doctrine` / `extract` / `gate`
                  subcommands that **do not exist** — see [Known gaps](#known-gaps)
              - the prompt carries the **`orchestrate`** magic keyword:
              1. **OMP builds its own todo list** from the `## Phase N` headers
              2. ⚡ **`[P]` tasks dispatch as a single `task` call** — `tasks[]` array, `await: true`
              3. **the built-in `reviewer` agent** runs five lenses
                  - 📄 `acceptance/review-rounds.json`
              4. **commits per `commit.policy.ts`** — only once the verdict is `APPROVE`
          5. `omp stats --json`
              - 📄 `stats-after.json`
          6. **exits 1** if any task is left unchecked **or** the verdict is not `APPROVE`

      4. Record and verify

      1. 🏠 **`mise run spec:record specs/<slug>`**
          - 📄 `tools/memory/runs/<pass-id>.metrics.yaml`
          - reads the session `*.jsonl` — assistant turns, tool tallies, wall clock, `[P]` batch count
          - diffs `stats-before` against `stats-after` — tokens, cost, models actually observed
          - records `null` for an absent input — never a fabricated `0`
          - compares against `tools/memory/baselines/000-pass-000.metrics.yaml`
      2. 🏠 **`mise run spec:verify specs/<slug>`** → PA-009..PA-015, PASS/FAIL per criterion
      3. 🏠 **`mise run spec:reset specs/<slug>`** — clears pass output for a clean re-run

      5. Quality gates

      > ⚠️ **`gate` is stricter than `lint:all`.** `hk` runs biome with `--error-on-warnings`; the
      > package script does not. `bun run lint:all` can pass while `mise run gate` fails on a warning —
      > `gate` is the one that decides.

      1. ✅ **`mise run gate`** → `hk check --all` _(all blocking)_
          - ⚡ `bun --bun tsc --noEmit` — types
          - ⚡ `bunx @biomejs/biome check --error-on-warnings --no-errors-on-unmatched .` — lint + format
          - ⚡ `bunx jscpd --reporters console packages/speckit-run/src` — copy-paste detection
          - ⚡ `bunx knip` — unused files, exports and dependencies
          - on the `commit-msg` hook only:
          `bun run packages/speckit-run/src/core/policy/commit.policy.ts <msg-file>`
      2. ✅ `bun run lint:all` — sequential, fails fast
          1. `bun --bun tsc --noEmit`
          2. `bunx @biomejs/biome check .`
          3. `bunx jscpd --reporters console packages/speckit-run/src`
          4. `bunx knip`
      3. ✅ `bun test`



      ### Known gaps

      Verified defects, kept visible rather than discovered again later.

      1. ⚠️ **No agent integration installed.** `specify integration list` reports _"No integration
      currently installed"_, so every _`/speckit.*`_ command in step 1 is unavailable. Fix:
      `specify init … --integration omp --script sh` — dry-run first, the repo already has a
      populated `.specify/`.
      2. ⚠️ **`speckit-implement` instructs commands that do not exist.** It is `author:
      github-spec-kit` but **40 lines diverged** from upstream, and the divergence is handoff-era
      contamination. It tells the agent to run a bare `mise run spec:preflight <dir>` (our task
      requires the `structure` subcommand and rejects the bare form with `unexpected word`) and
      references `lint`, `doctrine`, `extract` and `gate` subcommands that were never implemented
      here. **This skill is loaded into every OMP session** by the step 2 prompt.
      3. ⚠️ **`speckit-preflight` is in-house and stale.** `author: flux`, no upstream counterpart,
      and it references the same four non-existent subcommands throughout.
      4. 🏠 **~2,240 lines of in-house logic** across the five `mise run spec:*` tasks and
      `packages/speckit-run`. Roadmap: replace with Spec Kit extensions, presets and bundles where
      an equivalent exists.


      ## CONTEXT
      This is a greeenfield bun workspace that aims to learn, define, perfect a multiagentic workflow to run speckit on omp.
      This greeenfield uses both /Users/roalcantara/Work/flux_reference and /Users/roalcantara/Work/bun/flux as inspiration/reference and aims to adopt everything that works well from both inspiration repos, but replace as much as possible all in-house solution in these repos by speckit or omp native alternatives (more detail in .specify/memory/constitution.md).

      As a greenfield project many things must be bootstraped, defined and setup (tooling, documents, bun workspace, including a M0 baseline to be used to perfect the workflow - .specify/memory/roadmap.md - and so on) in order to prove the SDD→OMP adoption path and then be able to evaluate speckit and omp solution to perfect the workflow.

      ## ISSUE

      The issue is that the speckit has landed and briging many norms and rules (.specify/memory/constitution.md) that are either incomplete or bloking the progress of the repo setup

      ## TASK

      Please, brainstorming a plan to finish the repo setup. Here are some suggestions, please evaluate, clarify, fix, simplify and improve these suggestions:

      > IMPORTANT:
      > ALL work MUST follow/respect as much as possible /Users/roalcantara/Work/flux/.specify/memory/constitution.md to prevent future drifts
      > NEW commit must follow these rules /Users/roalcantara/Work/bun/flux/docs/authority/doctrine/git-workflow.doctrine.md
      > mise.toml is the is the single source of truth for tool versions and task definitions - new tools must be installed either in package.json or mise.toml - the most suitable option for each tool

      ### PHASE 1: RESET

      Goal: Discard all current git commits, stash .specify and .omp to easy the setup

      - Discart all current commits from /Users/roalcantara/Work/flux - they will be rewriten.
      - git stash all files related/created/used by .specify and .omp - they will be added later
      - Ensure that `bun test` and `bun run lint:all` are both green and create the initial commit with all current project (without .specify and .omp)

      ### PHASE 2: TOOLING

      Goal: Import all relevant tooling from the reference repos to ensure the project quality and best-practices

      - Inspect both /Users/roalcantara/Work/flux_reference and /Users/roalcantara/Work/bun/flux and map everything that is worth adopting and defering in /Users/roalcantara/Work/flux - For example, but not limited to:
      1. dependency-cruiser
      2. ls-lint
      3. mdschema
      4. shellcheck
      5. gitleaks
      6. Commit-check
      7. tombi
      8. todo.schema
      9. markdownlint-cli2
      10. ast-grep (all above plus rules)
      11. skills-lock (skills CLI config file that manages the the skills at .agents/skills - all above plus install all skills in .agents/skills via skills CLI)
      - For each tool: the plan must cover: installation, setup - using the same (or improved) settings present in the reference repo -, package.json scripts adjust, hk scripts adjust, README.md adjust)
      - For each tool fully imported create a git commit following the mentioned rules
  ```

- Complete setup

  ```md
  ## 1. CONTEXT

  This is a greeenfield bun workspace that aims to learn, define, perfect a multiagentic workflow to run speckit on omp.
  This greeenfield uses both /Users/roalcantara/Work/flux_reference and /Users/roalcantara/Work/bun/flux as inspiration/reference and aims to adopt everything that works well from both inspiration repos, but replace as much as possible all in-house solution in these repos by speckit or omp native alternatives (more detail in .specify/memory/constitution.md).
  As a greenfield project many things must be bootstraped, defined and setup (tooling, documents, bun workspace, including a M0 baseline to be used to perfect the workflow - .specify/memory/roadmap.md - and so on) in order to prove the SDD→OMP adoption path and then be able to evaluate speckit and omp solution to perfect the workflow.

  ## 2. PROJECT (Do not re-derive — these are verified)

  ~/Work/flux repo
  .specify/memory/constitution.md binding
  .specify/memory/findings.md verified negatives + known traps
  .recon/manifest.yaml stack profile; human-owned, YOU update it

  ## 3. ISSUE

  This project must complete the setup, reorganize the commits to respect the conventions in a clean and logical timeline, review all files under .specify/memory and update the roadmap.

  ## 3. BRAINSTORMING

  /brainstorm then implement a plan to:

  1. soft undo ALL commits (they must be rewritten and organized in a sane, logical timeline)
  2. stash both .specify and .omp folder (they will be poped latter just before the repo is ready)
  3. Create a ROADMAP.md in the project root ()

  ## 4. BINDING RULES

  Output
  Standard recon report: primary / runnerUp / consideredRejected / coverage matrix.
  Then an explicit ADOPT / ADAPT / DEFER line for: git messages linter
  A BUILD verdict is valid only as primary=null plus a coverage matrix whose links were actually read.
  Enumerate the category before any verdict:
  A BUILD verdict without a recorded enumeration is invalid.
  `primary: null` + a coverage matrix whose links you actually read is the only legitimate BUILD.
  A budget is met by optimising the work, not narrowing the gate:
  Excluding a package, or passWithNoTests, is NOT compliance.
  Weakening a budget or a linter rule IS LAST OPTION:
  Requires an ADR in docs/adr/ recording what was measured, what was tried, and what would restore the value —
  referenced from a roadmap ledger entry via `governed-by`. LAST RESORT.
  Evidence over assertion:
  paste real command output.
  Report WALL CLOCK (`time`), never a tool's self-reported figure — they differ 3-7x here.

  ## 5. VEREDICT

  UPDATE .recon/manifest.yaml with the verdict; It is human-owned
  recon writes only .recon/cache.yaml.
  Treat updating it as part of adopting anything.

  ## 6. DONE

  A tool has been defined to validate git commits that fits the current project
  .recon/manifest.yaml reflects reality
  .specify/memory/constitution.md not edited; amendments are separate.
  Report outputed

  ## VALIDATION

  After the installation/setup/configured/documented of the chosen tool, mise tasks and hk configurations and pre-commit created and validated:

  - DO NOT create live specs to validate the git commit validation
  - Rater, execute as many tests (git commit creation, undo, loop) as many as necessay to ensure that all rules are ACTUALY respected

  ## DOCS

  Update README (following the current conventions) and any other relevant file

  ## GREEN

  Resolve any test/lint issues in every package if need until `bun test` and `bun run lint:all` is fully green.

  ## COMMIT

  Create a new commit to add this feature following /Users/roalcantara/Work/bun/flux/docs/authority/doctrine/git-workflow.doctrine.md

  ## DONE

  bun test exit 0, within 500ms wall
  bun run lint:all exit 0, within 2s warm (cold may exceed; say so)
  git status clean
  .recon/manifest.yaml reflects reality
  every claim backed by pasted output
  Anything weakened has an ADR. If nothing was weakened, say so explicitly.

  recon

  CONTEXT
  Repo: ~/Work/flux. Greenfield project
  Constitution mandates gates:
  `bun run lint:all` MUST complete in <= 2s ← script absent
  `bun test` MUST complete in <= 500ms ← currently 2.05s (recon suite)

  CONSTRAINTS

  - mise is the adopted installer and version pin
  - Every candidate MUST be installable via mise or bun. A tool needing a separate package manager, a global install, or a system runtime is disqualified unless nothing else meets the budget — say so explicitly if that happens.
  - bun is the runtime, package manager and test runner. Do not propose node, npm, pnpm or yarn.
  - The chosen tool MUST be able to ensure/validate these rules /Users/roalcantara/Work/bun/flux/docs/authority/doctrine/git-workflow.doctrine.md (but in the project /Users/roalcantara/Work/bun/flux)
  - Although the reference repo /Users/roalcantara/Work/bun/flux uses /Users/roalcantara/Work/bun/flux/tools/policy/commit.policy.ts to validate git commit messages, this repo favors external options instead of in-house solutions (Adopt or adapt ready external options before authoring custom tooling. Build only what recon proves does not exist, and record the enumeration that proved it - .specify/memory/constitution.md), meaning:
    Existing tool integrated to to project (package.json or mise or hk) is preferable - custom in-house solutins (like commit.policy.ts) MUST BE THE VERY LAST OPTION
  - Ideally, the chosen tool would have a config file to covers the hard rules from /Users/roalcantara/Work/bun/flux/docs/authority/doctrine/git-workflow.doctrine.md
  - TASKS AND SCRIPTS:

  DOCS
  Update README (following the current conventions)

  RULES

  - Paste real command output for every claim. Principle III forbids asserting an outcome without it.
  - Report timings before AND after any optimisation.
  - "The budget is unreachable, here is the ADR" is acceptable ONLY with measurements showing what was tried.
  - Do not edit .specify/memory/constitution.md; amendments are separate.

  SUGGESTIONS
  Here are some optios to be evaluated - but please, DO NOT be lined only to these tools - meaning, search on google AND github repos with similar solution is REQUIRED:

  OUTPUT
  Standard recon report: primary / runnerUp / consideredRejected / coverage
  matrix. Then an explicit ADOPT / ADAPT / DEFER line for: git messages linter
  A BUILD verdict is valid only as primary=null plus a coverage matrix whose
  links were actually read.
  ```

- RECON

  ```md
  /recon "What tool/solution could be adopted in this monorepo to validate git messages in pre-comit hook respecting the project conventions? Consider - but not limited to:
  SUGGESTION: Also, evaluate hk native options, such as - but not limited to:

  - https://hk.jdx.dev/cli/migrate/pre-commit.html
  - https://hk.jdx.dev/cli/run/pre-commit.html
  - https://hk.jdx.dev/builtins.html#check-conventional-commit
  - https://hk.jdx.dev/cli/run/prepare-commit-msg.html
  - https://hk.jdx.dev/cli/run/commit-msg.html
  - https://hk.jdx.dev/cli/util/check-conventional-commit.html
  - https://hk.jdx.dev/builtins.html
    SUGGESTION: Also, evaluate any tool that could integrated to the repo such as - but not limited to:
  - https://pre-commit.com
  - https://conventionalcommits.org/en/about
    SUGGESTION: Also, search unknown solutions/options
  - SEARCH on GOOGLE for "pre commit hook git commit conventional validation" and evaluate the best fit options
  - SEARCH on github for repositorios that validates git commit messages in bun workspaces, perhaps using mise, perhaps using hk

  Enumerate the category, do not stop at the first hit:
  Coverage note: `official_registry` is ONE coarse row and Spec Kit has TWO catalogs (extensions/ and presets/catalog.community.json).
  Read every link; a passing coverage gate proves a class was visited, not covered."
  ```

- cd ~/.agents/skills/skill-creator && timeout 540 python3 -m scripts.run_eval

  ```sh
  cd ~/.agents/skills/skill-creator && timeout 540 python3 -m scripts.run_eval \
  --eval-set ~/.agents/skills/omp-usage/evals/trigger-set.json \
  --skill-path ~/.agents/skills/omp-usage \
  --runs-per-query 1 --verbose \
  > /tmp/claude-501/-Users-roalcantara-Work-flux/10ae3cd7-6b22-4f19-bde0-62c3a9fefc68/scratchpad/eval-omp-usage.json 2>/tmp/claude-501/-Users-roalcantara-Work-flux/10ae3cd7-6b22-4f19-bde0-62c3a9fefc68/scratchpad/eval-omp-usage.log
  echo "exit=$?"; tail -30 /tmp/claude-501/-Users-roalcantara-Work-flux/10ae3cd7-6b22-4f19-bde0-62c3a9fefc68/scratchpad/eval-omp-usage.log
  ```

## REFERENCES

- [Spec-Driven Development with GitHub Spec Kit][0]
- [Speckit Quickstart][1]

[0]: https://learn.microsoft.com/en-us/training/modules/spec-driven-development-github-spec-kit-enterprise-developers/3-examine-github-spec-kit 'Spec-Driven Development with GitHub Spec Kit'
[1]: https://github.github.com/spec-kit/quickstart.html 'Speckit Quickstart'
