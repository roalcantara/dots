# Architecture decision records

An ADR keeps the reasoning behind a decision: the context that forced it, the choice made, the alternatives that
lost, and what follows. Code shows what was built; an ADR says why, so the next person or agent does not reopen a
settled question or reverse a trade-off by accident.

## When to write one

Write an ADR when a choice is expensive to reverse (a release process, a data model, an authentication scheme, a tool
that owns a workflow), or when people keep asking the same question about why something is the way it is. The
`documentation-and-adrs` skill lists more triggers. Do not write one for a change anyone can undo in a single commit.

## Format

Files live in `docs/adr/`, numbered from `0001`, named `NNNN-<slug>.md` (`0001-releases.md`). A record has this shape:

```markdown
# NNNN. <Title>

- Status: <proposed|accepted|superseded by NNNN|deprecated>
- Date: YYYY-MM-DD

## Context

What forced a decision: the evidence, the constraints, what fails today.

## Decision

The choice, in the present tense, and why the alternatives lost.

## Consequences

What the choice buys, what it costs, and what a reader needs to know to live with it.
```

## Statuses

- `proposed`: written but not agreed yet; a merged ADR is usually `accepted`.
- `accepted`: in force.
- `superseded by NNNN`: replaced by a later ADR.
- `deprecated`: no longer true, and nothing replaced it.

## Changing a decision

Write a new ADR. Its context says what changed; the old one's status becomes `superseded by NNNN`. Never edit the
decision of a superseded ADR and never delete one: the trail from a wrong decision to the right one is the point.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-releases.md) | GitHub Releases as the changelog | accepted |

Keep this table in step with the files: a new ADR adds its row, and a superseded ADR's status changes here too.
