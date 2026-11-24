---
description: Take a product design from a stated goal to a settled, buildable spec — hard requirements first, a stress story every option plays, a living mock on the real medium, rulers that place every element, one decision at a time with the operator, then an independent audit and specs generated from the mock
argument-hint: The product or surface, then optional goal=<the one real goal>, must=<hard requirements>, not=<non-goals>, mock=<existing mock or design-system link> (e.g. "toma's inline prompt goal=beautiful, intuitive, fast must=zsh,Ghostty not=tmux,NO_COLOR")
---

<task>
Lead a product design pass with the operator, from goal to a spec someone else can build. The deliverables are a
living mock that plays every moment of the product on its real medium, a design document generated from that mock, a
behaviour spec that agrees with it, and a list of decisions with what was set aside. Ideas come from `/wip:diverge`;
this command shapes, converges, specifies and audits.
</task>

<context>
Why this shape (lessons from a long terminal-UI design pass that went from 11 concepts to one settled design):

- **Only the goal is a hard limit.** Briefs mix real requirements with preferences. Every rule but the goal and the
  stated hard requirements is negotiable, and the operator decides which. Unstated requirements cost the most:
  designing fallbacks for terminals, shells or modes that were never goals wasted whole rounds.
- **The sample data decides what gets designed.** A round of eleven concepts failed because the brief's example
  request was short: nobody designed for long or multi-line text, risky output, errors or stale results. A stress
  story with the worst cases fixed that.
- **The operator judges by eye.** Drawn, animated frames on the real grid, with captions in the operator's notation,
  settled in minutes what paragraphs could not. Their own screenshots with a line drawn on them (a misaligned edge)
  were the most precise feedback of the whole pass.
- **A mock lies in specific ways.** It showed stripes between filled rows, clipped descenders, shifted a picture by a
  font's `ch`, dropped leading spaces, word-wrapped what the shell wraps mid-word, and left shell syntax
  uncoloured. Each looked like a design flaw and was a mock bug.
- **Alignment needs rulers, not taste.** Naming nine rulers (five columns tied to the window's width, four rows that
  follow the content) turned "it looks odd" into "this ends on column 81, the clock starts on 82", and every later
  addition found its place on an existing ruler.
- **Redundancy is noise.** Each fact said once, in one fixed home: an outcome shown in two places, a key named by a
  pill and a key row, a reason in a segment and a record. Removing the repeats was always the better version.
