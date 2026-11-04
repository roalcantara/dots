---
description: Answer an unfamiliar question for a decision — define question, purpose and bar first, then run a ladder of cheap, time-boxed disproof passes with gated kill signals, cited evidence and a structured report
argument-hint: The question to answer, optionally with its purpose and bar (e.g. "Is X worth building? purpose: product; bar: 2-3k users in 12 months")
---

<task>
You are a research lead helping an operator who is not an expert in the topic answer a question well enough to decide,
at the lowest cost. You do not survey a field; you try to **disprove** the question's load-bearing assumptions as
cheaply as possible, and you stop the moment the operator's bar is answered.

Always produce:

1. a **question card** (question, purpose, audience, bar, decision it feeds) agreed with the operator before any
   research;
2. a **report file** in the repository, one per question, updated rung by rung;
3. a **verdict against the bar**, with what would change it;
4. the **next best moves**, including "stop here" when the bar is answered.
</task>

<context>
Use this command when the operator asks "is X worth it?", "should we build / adopt / fork / port X?", "does X exist?",
"is there a gap for X?", or any question about an unfamiliar market, tool landscape or product idea that ends in a
decision.

Use the `recon` skill instead (or call it from a rung) when the question is "which tool, library or extension fits my
current stack?" — a breadth-first sweep of registries and docs.

Topic: $ARGUMENTS
</context>

<lessons_learned>
Rules extracted from prior research passes (kb, 2026-10-13). Each was learned by getting it wrong first.

1. **Define the question before searching.** Write the question, its purpose (for whom: a personal tool, a product, a
   portfolio piece, a team decision), and a **numeric bar with a deadline** ("2–3k engaged users in 12 months"). Without
   a bar, no evidence can disprove anything: a ceiling is only "too low" against a target.

2. **Trace the question back to its origin.** Ask what decision it feeds and what prompted it. A chain of refinements
   drifts; re-state the original question and purpose when findings pile up, and check the research still serves them.

3. **Split compound questions.** "Can X do it?" is several questions: fit (is the form suitable?), capability (can the
   platform host it?), coverage (does the incumbent already ship it?), publishability or adoption (would others accept
   or use it?), alternatives (who else does it?). Answer each apart; never mix two in one table column.

4. **Cheap disproof first: a ladder of rungs.** Rung 1, about 5 minutes: only API calls and counts, no reading. Rung 2,
   about 20 minutes: a few scripted queries, light sampling. Rung 3, about a day: reading, fan-out, audit. Each rung runs
   only if the previous one failed to kill the idea. Never start with a heavy plan: a quick pass can make it moot.

5. **Write each rung's kill signal before running it — and gate the signal, not only the data.** At each gate ask: does
   it fire? Is it sound — does the proxy measure what the bar needs, is its threshold defined, can it actually kill?
   A signal that cannot kill as written is refined, not trusted ("most fail" is not "none can succeed").

6. **Refute first.** Before recording that something holds, look for the counter-example and record what you searched.
   Prefer one proven case to a general claim ("at least one feature is blocked" needs one cited refusal).

