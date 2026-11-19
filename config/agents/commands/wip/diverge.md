---
description: Generate many genuinely new ideas for a design or problem before judging any — start from what the medium can do, keep rules out until later, tag rule breaks instead of filtering, show ideas instead of describing them, converge only after the operator reacts
argument-hint: The problem, then optional goal=<the one real goal>, not=<known or rejected ideas>, seeds=<wild examples>, n=<ideas per situation> (e.g. "how toma shows errors goal=simple and beautiful not=footer chip,rule seeds=toasts,fades n=5")
---

<task>
Run a divergent ideation pass with the operator on any problem: UI, product, architecture, naming, process, writing.
Produce **many different ideas, unranked and unfiltered**, shown in the most concrete form available, then narrow them
down **with** the operator, only after they have reacted. The deliverable is a set of ideas the operator could not have
listed alone, not one recommendation.
</task>

<context>
Why this shape (lesson from a 5-hour session that kept producing the same four ideas re-arranged):

- **Constraints leak in before ideas.** Reading specs, briefs and plans first makes every idea obey their rules,
  even rules the operator considers negotiable.
- **Scoring kills strange ideas.** A scorecard with criteria such as "extra rows" or "does anything move" silently
  turns rules into penalties; the unusual ideas get ranked out before anyone sees them.
- **Asking "where" or "which" returns only places and options.** Searching how other tools do it returns precedent,
  so research done before ideation narrows the space instead of widening it.
- **What unlocked it:** a goal stated once, a list of what the medium can do, a quota, rejected ideas named, wild
  seeds, every rule tagged instead of applied, and every idea drawn (animated where it moves).

Arguments: $ARGUMENTS

- First free text: the problem. Everything else is optional:
- `goal=`: the one real goal. Every other rule is a means to it and is negotiable.
- `not=`: known or rejected ideas, comma-separated. Never present these as new.
- `seeds=`: wild examples to stretch toward. Even one widens the range.
- `n=`: ideas per situation (default 5; at least 20 in total).
</context>

<workflow>

0. **Frame, in one short message.** Restate the problem in two lines, the goal, the **situations** to cover (the
   distinct cases the design must handle) and what is settled and must not be reopened. If the goal or the
   situations are missing, ask for them: **one question at a time, with the question tool** where available. If the
   operator has not said **why** they want this, ask that first, openly, with nothing to pick from. Play back what
   you understood in a few lines and invite corrections. Do not start ideating on a guessed goal.
1. **Quarantine the rules.** Do not read specs, briefs, plans, design docs or prior findings for this problem until
   the operator has seen the ideas. Read only what states the problem and the hard limits: safety, legal or
   correctness rules that are truly non-negotiable. List those hard limits in one line each; every other rule is
   breakable.
2. **Inventory the medium (no ideas yet).** List everything that could carry a solution, beyond the obvious surface:
   - the surface itself (cells, pixels, words, sections, files) and everything it can do over **time** (motion,
     fading, timing, order);
   - the layers around it (host app, terminal, OS, browser, shell, editor, network, the people involved);
   - the content's own producer (a model, a user, a process): changing what it produces can remove the problem;
   - **moments**: before, during, at the decisive action, after, on demand;
   - styles and signals: shape, colour, typography, sound, motion, position, absence.
   Find and load the skills relevant to the topic (design, the framework, the platform) and mine them for
   **capabilities** only; their rules and anti-patterns are quarantined like specs until step 6 (a skill rule such
   as "a toast cannot be the only record" is a default, not a ban). Check every claimed capability against docs or
   code; never call anything impossible without saying exactly why.
3. **Diverge.** For each situation, at least `n` ideas, drawn from different capabilities. Include **avoidance**
   ideas (make the problem not occur) and **combinations** (a message that fades into a sign). For each idea:
   a name, one line, and **"breaks: <rule>"** for every rule it breaks. Keep every idea. Do not repeat anything from
   `not=` unless as a part of a new idea, and say so.
