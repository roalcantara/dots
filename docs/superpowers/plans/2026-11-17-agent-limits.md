# Agent Limits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pick, by hands-on comparison, the macOS tool that shows Claude, Codex, Copilot and Gemini limits (plus
tokens and cost where possible), and install it reproducibly from the dots repo.

**Architecture:** Evaluation first: shortlist on paper, test each candidate alone against reference readings, and
record everything in an evaluation doc. The user approves the winner, then it's wired in through the Brewfile, the
repo's config linking or a mise bootstrap fragment, and the docs.

**Tech Stack:** Homebrew Brewfile, mise bootstrap fragments (`config/mise/conf.d/`), Bun integration specs
(`test/integration/bootstrap/`), SwiftBar (fallback only).

**Spec:** `docs/superpowers/specs/2026-11-17-agent-limits-design.md`

## Global Constraints

- Work in `../dots-agent-limits`, branch `chore/agent-limits`. Never push or open a PR.
- Git always through `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`; stage named paths only.
- Conventional Commits with a capitalized description, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The agent never types credentials. Every Keychain prompt, sign-in, cookie or permission dialog: stop, tell the
  user what is asking and why, and wait for them to approve it at the machine.
- One candidate installed and running at a time.
- macOS-only Brewfile entries end in `if OS.mac?` with a `# comment` in the existing style.
- Pass/fail: correct numbers for Claude (session + weekly) and Codex (30-day free window), plus a menu bar item.
  Preferred, not required: Gemini, Copilot, widgets, Claude's Fable limit, tokens and cost.
- Paper cut: no release in the last 6 months, paid with no trial, or missing two or more of the four agents.
- Fallbacks (best tool + SwiftBar plugin, SwiftBar alone, fork) are never started without the user's decision.

## Review Focus

1. **Expired or missing credentials:** a tool must show a clear error or stale marker, not 0% or old numbers as
   fresh. Checked in Task 3, step 5.
2. **Codex free plan's single 30-day window:** must not be drawn as 5h/weekly. Checked in Task 3, step 4.
3. **Repeated Keychain prompts:** a prompt on every refresh, not just once, is a failure of criterion 4. Checked in
   Task 3, step 6 (leave it running 30 minutes).
4. **Leftovers after uninstall:** login items, widgets or `~/Library` files left behind skew the next candidate.
   Checked in Task 3, step 8.
5. **Settings lost on reinstall:** the winner's settings must survive `brew reinstall`. Checked in Task 5, step 6.

---

### Task 1: Gemini CLI as a reference source (superseded)

> Superseded: Gemini is Google AI Pro through Antigravity, so `agy -p /usage` (antigravity-cli, already in the
> Brewfile) is the reference. Done, then reverted.

**Files:**
- Modify: `config/homebrew/Brewfile` (DEVTOOLS agents block, next to `cask "codex"`)
- Test: `test/integration/bootstrap/brewfile-profiles.spec.ts`

**Interfaces:**
- Produces: a signed-in `gemini` CLI whose `/stats` is Gemini's reference reading in Task 3.

- [ ] **Step 1: Write the failing test** — add to `describe("Brewfile profiles")`:

```ts
it("gemini-cli for desktop,dev only", () => {
  expect(container).not.toContain("gemini-cli");
  expect(desktop).not.toContain("gemini-cli");
  expect(dev).toContain("gemini-cli");
});
```

- [ ] **Step 2: Run it and see it fail**
Run: `bun test test/integration/bootstrap/brewfile-profiles.spec.ts`
Expected: FAIL on `gemini-cli for desktop,dev only`.

- [ ] **Step 3: Add `brew "gemini-cli"  # Google Gemini coding agent CLI` after `cask "codex"`**

- [ ] **Step 4: Run it and see it pass** (same command). Expected: all pass.

- [ ] **Step 5: Install and hand sign-in to the user**
Run: `brew install gemini-cli`, then ask the user to run `gemini` and sign in. Afterwards `gemini` → `/stats`
shows a quota. Expected: a usage figure, not a sign-in prompt.

- [ ] **Step 6: Commit** `config/homebrew/Brewfile` and the spec:
`feat(brew): Add Gemini CLI, the Gemini usage reference`.

### Task 2: Shortlist and the evaluation doc

**Files:**
- Create: `docs/superpowers/specs/2026-11-17-agent-limits-evaluation.md`

**Interfaces:**
- Produces: the evaluation doc with a **Cut on paper** table (`Candidate | Source | Reason`) and a **Scored**
  table that Task 3 fills, one row per shortlisted candidate:
  `Candidate | Version | Claude | Codex | Copilot | Gemini | Fable | Tokens/cost | Menu bar | Widgets | Credentials read | Prompts | Install | Last release | License | Verdict`.
  Each agent cell is `pass` / `wrong: <what>` / `missing`, with the reading and the reference next to it.

