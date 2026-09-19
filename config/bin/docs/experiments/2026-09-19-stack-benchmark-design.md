# Stack benchmark for `config/bin` — design

- **Status:** approved design, pre-registered (thresholds frozen before any port)
- **Date:** 2026-09-19
- **Scope:** choose the implementation stack for the full `config/bin` rewrite

## 1. Goal

Pick the stack for rewriting every `config/bin` utility by building the same
tools in each candidate stack under identical rules and scoring them against
pre-registered metrics.

Priority order: **performance > organization > simplicity > testability >
flexibility**. Performance weighs most but cannot win alone.

"Performance" means **per-call cost when invoked by other programs**: git
aliases (`git/config` calls `gitx` from 54 alias lines), fzf previews
(re-invoked per cursor move), `.zshrc` helpers, and loops in other scripts.
Cost = latency + memory + disk footprint.

### Baseline (measured 2026-09-19, hyperfine `-N`, 20 runs)

| Command                    | Mean    | Peak RSS |
| -------------------------- | ------- | -------- |
| `zsh -fc true`             | 3.6 ms  | 2.8 MB   |
| `bash -c true`             | 4.4 ms  | 6.7 MB   |
| `./xc-md --help` (usage)   | 3.5 ms  | —        |
| `bun -e 0`                 | 30.4 ms | 9.4 MB   |
| `./xc-puts --green hi`     | 57.0 ms | 22.9 MB  |

Hello-world floor per stack (same host, hyperfine `-N`, 50 runs; Bun 1.4.2 is
the Rust-based Bun):

| Hello world                          | Mean    | Peak RSS | On disk |
| ------------------------------------ | ------- | -------- | ------- |
| Rust (`rustc -O`, stripped)          | 1.3 ms  | 1.7 MB   | 334 KB  |
| Bun `--compile`                      | 4.2 ms  | ~9.5 MB  | 59 MB   |
| `usage zsh` script                   | 8.4 ms  | —        | 18 MB (`usage`) |
| `bun h.ts`                           | 23.2 ms | —        | —       |
| `usage exec bun` script              | 27.1 ms | 9.7 MB   | Bun runtime + 18 MB |

## 2. Out of scope

Handled **only after this benchmark lands**, as separate sub-projects:

- Behavior recovery for scripts whose logic was replaced by dummy bodies
  (e.g. `zsys`).
- The rewrite of the remaining scripts.
- The `git/config` aliases that call `!zsh .../gitx` (bypassing the usage
  shebang). The benchmark measures `gitx` by direct invocation only.

## 3. Sample tools

| Tier    | Tool        | Lines | What it stresses                                       |
| ------- | ----------- | ----- | ------------------------------------------------------ |
| Simple  | `xc-puts`   | 104   | Startup + arg parsing floor; many flags                |
| Mid     | `gitx`      | 346   | Hot path; subcommand dispatch; external `git`/`fzf`    |
| Complex | `xc-skills` | 835   | Organization at scale; file I/O; repeatable flags      |
| Evolve  | `xc-sec`    | 80    | Adding a *new* tool (see §8)                           |

## 4. Candidates