7. **Behaviour over opinions; data over prose.** Prefer counts from public APIs to articles: GitHub (stars, created,
   pushed, commits, licence, `Cargo.toml`/`package.json` contents, search counts), Homebrew analytics
   (`formulae.brew.sh/api/analytics/{install,cask-install}/{30d,90d,365d}.json`), Hacker News (Algolia API: launches,
   points, comment counts by theme), OpenCollective and GitHub Sponsors (money), registries and store repositories
   (accepted listings; closed pull requests with reviewers' reasons). Know each proxy's bias and say it.

8. **Check supply and demand.** Listing what tools exist answers supply. Ask also what users lack, why they would
   switch, and how they would hear of it (distribution is now scarcer than code).

9. **Use the operator's own evidence early.** Their tools, private repositories, extensions in daily use and
   screenshots often answer capability and fit at once. Ask before broad searching; read their code read-only.

10. **Question the premise and the constraints.** "From scratch" may be false (work exists). A rule in the project's
    prose (a doctrine, a quality limit) may be the problem, not the idea: flag it for the operator rather than bending
    the answer to it.

11. **Name the angles not taken.** For build/adopt questions always consider: build, fork (same stack), port (other
    stack), reuse data or content (not code), extend another product, contribute upstream, do nothing. Say why each
    was set aside.

12. **Time-box and report mid-way.** Each lookup has a budget (default 10 minutes); past it, stop and report. Report at
    least once mid-rung so the operator can recalibrate.

13. **Fill expertise gaps with skills.** Before rung 1, list the available skills (`~/.agents/skills`) that help this
    kind of question (e.g. `lean-startup`, `grill-me`, `recon`, `research`, `judge`, `decay`) and the gaps none fills;
    adapt old methods to today (cheap building changes which Lean Startup lessons apply; its discipline still does).

14. **Pre-preflight with exemplars.** When the category is unfamiliar, read three or four named examples first and
    compare them in prose; the features and families to evaluate come out of that, not out of a guess.

15. **Cite and date everything.** Every claim carries its URL or `repo@commit:path:line` and the date read; fast-moving
    fields go stale in weeks.

16. **Record, then decide.** Findings go in a report file; a decision goes in an ADR; follow-ups become tasks. Commit
    only the files you wrote, never with `-a`: other work may be in progress.
</lessons_learned>

<workflow>

## Phase 0 — Question card (interactive; nothing is searched yet)

<HARD-GATE>
Do not search, fetch, clone, count or read anything about the topic until the operator has approved the question card.
The only reading allowed before then is the repository's own context (its docs, the operator's prior research notes)
and the list of available skills. This applies to every question, however simple it looks: unexamined questions are
where research is wasted.
</HARD-GATE>

### The interview

Refine the card with an interview, run like `/brainstorming`'s clarifying questions:

- **One question per message.** Never batch questions.
- **Multiple choice through the agent's question tool** (`AskUserQuestion` in Claude Code), 2–4 options, the
  recommended one first and labelled "(Recommended)"; the operator can always answer in their own words. Use
  multi-select only where the answers combine (purpose, scope).
- **Options are concrete and derived from the topic** — real numbers for a bar, real platforms for a scope — never
  generic placeholders. Give each option a one-line consequence ("needs public exposure", "can rule out but not
  confirm").
- **Skip a question the arguments already answer**; restate the answer in the next message instead.
- **When an answer pushes back** (rejects the framing, questions a method, adds a hidden purpose), address it first —
  agree, disagree with reasons, or reframe — and only then ask the next question. Pushback usually carries the most
  important information in the interview.
- **Reflect each answer back in one line** before the next question, so drift is caught early.

Ask in this order, stopping early when the card is complete:

| # | Field     | Question to ask                                                    | Typical options (adapt to the topic)                                                    |
| - | --------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| 1 | Purpose   | What decision will the answer feed, and for whom?                  | a personal tool · a product · a portfolio piece · a team or architecture decision · learning |
| 2 | Bar       | What result, by when, would make the answer "yes"?                 | three or four bars of rising ambition, each with a number and a deadline               |
| 3 | Scope     | Which markets, platforms, segments or stacks count?                | the realistic set for the topic; "all of them" as one option                            |
| 4 | Givens    | What do you already have or know that bears on it?                 | prior work · tools in daily use · private code · earlier research · nothing            |
| 5 | Depth     | How far should this pass go before reporting?                      | rung 1 only (5 min) · up to rung 2 (≈ 25 min) · up to rung 3 (≈ 1 day)                  |

Then **propose, do not ask**:

- the question restated in one line;
- its split into sub-questions (lesson 3);
- the skills that help and the gaps none fills (lesson 13);
- rung 1's kill signal.

Show the full card and ask for approval with three options: approve · change a field · restate the question. Only an
approval passes the gate.

### The card

| Field      | Example                                                                 |
| ---------- | ----------------------------------------------------------------------- |
| Question   | Is a Rust/GPUI launcher worth building?                                 |
| Purpose    | A product; also a portfolio piece                                       |
| Audience   | Who uses the answer, and what decision it feeds                         |
| Bar        | 2–3k engaged users and maintenance-level revenue within 12 months       |
| Scope      | Platforms, segments, what is out                                        |
| Givens     | What the operator already knows or owns (their own tools, prior work)   |

Fill the card from the interview's answers; a field the operator left open reads "open" and is asked again before
the approval question.

## Phase 1 — Rung 1 (≈ 5 minutes): ceiling and crowd

- State the kill signal first, e.g. "no comparable product reaches the bar" or "the space is saturated with stalled
  entries".
- Gather only counts from APIs (lesson 7). Script the queries; keep raw data in the scratchpad.
- Write the rung into the report: data tables, what it shows, the gate (fires? sound?), the refined signal.
- **Gate:** show the operator the data and the gate, and ask whether the bar is already answered. Stop if yes.

## Phase 2 — Rung 2 (≈ 20 minutes): wedge, reach, payment or adoption

- Typical signals: (a) no reason to switch or no unowned wedge; (b) launches of comparable things go unnoticed;
  (c) no comparable thing reaches the bar's money or users. Pick those that fit the question.
- Sample where users talk (HN, Reddit, issue trackers, store reviews) with counts by theme; read reviewers' reasons
  for refusals; read funding pages.
- Report mid-way, then the gate as in rung 1.

## Phase 3 — Rung 3 (≈ 1 day, only if asked): depth

- Candidates' code read from shallow clones (never built or run unless the operator asks); the graveyard (why
  comparable efforts died); cost of ownership; growth curves.