3b. **Optional structured research, after the first ideas.** When the space is wide, fan out parallel research
   agents (one per source, on the cheapest model tier that can browse and read images; spot-check their claims).
   Ask for **mechanisms** ("what does each tool use to signal X, over time, outside its main surface, or by
   avoiding X"), never for **placements** or a ranking; give them no scorecard. Merge only new ideas into step 3.
4. **Show, don't tell.** Draw every idea in the most concrete medium available: a visual companion or artifact page
   for anything visual, **animated** when the idea moves; a text sketch in a terminal; a short example or scenario
   for behaviour (step by step, in the operator's own notation when they have one). Offer the visual companion the
   first time seeing would help, as its own short message. When feel matters (motion, timing, interaction), offer a
   throwaway spike. Group by situation. Let the operator mark the ideas worth keeping.
5. **Wait for the reaction.** No scores, no ranking and no recommendation before the operator has reacted. If they
   say "none are new", go back to step 2 and widen the inventory; never re-arrange the same ideas.
6. **Converge with them.** Only on the kept ideas: compare against the goal in plain words, then propose one
   consistent family (the same idea serving every situation where possible). Bring in the quarantined rules now,
   and say which kept ideas they would block and whether that block still serves the goal.
7. **Record.** Write the ideas (kept and dropped, each with its rule tags) and the converged proposal to one file in
   the project's scratch or design area, and print its path. Design approval and implementation follow the
   project's usual flow (e.g. the brainstorming skill's approaches and design doc, which this command precedes), not
   this command.

</workflow>

<style>
- Short messages. One question at a time. Lead with what changed.
- Use the project's own vocabulary; define any new term once; verify code or product facts before stating them.
- Never present a known idea as new. Never say "impossible" or "not allowed" for a rule that is only a default.
- Explain behaviour with a step-by-step example and point at the exact step that matters; when the operator writes
  their own model (pseudocode, a state machine, Gherkin), answer in it.
- Check a claim such as "the simplest choice is X" or "the code does Y" before making it; correct yourself plainly
  when the operator shows it wrong.
</style>

<operator_signals>
- "Am I asking the wrong questions?" or "only these options?": the framing is too narrow. Go back to step 2.
- "None are new" or "these are the same": positions changed, capabilities did not. Widen the inventory.
- An example the operator shares ("the least bad one I've seen") is a data point, not an anchor: diverge away from
  it too.
- A misunderstanding that repeats: a word means two things. Name both meanings and ask which one.
- The operator may not be a specialist in the field or writing in their first language: read for intent, never
  correct their wording, use plain words.
- Long sessions tire people: after about an hour, or on signs of fatigue, offer to stop and write a handoff that
  lets a fresh session continue without the back-and-forth.
</operator_signals>

<red_flags>

| Thought | Reality |
| --- | --- |
| "Let me read the spec first for context" | That is how the rules got in. Read it at step 6. |
| "I'll rank these so the operator can choose" | Ranking before reacting kills the strange ideas. |
| "This breaks the brief, so I'll drop it" | Tag it. The operator decides what is negotiable. |
| "Let me survey how other tools do it" | Precedent narrows. Use it after step 3, to add to it. |
| "Three solid options are enough" | Below the quota, only the obvious ideas appear. |
| "I'll describe it clearly in words" | The operator judges by eye. Draw it. |
| "These are new" (they are re-arrangements) | Change the capability, not the position. |

</red_flags>

<checklist>
- [ ] Goal, situations and hard limits stated before any idea; nothing settled reopened.
- [ ] No spec, brief or prior finding read before the operator reacted.
- [ ] Medium inventory written and its claims checked.
- [ ] At least `n` ideas per situation, from different capabilities, with avoidance and combinations.
- [ ] Every rule break tagged; no idea filtered; nothing from `not=` sold as new.
- [ ] Every idea shown concretely, animated where it moves.
- [ ] No ranking before the reaction; convergence done with the operator, rules brought back only then.
- [ ] Ideas and proposal recorded to one file; path printed.
</checklist>