- [ ] **Step 1: Search again for newer tools** (2026; "macOS menu bar AI usage limits", "WidgetKit Claude Codex
usage", Homebrew casks matching `usage|limits|codexbar|claudebar`). Add any found to the spec's candidate list.

- [ ] **Step 2: Paper-cut every candidate** against the Global Constraints' paper-cut rule, reading each repo's
releases page, README and license. Starting list: CodexBar, ClaudeBar, AgentLimits, LLM Usage Widget, Fetchy,
Usage4Claude, Claude Usage Tracker, TokenBar. Expected: 3–5 left; every cut has a reason in the table.

- [ ] **Step 3: Record the references** at the top of the doc: how each is read (`omp usage`; VS Code Claude
panel; `agy -p /usage`; `npx ccusage@latest daily`, `weekly`, `monthly`).

- [ ] **Step 4: Run `hk check --all`.** Expected: markdownlint green.

- [ ] **Step 5: Commit** the doc: `docs(specs): Shortlist the agent limits candidates`.

### Task 3: Hands-on test of one candidate (repeat per shortlisted candidate)

**Files:**
- Modify: `docs/superpowers/specs/2026-11-17-agent-limits-evaluation.md` (its **Scored** row)
- Create: `docs/superpowers/specs/assets/agent-limits-<candidate>-menubar.png`, `…-widget.png` (if it has one)

**Interfaces:**
- Consumes: the Scored table and references from Task 2.

- [ ] **Step 1: Check nothing from a previous candidate is left**: no other usage app in
`osascript -e 'tell application "System Events" to get name of every login item'`, no widget from it.

- [ ] **Step 2: Install** by cask (`brew install --cask <name>`), else the signed release. Note version, and
whether Gatekeeper accepts it (`spctl -a -vv <app>`).

- [ ] **Step 3: Configure each agent** through the tool's documented auth path, preferring CLI/OAuth credentials
over cookies; stop for every prompt (Global Constraints). Log each prompt: what asked, for what.

- [ ] **Step 4: Read and compare** in the same minute: tool vs `omp usage` (Codex, Copilot), VS Code panel (Claude),
`agy -p /usage`, and the tool's tokens/cost vs `npx ccusage@latest` for today and this week. A difference of
1 percentage point or less passes. Codex shown as a 5h/weekly pair: `wrong`.

- [ ] **Step 5: Expired credential check**: for one agent, have the user sign out of its CLI (Codex:
`codex logout`), wait one refresh, record what the tool shows, then have the user sign back in.

- [ ] **Step 6: Leave it running 30 minutes**; record the refresh interval and any repeated prompt.

- [ ] **Step 7: Screenshots** of the menu bar dropdown and, if any, a Notification Center/desktop widget added by the
user. Save them under `assets/`, cropping out email addresses.

- [ ] **Step 8: Uninstall fully**: `brew uninstall --cask --zap <name>` (or delete the app plus its
`~/Library/{Application Support,Preferences,Caches,Group Containers}` entries), remove its login item and widget.
Re-run step 1's check. Expected: nothing left.

- [ ] **Step 9: Fill the row, run `hk check --all`, commit** the doc and screenshots:
`docs(specs): Score <candidate> for agent limits`.

### Task 4: Pick the winner — stop for the user

**Files:**
- Modify: `docs/superpowers/specs/2026-11-17-agent-limits-evaluation.md` (a **Verdict** section)

- [ ] **Step 1: Write the verdict**: winners are among candidates passing the pass/fail line; among those, prefer
tokens/cost, then coverage, then widgets, then credentials, then upkeep. If none passes, write which fallback
applies and why.

- [ ] **Step 2: Commit**: `docs(specs): Propose the agent limits winner`.

- [ ] **Step 3: Stop.** Present the verdict to the user. Task 5 starts only on their approval; a fallback goes back
to brainstorming as a new design.

### Task 5: Wire in the winner

**Files:**
- Modify: `config/homebrew/Brewfile` (next to `cask "swiftbar"`)
- Create either `config/<app>/…` (if the app reads a config file) or `config/mise/conf.d/<app>.toml`-style
  `defaults write` entries following `config/mise/conf.d/macos.toml` (if it uses `defaults`)
- Modify: `test/integration/bootstrap/brewfile-profiles.spec.ts`, plus `macos-defaults.spec.ts` if it uses `defaults`
  or a login item (the SwiftBar login item at line 129 is the pattern)
- Modify: `docs/MACOS.md` (a short section: what it shows, where settings live, how to add the widget)

**Interfaces:**
- Consumes: the approved winner from Task 4, its cask name and its settings domain.

- [ ] **Step 1: Write the failing tests**: in `brewfile-profiles.spec.ts`, the cask is in `desktop` and
`desktop,dev`, not `container`; if it has a login item, extend the login-item map in `macos-defaults.spec.ts`;
if it uses `defaults`, assert the keys chosen in step 3 are written by the bootstrap fragment.

- [ ] **Step 2: Run them and see them fail**:
`bun test test/integration/bootstrap/brewfile-profiles.spec.ts test/integration/bootstrap/macos-defaults.spec.ts`.

- [ ] **Step 3: Configure the app by hand with the user** (which agents, menu bar style, refresh), then capture its
settings: `defaults read <domain>` or the config file. Keep only keys the user chose; never commit tokens or
account IDs (check with `rg -i 'token|secret|@' <file>`).

- [ ] **Step 4: Add the cask, settings and login item** so the tests pass; add the `docs/MACOS.md` section.

- [ ] **Step 5: Run the gates**: `mise run test:specs` and `hk check --all`. Expected: both green.

- [ ] **Step 6: Reinstall check**: `brew reinstall --cask <name>`, then the bootstrap task for the settings.
Expected: the menu bar shows the same agents and style without reconfiguring.

- [ ] **Step 7: Commit** the named files: `feat(macos): Show agent limits with <app>`.