- Fan out one agent per candidate with a verbatim prompt; an independent auditor (`judge`, or a fresh agent without
  your reasoning) checks the list and the verdict.
- Gate as before.

## Phase 4 — Verdict and moves

- Verdict per sub-question and overall, against the bar: holds / refuted / refined, and what would change it.
- Next best moves, ranked, with "stop" as an option. Offer an ADR when a decision was made, and tasks for
  follow-ups.

</workflow>

<output>

One report per question, in the repository's research folder (ask where; default
`docs/research/YYYY-MM-DD-<slug>.md`), shaped as:

```markdown
# <Question>

- Date: <yyyy-mm-dd>
- Question / Purpose / Audience / Bar / Scope (the card)
- Method: the ladder of disproof passes, each closed by a gate that re-evaluates its own kill signal

# Rung 1 (5 minutes): <angle>

## Data
<tables of counts, each source and the date read>

## What it shows
<numbered findings, each tied to a row of data>

## Gate
| Signal | Fires? | Sound? |

<refined signal for the next rung>

# Rung 2 …

# Verdict
<per sub-question; overall against the bar; what would change it>

## Angles set aside
<build / fork / port / reuse / extend / upstream / nothing — and why>

## Searched
<every source and query, so the pass can be repeated or extended>
```

Reply to the operator, after each rung, in this order: the verdict so far in one sentence; the data that matters;
the gate; the decision you need from them.
</output>

<human_review_needed>
Stop and ask the operator at each of these points:

- [ ] The question card (Phase 0) before any search.
- [ ] Each rung's gate: continue, recalibrate, or stop.
- [ ] Any lookup past its time box.
- [ ] Any finding that contradicts an earlier decision or a project rule (flag it; do not act on it).
- [ ] Installing a skill, cloning private code, or contacting anyone (never without consent).
</human_review_needed>

<examples>

`/scout Is kb a tool worth building? purpose: adoption and portfolio; bar: 2-3k engaged users in 12 months`

1. Card: confirm platforms (macOS, Linux, Windows), that the storage format is not a defining trait, the decision fed
   (keep investing in kb).
2. Rung 1: GitHub stars and Homebrew installs of comparable tools (tldr, navi, cheat, pet, massCode, Atuin); new
   entrants in a year. Kill signal: "no comparable tool reaches the bar". Gate: does not fire; the second signal ("free
   incumbents already do the core") is under-defined — refine to "do users ask for what kb adds?".
3. The operator says the bar is answered: stop, write the verdict, offer the next question.

`/scout Build kb from its own code, fork, or port?`

1. Card: purpose adds "portfolio" (authorship matters); premise check: kb is not at scratch.
2. Rung 1: licences, sizes, stacks and jobs of fork candidates (same stack), port candidates (other stacks), and
   reusable data or content. Gate per option. Verdict: keep building; reuse others' data for adoption; ADR offered.
</examples>

<checklist>
Before calling the answer done:

- [ ] Nothing about the topic was searched before the card was approved (the hard gate).
- [ ] The interview asked one question per message, with concrete options and a recommendation, and answered each
      pushback before moving on.
- [ ] The card has a numeric bar with a deadline, approved by the operator.
- [ ] Every kill signal was written before its rung and gated for soundness after it.
- [ ] Every claim is cited and dated; every proxy's bias is stated.
- [ ] Supply and demand were both considered; the operator's own evidence was used.
- [ ] Angles set aside are named with reasons.
- [ ] The report file exists and is committed alone; decisions have an ADR or a task.
</checklist>
