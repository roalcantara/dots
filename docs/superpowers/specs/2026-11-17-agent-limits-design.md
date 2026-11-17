# Agent limits on macOS — design

Branch `chore/agent-limits` (from `chore/add-todos`), worktree `../dots-agent-limits`.

## Intent

One glanceable place, built into macOS, that shows the usage limits of every agent in use: Claude Code, Codex,
GitHub Copilot and Gemini. Today the numbers are split across three places, and none of them shows every agent:

| Where | Shows |
| --- | --- |
| `omp usage` | Copilot (monthly premium requests), Codex (30-day window, free plan) |
| VS Code Claude Code panel | Claude: session (5h), weekly (7d), Fable limit (per model) |
| Raycast "Agent Usage" extension | Claude; Codex, Gemini, Copilot "Not Configured" |

The experience to match is omarchy's: limits and token/cost stats side by side, at a glance. AgentLimits (menu
bar plus Notification Center widgets, limits plus ccusage tokens and cost) is the macOS shape wanted. The choice is made by installing
the candidates and running them against the real accounts, not from READMEs.

## Goals

- Pick one tool by a recorded, hands-on comparison against the criteria below.
- Install it reproducibly: Brewfile entry, plus settings or login item kept in the repo where the tool allows.
- Its numbers agree with the reference sources (`omp usage`, the VS Code panel) for each agent.

## Non-goals

- Linux or the Docker images: this is macOS only, so the Brewfile entry is `if OS.mac?`.
- Agents other than the four named.

## Anti-goals

- A tool that shows wrong numbers: the Codex free plan's single 30-day window drawn as a 5h/weekly pair counts as
  failing Codex. (Claude passes with session and weekly windows; the Fable limit is extra credit.)
- Reading browser cookies or Keychain items without a prompt the user sees and approves. Any credential read,
  cookies included, is allowed once macOS asks first.
- An in-house build (SwiftBar plugin or AgentLimits fork) chosen before every existing tool has been shown unfit.

## Approaches

- **A. Hands-on comparison (picked):** shortlist on paper, install 3–5 in the worktree, score each against real
  accounts, then wire in the winner. Slower (about an hour, plus Keychain prompts), but decided on evidence.
- **B. Research only, then install the top pick:** faster, but trusts READMEs and misses window/limit
  mismatches like the Codex free plan.
- **C. SwiftBar plugin first** (`omp usage` plus a JSON CLI): most omarchy-like and fewest new apps, but no
  widgets, and it skips testing the existing tools.

## Decided

### Candidates

Paper cut first: drop anything abandoned (no release in the last 6 months), paid with no trial, or missing two or
more of the four agents. Starting list:

| Candidate | Known so far |
| --- | --- |
| [CodexBar](https://github.com/steipete/CodexBar) | MIT, `brew install --cask codexbar`, menu bar + WidgetKit, all four agents, JSON CLI |
| [ClaudeBar](https://github.com/tddworks/ClaudeBar) | Apache-2.0, `brew install --cask claudebar`, macOS 15+, menu bar/notch, all four agents, no widgets listed |
| [AgentLimits](https://github.com/Nihondo/AgentLimits) | menu bar + NC widgets, "In Development", zip release, no Gemini (custom scripts) |
| [LLM Usage Widget](https://github.com/flukelaster/llm-usage-widget) | menu bar; Claude, Codex, Copilot |
| Fetchy (App Store) | closed source, in-app purchases; Claude, Codex, Gemini |
| Usage4Claude, Claude Usage Tracker | Claude and Codex only (likely cut) |
| TokenBar | paid, closed (cut unless a trial exists) |

A fresh search during the shortlist step adds anything newer.

### Criteria (scored per tool, pass/fail first, then notes)

1. **Correct numbers** per agent vs the reference sources, read at the same minute. Must pass for Claude and Codex.
2. **Coverage:** Claude (session + weekly; Fable is extra credit), Codex (30-day free window), Copilot (monthly),
   Gemini (via Gemini CLI, scored like the others).
3. **macOS integration:** menu bar item (required); Notification Center or desktop widgets (scores higher, not
   required); refresh interval.
4. **Credentials:** what it reads (OAuth file, Keychain, browser cookies), and whether macOS prompts for it.
5. **Install:** Brewfile-able (cask or tap), signed/notarized, settings exportable to `config/`.
6. **Upkeep:** last release, open issues, license.
7. **Tokens and cost (preferred, not pass/fail):** token counts and cost per day/week/month, per agent and per
   model, as ccusage reports them. Checked against `ccusage` output for the same period. Between two tools that
   pass 1–3, the one with this wins unless another criterion clearly outweighs it.

### Test procedure (per candidate)

1. Install in isolation (only one candidate running at a time).
2. Configure each agent with the tool's documented, least-privileged auth path.
3. Record the readings next to `omp usage` and the VS Code panel; take a screenshot of menu bar and widget.
4. Note every Keychain/permission prompt.
5. Uninstall fully (app, login item, `~/Library` support files, widget) before the next.

Results go in an evaluation doc: `docs/superpowers/specs/2026-11-17-agent-limits-evaluation.md`, one row per
candidate, screenshots in `docs/superpowers/specs/assets/`.

### Fallback order if nothing passes

1. Best tool for most agents, plus a SwiftBar plugin (`config/swiftbar/plugins/`) for the missing agents, or for
   tokens and cost if the winner lacks them.
2. SwiftBar plugin alone, built on `omp usage` and the winner's JSON CLI if any.
3. Fork of AgentLimits (or the closest open-source candidate) to add the missing agent.

Each fallback step is a new design decision brought back to the user, not done automatically.

### Wiring in the winner

- `cask "<name>" if OS.mac?` in `config/homebrew/Brewfile`, with a comment in the existing style.
- Settings: committed under `config/<app>/` and linked, or a `defaults write` list in a mise bootstrap fragment
  (`config/mise/conf.d/`), whichever the app supports.
- Login item and widget placement documented (widgets can't be placed by script).

## My calls (correct if wrong)

- Reference sources are `omp usage` (Copilot, Codex), the VS Code panel (Claude) and Gemini CLI's own `/stats`
  (Gemini). For tokens and cost, `npx ccusage@latest` (not added to the Brewfile; run only for comparison).
- Gemini CLI is installed and signed in before testing starts: `gemini-cli` in the Brewfile (kept whatever the
  winner), signed in by the user.
- One candidate installed at a time, to keep Keychain prompts and menu bar items attributable.
- Raycast's Agent Usage extension is a reference, not a candidate: it isn't a menu bar or widget surface.
- The agent drives installs and readings and pauses for every Keychain prompt, sign-in or permission dialog,
  which the user approves at the machine. The agent never enters credentials.
- The winner is proposed with the evaluation doc and wired in only after the user approves it.

## Verification

- The evaluation doc has a scored row for every shortlisted candidate and a recorded reason for every cut.
- After wiring in: a clean `brew bundle` installs the winner; its menu bar readings match the references.
- `hk check --all` and `mise run test:specs` stay green.