| ID     | Stack                                                        | Tools                        |
| ------ | ------------------------------------------------------------ | ---------------------------- |
| **S1** | zsh/bash + `usage` shebang (current model, rebuilt cleanly)   | xc-puts, gitx, xc-skills     |
| **S1b**| Autoloaded zsh functions + thin `usage` CLI wrapper           | xc-puts, gitx                |
| **S2** | Rust + `usage-rs`                                             | xc-puts, gitx, xc-skills     |
| **S3i**| Bun/TypeScript script on a `usage exec bun` shebang ([other interpreters](https://usage.jdx.dev/cli/scripts#other-interpreters)) | xc-puts, gitx, xc-skills |
| **S3c**| Same Bun/TypeScript code, shipped via `bun build --compile`   | xc-puts, gitx, xc-skills     |

- S3i and S3c share one codebase (`src/lib/` + per-tool logic); only the
  entrypoints differ:
  - **S3i:** `#!/usr/bin/env -S usage exec bun`, `//USAGE` header, reads `usage_*`
    env vars. Scored as a full candidate, even though it is expected to lose on
    latency, so the real numbers are on record.
  - **S3c:** a compiled binary that parses `process.argv` in-process against
    the same spec. Help text is generated at build time from that spec with
    `usage`, so `--help` output matches S3i.
- 14 builds from 11 independent codebases (S3i/S3c share one), plus 4 `xc-sec`
  evolve builds (S1, S2, S3i, S3c; S1b skips it — see §8).
- S2 and S3c **may** ship as a single multicall binary (one binary, one symlink
  per tool name). Each stack is judged in its best packaging.

## 5. Phase 0 — behavior contract (gate for everything else)

The existing specs cannot detect lost behavior (`gitx.spec.ts` has 4 tests for
346 lines; no spec asserts exact output). Phase 0 fixes that before any port.

1. **Source of truth:** current implementations of the sample tools. If a
   sample tool turns out to be gutted, use its last real git revision.
   Snapshot them into `~/Work/bench/originals/` with the source commit SHA.
2. **Contract suite** at `~/Work/bench/contract/<tool>/`, black-box,
   run with `bun test`, invoking the tool **directly** (never `zsh <path>`).
   Each case asserts exact stdout, stderr, exit code, and filesystem side
   effects against committed golden files.
3. **External command fakes:** `git`, `fzf`, `gum`, `rg`, `pbcopy`,
   `python3` are replaced by fakes on a prepended `PATH`. Fakes log argv to a
   file and return canned output. The contract asserts the argv log, so a port
   cannot skip or alter an external call.
4. **Coverage rule:** every subcommand, every flag, every `#USAGE example`,
   and at least one error path per subcommand.
5. **Mutation check:** for each subcommand, replace one function body in the
   original with `return 0`; the suite must fail. Any surviving mutant means
   the contract is incomplete.
6. **Target selection:** the suite reads the tool under test from
   `CONTRACT_BIN_DIR`, so the same suite runs against every port unchanged.
7. **Freeze:** once Phase 0 is committed, contract files are read-only.
   A port that modifies them is disqualified.

Phase 0 is also the one place where `xc-sec`'s contract is written (from the
§8 spec, not from the current script).

## 6. Build rules (fairness)

1. **Same brief.** One port-prompt template; only the stack name and idiom
   guide differ. Same contract, same time box (per tool: simple 1 h, mid 3 h,
   complex 6 h of agent/wall time).
2. **Isolation.** Each port is built in its own git worktree; builders do not
   see other stacks' ports.
3. **Idiomatic, not transliterated.** Each port follows its stack's idiom
   guide, fixed here before porting:
   - **S1:** `emulate -L zsh` (or `set -euo pipefail` for bash); `#USAGE`
     headers; shared `lib/*.zsh` sourced by each tool; shellcheck-clean.
   - **S1b:** logic in `functions/` loaded with `autoload -Uz`; no global
     state; a thin `usage` shebang wrapper per tool calls the function.
   - **S2:** one Cargo workspace; shared library crate + bin target(s);
     arg parsing via `usage-rs` only; `anyhow` for errors;
     `std::process::Command` for externals; `cargo clippy -D warnings` clean.
   - **S3i / S3c:** one package; `src/lib/` shared modules; `Bun.spawn`/`$`
     for externals; `strict` TS; `biome` clean. S3i entrypoints use the
     `usage exec bun` shebang; S3c entrypoints parse argv in-process against the
     same spec.
4. **Same externals.** A port may replace an external tool with a native
   library (e.g. `rg` → `regex` crate) only if the contract still passes, and
   the swap must be logged in the port's `NOTES.md`.
5. **Release builds.** Rust: `--release`, `lto = "fat"`, `codegen-units = 1`,
   `strip = true`, `panic = "abort"`. Bun: `--compile --minify --bytecode`.
   Shell: as-is.
6. **Shared UX.** Every port exposes the same `usage` spec, so `--help` and
   completions are identical across stacks.
7. **Equal review.** Each port gets one `/code-review` pass at the same level;
   findings are fixed before measurement.
8. **Same host.** All measurements on one machine, AC power, no other load,
   same toolchain versions (pinned in `mise.toml` and recorded in the report).

## 7. Metrics

### 7.1 Performance (35%) = Latency 60% + Memory 25% + Disk 15%

hyperfine: `-N`, 10 warmup, ≥100 runs, 3 independent sessions; score p50,
report p95.

| ID  | Probe                                                   | Use        |
| --- | ------------------------------------------------------- | ---------- |
| P1  | `--help`                                                | reported   |
| P2  | typical call with fakes (isolates the stack's overhead) | **scored** |
| P3  | typical call with real `git`                            | reported   |
| P4  | 100 sequential calls from a zsh loop                    | **scored** |
| P5  | in-process zsh call (S1b only)                          | compared with others' P4 |
| P6a | peak RSS per call (`/usr/bin/time -l`)                  | **scored** |
| P6b | projected install footprint for all 23 tools, runtime included | **scored** |
| P7  | 20 concurrent typical calls: wall time + summed peak RSS | **scored** (memory) |
| P0  | stack floor: an empty program in the stack (`usage zsh` with an empty body, an empty Rust `main`, an empty `usage exec bun` script, an empty compiled Bun binary) | reported |

Measurement rules (adopted from `jdx/usage` `tasks/perf-*.sh`):

- **Preflight:** before a probe is timed, its typical call runs once under the
  same stubs, and its normalized stdout must equal the original's. A probe that
  fails, or does less work, is never timed; the run aborts for that tool.
- **Estimators:** scores use the **median** (the latency you feel). The
  **minimum** is recorded next to it, and is what the ±10% cross-session
  stability check uses, because background noise only ever adds time.
- **Fixed costs are shown, not hidden:** P0 is reported beside each tool's
  numbers. P2 keeps both the raw value and the stub-adjusted value; only the
  cost of the fake programs is subtracted, never the stack's own runtime.

"Typical call" per tool: `xc-puts --green msg`; `gitx branches`;
`xc-skills ls` (non-interactive mode). Fixed in the benchmark harness.

Bands (score 5 → 1):

| Sub-score | Metric                         | 5    | 4     | 3     | 2      | 1      |
| --------- | ------------------------------ | ---- | ----- | ----- | ------ | ------ |
| Latency   | max(P2, P4 ÷ 100), p50         | ≤5 ms| ≤10   | ≤20   | ≤50    | >50    |
| Memory    | mean of P6a band, P7-RSS band  | P6a ≤5 MB / P7 ≤100 MB | ≤15 / ≤300 | ≤40 / ≤800 | ≤100 / ≤2000 | above |
| Disk      | P6b                            | ≤10 MB | ≤50 | ≤200  | ≤500   | >500   |

Footprint counting: preinstalled runtimes (zsh, bash) count 0; `usage`
counts 18 MB wherever the stack needs it at runtime; the Bun runtime counts
once for S3i (shared by all scripts); compiled binaries include their embedded
runtime. For S1b, P5 replaces P4 in the latency formula.

Each sample tool is scored separately; the stack's Performance score is the
mean across its tools.

### 7.2 Organization (25%)

| Metric                                    | Tool            |
| ----------------------------------------- | --------------- |
| Largest file (LOC), largest function (LOC)| `scc`, `lizard` |
| Duplication %                             | `jscpd`         |
| Locations of shared logic (count)         | manual          |
| Files touched to add a subcommand / tool  | §8 evolve diff  |

Rubric: **5** = no file >300 LOC, no function >40 LOC, dup <3%, one shared
lib, evolve touches ≤2 files outside the new tool. **3** = one of those
limits exceeded. **1** = three or more exceeded.

### 7.3 Simplicity (20%)

| Metric                                            |
| ------------------------------------------------- |
| LOC for the same contract (`scc`, tests excluded) |
| Runtime + build dependency count                  |
| Build step required (yes/no)                      |
| Steps from fresh clone to a working tool          |
| Stacks in use (a mixed verdict counts 2)          |
| **Learning cost:** owner fluency in the stack's language (pre-registered, below) |

Rubric: **5** = lowest LOC (±10%), ≤2 deps, no build step or one command,
≤2 setup steps, owner fluency ≥4. Each shortfall drops one point; fluency ≤2
drops two.

**Owner fluency (1–5), recorded before any port exists; never edited after:**

| Language   | Fluency | Stacks      |
| ---------- | ------- | ----------- |
| zsh/bash   | 4       | S1, S1b     |
| Rust       | 1       | S2          |
| TypeScript | 5       | S3i, S3c    |

Recorded 2026-09-19. Consequence, stated up front: S2 loses two Simplicity
points for learning cost.

### 7.4 Testability (12%)

| Metric                                                  |
| ------------------------------------------------------- |
| Internal functions unit-testable without spawning (y/n) |
| Line coverage measurable (y/n) and value                |
| Unit test suite runtime                                 |
| Effort to fake `git` (lines of test support code)       |

Rubric: **5** = unit tests in-process, coverage ≥80% measured, suite <5 s.
Each shortfall drops one point.

### 7.5 Flexibility (8%)

| Metric                                              |
| --------------------------------------------------- |
| Contract passes on Linux CI (GitHub Actions ubuntu) |
| Installable through a mise backend                  |
| Ecosystem for regex, JSON, TUI without shelling out |
| `xc-sec` evolve: can it drop `python3`              |

Rubric: one point per satisfied item, plus one for the evolve exercise
passing its contract on the first run.

## 8. Evolve exercise — `xc-sec`

`xc-sec` is currently untracked, not on `usage`, and depends on `rg` and
inline `python3`. Each stack (S1, S2, S3i, S3c) implements it **after** its
three ports are done, reusing its own shared lib.

Spec (identical for all stacks):

- `xc-sec scan|redact [--profile balanced|strict] [--dry-run] [paths…]`
- Default targets: the shell/REPL history files listed in the current script;
  extra paths append.
- Patterns: the current balanced and strict sets.
- `redact` writes `<file>.bak.<YYYYmmddHHMMSS>` before rewriting;
  `--dry-run` writes nothing and reports what would change.
- Exit codes: `scan` → 0 no findings, **2** findings, 1 error.
- `usage` help, same shape as the other tools.

Recorded: time to green contract, LOC added, files touched outside the new
tool, shared-lib functions reused, whether `python3` was dropped.

## 9. Decision rule

1. **Disqualify** if any of these hold:
   - any contract test fails;
   - any criterion scores 1;
   - the P6b or P7-memory band is 1.
2. **Total** = 0.35·Perf + 0.25·Org + 0.20·Simp + 0.12·Test + 0.08·Flex.
3. **Winner** = highest total. If the top two are within **0.25**, the higher
   **Simplicity** score wins (it includes learning cost). If still tied, the
   higher Organization score wins. Rationale: a small performance edge is not
   worth adopting a language the owner is less fluent in.
4. **Split verdict allowed:** if S1b beats every other stack's Latency score
   for in-shell callers, the recommendation may be S1b for sourced helpers +
   the overall winner for standalone tools. Its Simplicity score then counts
   2 stacks.
5. **Pre-registered predictions** (recorded now, compared in the report):
   S2 wins Memory and Disk; S2 and S3c tie on the Latency band (hello-world
   floors 1.3 ms vs 4.2 ms); S3i scores Latency 2 (≈27 ms) but survives
   disqualification; S3c needs multicall to avoid a Disk disqualification;
   S1b wins P5; S1 wins Simplicity for the simple tier.

## 10. Deliverables — the `bench` repo

All experiment artifacts live in a **new standalone repo at `~/Work/bench`**,
built to be published on GitHub afterwards. The dots repo keeps only this
design doc and, at the end, a link to the results.

```text
~/Work/bench/
├── README.md              # question, TL;DR verdict, how to reproduce
├── LICENSE                # MIT (same as dots)
├── mise.toml              # pinned toolchain + tasks: setup, contract, bench, report
├── docs/
│   ├── design.md          # copy of this spec (pre-registration, frozen)
│   ├── methodology.md     # probes, bands, rubrics, fairness rules
│   └── results.md         # raw tables, scores, verdict vs predictions
├── originals/             # snapshot of the dots scripts under test + source commit SHA
├── contract/              # Phase 0 suites, fakes, golden files, mutation report
├── stacks/
│   ├── s1-zsh/  s1b-zsh-fn/  s2-rust/  s3-bun/   # s3-bun builds S3i + S3c
│   └── */NOTES.md         # per-port log: time spent, deviations, native swaps
├── bench/                 # harness: hyperfine, RSS, P7 burst, footprint, static metrics
└── results/<date>-<host>/ # raw JSON/CSV per run + machine info (CPU, OS, versions)
```

- `mise run contract STACK=<id>`: runs the frozen contract against any stack.
- `mise run bench`: regenerates every number into `results/<date>-<host>/`.
- `mise run report`: rebuilds `docs/results.md` (tables + charts) from raw data.
  Every latency, memory and disk figure is also shown as a **ratio of S1** and
  of the stack's own P0 floor, because ratios carry over to other machines and
  absolute numbers do not.
- Linux-only, reported-only: **instruction counts** per call (valgrind
  cachegrind), which are deterministic across runs. Marked "not measurable"
  where the runtime does not run under valgrind (likely S3).
- After the verdict: track the winning stack's per-call cost over time with
  [jdx/tak](https://github.com/jdx/tak) (instruction-counted benchmarks kept
  per commit). Out of scope for the comparison itself.
- CI (GitHub Actions, macOS + ubuntu) runs the contract for every stack. It
  also provides the Linux data for Flexibility.

### Publication readiness (before pushing to GitHub)

- Scrub `originals/` and fixtures of personal paths, hostnames, emails, and
  secrets (run `gitleaks` over the full history).
- `originals/` fixtures must not contain real history files; `xc-sec` runs
  against synthetic fixtures only.
- The README states the machine, the date, and that the numbers are
  host-specific, and links to the raw data.
- Creating the GitHub repo and pushing is left to the owner; the plan stops
  at a publish-ready local repo.

## 11. Success criteria for the experiment itself

- The contract kills every mutant from §5.5.
- Every scored number regenerates from `mise run bench` within ±10% across
  sessions, judged on the per-session **minimum**.
- All 14 builds and 4 evolve builds pass the unchanged contract, or are
  explicitly disqualified with the failing cases listed.
- A fresh clone of `~/Work/bench` reproduces the full run with
  `mise install && mise run bench && mise run report`.
- The verdict follows mechanically from §9; no score is adjusted after the
  results are known.