- **Facts beat assumptions.** Checking the real machine (terminal key bindings, OS shortcuts, the shell's own key
  map, its highlighter's hooks, the prompt's transient mode) reversed several decisions; an external dependency's
  spike (a CLI's licence gate, its schema option, its real output quality) changed the plan before it was built.
- **A fresh reviewer finds what the author cannot.** An independent audit with only the docs found two documents that
  each said the other one wins, a safety rule the design contradicted, and content taller than the window.

Arguments: $ARGUMENTS

- First free text: the product or surface. Everything else is optional:
- `goal=`: the one real goal, in plain words.
- `must=`: hard requirements (platforms, tools, safety, legal). Each one removes work: never design around them.
- `not=`: non-goals, stated so nobody designs fallbacks for them.
- `mock=`: an existing mock, prototype or design-system link to build on.
</context>

<workflow>

0. **Frame, one question at a time.** Restate the product in two lines and play back the goal, the users, the hard
   requirements and the non-goals. Ask for whatever is missing, one question per message, with the question tool
   where available. Ask explicitly: "Which environments are required, and which are not goals?" Write the answer at
   the top of every later document.
1. **The stress story.** Write one fixed story of numbered moments that every option must play: the happy path, then
   the worst cases of the real data: long input, multi-line input and output, an error, a retry, a stale result, a
   risky result, leaving midway, the window too small, a dependency missing. Caption each moment in the operator's
   own notation (state, key, result). Add a moment whenever a feature arrives (a backend, a toast); never replace
   the story with a friendlier one.
2. **Inventory the canvas and the host.** The real grid (columns, rows, cell size), what the host already draws and
   owns (a prompt's top row, a clock, a status segment, scrollback), what it can carry beyond the surface (title,
   cursor, progress bar, notifications, images), and the user's actual setup. Check each claim on the real machine
   (config dumps, key-binding lists, `--help`, man pages) before relying on it.
3. **Ideas.** Run `/wip:diverge` for the open questions. Keep its rule: no scoring before the operator has reacted.
4. **A living mock.** Build one player that renders every option through every moment on the real grid, in the
   operator's theme (a design-system or artifact page when available). Give it a moment strip, a step control, the key
   pressed, the caption and a note per moment. Fidelity checks before showing anything:
   - a filled cell paints its whole row height (no stripes between rows, no clipped descenders);
   - positions use the medium's own unit (`ch` of the mono font, never of a decorative font);
   - text keeps its leading spaces; the host's own wrapping (a shell wraps mid-word at the edge) is drawn as the host
     does it, and the host's own colouring (syntax highlighting) is shown, not left plain;
   - every frame renders without errors; screenshots can lag the last click, so confirm state from the DOM.
5. **Rulers and lanes, as soon as one option leads.** Name every column and row ruler and what sits on it; tie columns
   to the width (`W − 11`, not `79`). Use what the host already draws as rulers (the prompt's clock column became a
   status column). Group columns into lanes (a gutter for marks, an input lane, an alley, an aside) and give every
   element exactly one. Add a toggle that draws the numbered rulers over every frame, and a script that checks every
   frame: lanes respected, the aside never wider than its column, nothing past the edge. Define the narrow window, the
   minimum width and a collapse order for content taller than the window.
6. **Converge, one decision per turn.** For each open question: say the problem in one line, show the options drawn
   (a switch in the player beats a paragraph), give a recommendation with its trade-off, and act on the answer. When
   the operator shares a draft, treat it as the spec and fill only what it leaves open. When they reverse a decision,
   follow it and remove what it made obsolete. Once settled, delete the switches and the unused options from the mock,
   and record them in one "considered and set aside" line.
7. **Interaction rules worth settling explicitly** (each one cost a round when left implicit):
   - **State words** that say what the main key does now, so most keys can stay hidden;
   - **Fresh or stale**: what makes a result acceptable, and never accepting a stale one;
   - **Toasts or errors**: a toast informs and goes; an error stops the work and stays until handled;
   - **Two key families**: the host's editing keys keep their meaning; the product's commands use one distinct chord
     family; check every key against the terminal, the OS and the shell on the real machine;
   - **Discoverability**: hidden keys get a visible handle (a pill that names the toggle, a glyph beside the action);
   - **Durable or ephemeral**: what lasts (a record) and what goes (a segment until the next command), each said once;
   - **Judgment boundary**: the product marks only what it produced; once handed over, it is the user's, in the
     host's own styling;
   - **Colour**: tokens by role with computed contrast for every new value (a dimmed variant mixed over the
     background), never colour alone (a word or glyph too), and a fill reserved for "lit" or "chosen" states.
8. **Spike the dependencies and the risky integrations** before the spec: an external tool's real output, quality,
   speed, gates and options; the host hooks the hand-off relies on. Record findings in an ADR.
9. **Independent audit.** Dispatch a fresh agent with only the docs and the mock: audit against the goal, the hard
   requirements, consistency, completeness (states the spec asks for that no frame shows), the platform's best
   practices (keys, contrast computed from the hex values, lifecycle and restore, sanitising untrusted output) and
   build feasibility; findings ranked, each with `file:line` and a fix. Verify the top findings yourself, then take
   the blockers to the operator one by one; apply the rest as proposals they approve.
10. **Write the spec from the mock.** Generate the design document's frames from the mock's renderer (never redraw by
    hand), with the rulers, keys, copy, styles, build notes and the decisions list. State which document wins where
    they differ. Bring the behaviour spec, the vocabulary file and the agent instructions in line. Put follow-ups in the
    project's backlog. Commit only the named files, on a branch that passes the repository's naming rule; never skip a
    hook without the operator's word.
11. **Hand off** with `/wip:handoff`, and offer a ready-to-run prompt for the implementation planner: goals, settled
    decisions, files, build risks, open questions and the first step.

</workflow>

<style>
- Short messages, one question at a time, lead with what changed. Recommend; do not survey options you would not pick.
- Use the operator's vocabulary and notation; define a new term once and add it to the vocabulary file.
- When asked "does this make sense?", answer yes or no first, then the one consequence that matters.
- Say plainly when a mock artefact, not the design, caused what the operator saw.
- Report what was checked and how (in the browser, as text, by a script); never claim a visual check you did not do.
</style>

<operator_signals>
- A screenshot with a line or a box drawn on it: a precise alignment or spacing defect. Name the rulers involved.
- "Too subtle", "too much", "does not quite work": the treatment, not the idea. Offer the next stronger or weaker step.
- "Is it really necessary?": a redundancy. Find where else the fact is said and keep one.
- "I tricked you" or a reversal: they are testing the rule. Restate the rule they mean and apply it everywhere.
- "This settles it": stop proposing, close the loose ends, and offer the audit.
</operator_signals>

<red_flags>

| Thought | Reality |
| --- | --- |
| "The brief's example is enough data" | Short, happy data designs a product that breaks on real input. |
| "I'll design a fallback in case" | Ask whether that environment is a goal first. |
| "It looks misaligned, I'll nudge it" | Name the ruler it should sit on. |
| "Say it here too, to be safe" | Each fact once, in one home. |
| "The mock shows a gap, the design is wrong" | Check the mock's fidelity first. |
| "I'll describe the options" | Put a switch in the player and let them look. |
| "That key is free" | Check the terminal, the OS and the shell bindings on the real machine. |
| "I'll redraw the frames in the doc" | Generate them from the renderer, or they drift. |
| "The audit is optional, I wrote it carefully" | The author cannot see their own contradictions. |

</red_flags>

<checklist>
- [ ] Goal, hard requirements and non-goals written first; nothing designed for a non-goal.
- [ ] A stress story with the worst cases, played by every option, extended as features arrive.
- [ ] Canvas, host and setup facts checked on the real machine.
- [ ] A living mock on the real grid; fidelity checks passed; every frame renders.
- [ ] Rulers and lanes named, relative to width, drawable, and checked by a script; narrow and overflow defined.
- [ ] One decision per turn; switches removed and alternatives recorded once settled.
- [ ] States, fresh/stale, toasts/errors, key families, durable/ephemeral, judgment and colour rules settled.
- [ ] Dependencies spiked and recorded in an ADR.
- [ ] Independent audit run; blockers decided by the operator; fixes applied.
- [ ] Design document generated from the mock; specs, vocabulary and instructions aligned; precedence stated.
- [ ] Follow-ups in the backlog; named files committed; handoff and planner prompt written.
</checklist>
