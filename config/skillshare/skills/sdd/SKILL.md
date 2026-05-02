---
name: sdd
description: >
  Produces exactly three files under docs/specs/<feature-slug>/:
  requirements.md (behavior and acceptance, EARS), design.md (normative
  technical contract: single source of truth for APIs, JSON payloads, HTTP
  status codes, and operational policies), tasks.md (ordered work and
  verification). MUST match the repository canonical example layout when
  docs/example/{requirements,design,tasks}.md exist—same section order and
  heading levels; do not invent top-level sections, rename stable headings,
  or rely on custom HTML id anchors for cross-links. Design states concrete
  values only: forbid "pick one", "either A or B", "before verification",
  and placeholder tables (e.g. "_e.g. 200_"). Cross-links use real Markdown
  headings so URL fragments match editor and GitHub slug rules. Use when the
  user asks for SDD, spec, PRD, Kiro-style feature specs, or separate
  requirements / design / tasks documents. Supports Requirements-First and
  Design-First workflows.
compatibility: Designed for Cursor Agent and similar agentic coding tools.
metadata:
  author: roalcantara
  version: "1.1"
---

# Kiro-style Feature Spec Generator

Generate a complete three-file spec for the described feature, replicating
Kiro's spec workflow. Read [references/EARS.md](references/EARS.md) before
writing any requirement. Read [references/FORMATS.md](references/FORMATS.md)
before creating any file.

## Non-negotiables (layout, roles, links)

1. **Layout source of truth**
   - If the workspace contains **`docs/example/requirements.md`**, **`docs/example/design.md`**, and **`docs/example/tasks.md`**, treat them as the **canonical skeleton**: **same top-level sections**, **same heading levels** (`#`, `##`, `###`, `####`), and **same patterns** (tables vs lists) as in those files. Fill content for `<feature-slug>`; **do not** substitute a different outline (for example the shorter template in FORMATS alone).
   - If those files are **missing**, use [references/FORMATS.md](references/FORMATS.md) templates only.

2. **Separation of concerns**
   - **`requirements.md`**: *What* must hold and *how we know* (EARS acceptance criteria). **Reference** the design for specifics (`design.md#heading-slug`). **Do not** duplicate long normative tables (status codes, route matrices, JSON schemas) if they already live in `design.md`.
   - **`design.md`**: *How* in **closed**, **verifiable** detail—routes, methods, request/response bodies, HTTP status integers, error shapes, queues, retries, DLQ, etc. This file is the **single source of truth** for those facts.
   - **`tasks.md`**: *Order of work* plus verification steps that **point to** requirement ids **and** design headings; **do not** restate full contracts inline.

3. **Anchors and cross-links**
   - Define link targets with **real Markdown headings** (`#### 8.1 Routes table`, etc.). **Do not** depend on `<a id="...">`** for Cursor/VS Code preview.
   - When linking from requirements or tasks to design, use fragments that match **GitHub-style slugs** from those headings (verify the heading text produces a stable slug).

4. **Forbidden in normative design prose** (anything a verifier would need as a single expected value)
   - Phrases like: "pick one", "the design chooses later", "before verification fill in", "either X or Y" for the same case, "for example" / `_e.g._` **in place of** a committed value in a canonical table.
   - If the human has not decided a value, **ask** before writing the design section—**do not** leave open options in the shipped doc.

---

## Step 0 — Workflow Selection

Ask the user:

> "Which workflow do you want to use?
> - **Requirements-First** — you know the desired behavior; architecture
>   will adapt to meet it.
> - **Design-First (High Level)** — you have a system architecture in mind;
>   requirements will be derived from it.
> - **Design-First (Low Level)** — you have pseudocode, interfaces, or
>   algorithms in mind; requirements will be derived from them."

Wait for explicit selection before proceeding.

Derive `<feature-slug>` from the feature name (lowercase, hyphens only).
All files go to `docs/specs/<feature-slug>/`.

---

## Workflow A — Requirements-First

**Flow:** Requirements → Design → Tasks

### Phase 1 — Requirements

1. Ask clarifying questions if the feature description is ambiguous:
   - Who are the users / roles involved?
   - What are the main success scenarios?
   - What are the key failure / edge cases?
   - Are there non-functional constraints?

2. Generate `docs/specs/<feature-slug>/requirements.md` following
   [references/FORMATS.md](references/FORMATS.md#requirementsmd) **and**, when
   present, the **section order and headings** of `docs/example/requirements.md`.

3. Requirements rules:
   - Write every acceptance criterion in EARS format (see [references/EARS.md](references/EARS.md))
   - Use `WHEN … THE SYSTEM SHALL …` as the primary pattern
   - Number each criterion within its story (1.1, 1.2, 2.1, …)
   - Cover happy path, edge cases, and error handling

4. **STOP. Show the file and ask:**
   > "Here is `requirements.md`. Does this capture everything correctly?
   > Let me know what to change before I move on to the design."

   Wait for explicit approval ("looks good", "approved", "proceed", etc.)
   before continuing.

### Phase 2 — Design

1. Generate `docs/specs/<feature-slug>/design.md` following
   [references/FORMATS.md](references/FORMATS.md#designmd) **and**, when
   present, the **section order and headings** of `docs/example/design.md`.

2. Every architectural decision must trace back to at least one requirement
   number from `requirements.md`.

3. **Normative contract**: Any API, payload, status code, or policy a tester
   could assert MUST appear **once**, **concretely**, in this file (see
   **Non-negotiables**). No placeholder rows or deferred choices.

4. Include a Mermaid sequence diagram for the main flow (unless the canonical
   example omits it for this feature type—then match the example).

5. **STOP. Show the file and ask:**
   > "Here is `design.md`. Does the architecture look right?
   > Any changes before I generate the tasks?"

   Wait for explicit approval before continuing.

### Phase 3 — Tasks

1. Generate `docs/specs/<feature-slug>/tasks.md` following
   [references/FORMATS.md](references/FORMATS.md#tasksmd) **and**, when
   present, the **section order and headings** of `docs/example/tasks.md`.

2. Tasks rules:
   - Each task must reference the requirement number(s) it satisfies
   - Order by dependency (no task should depend on an unresolved one above it)
   - Include setup, implementation, and validation tasks
   - Verification bullets should cite **`design.md#heading-slug`** (and
     `requirements.md` ids) instead of re-embedding full status or JSON specs

3. **STOP. Show the file and ask:**
   > "Here is `tasks.md`. Ready to start implementing, or do you want to
   > adjust anything?"

---

## Workflow B — Design-First

**Flow:** Design → Requirements → Tasks

### Phase 1 — Design

1. Ask clarifying questions if needed:
   - What are the technical constraints or required stack?
   - Any non-functional requirements (latency, throughput, compliance)?
   - Are there existing diagrams or architecture docs to incorporate?
   - High Level (components, interactions) or Low Level (pseudocode,
     interfaces)?

2. Generate `docs/specs/<feature-slug>/design.md` following
   [references/FORMATS.md](references/FORMATS.md#designmd) and, when present,
   **`docs/example/design.md`** layout. Apply **Non-negotiables**: the design
   must already contain **committed** technical values (no "TBD" tables).

3. Include all constraints and non-functional requirements explicitly.

4. **STOP. Show the file and ask:**
   > "Here is `design.md`. Does the architecture match your intent?
   > Iterate here before I derive the requirements from it."

   Wait for explicit approval before continuing.

### Phase 2 — Requirements

1. Derive requirements from the confirmed design.

2. Generate `docs/specs/<feature-slug>/requirements.md` following
   [references/FORMATS.md](references/FORMATS.md#requirementsmd) and, when
   present, **`docs/example/requirements.md`** layout.

3. Requirements must be feasible given the confirmed architecture — do not
   add behaviors the design cannot support.

4. Write every acceptance criterion in EARS format (see [references/EARS.md](references/EARS.md)).

5. **STOP. Show the file and ask:**
   > "Here is `requirements.md` derived from your design. Does this reflect
   > all the behaviors you expect? Any gaps before I generate the tasks?"

   Wait for explicit approval before continuing.

### Phase 3 — Tasks

Same as Workflow A, Phase 3.

---

## General Rules

- Never skip a phase or proceed without explicit user approval.
- Never generate all three files at once.
- If the user asks to change something after approval, update the file,
  show the diff, and re-confirm before continuing.
- Prefer short, unambiguous task descriptions over long prose.
- All Mermaid diagrams must be valid and renderable.
- **Layout**: Do not "improve" or reorganize the canonical example structure
  unless the user explicitly asks; consistency across features matters more than
  an agent's preferred outline.
- **Design first for forks**: If requirements mention "per design §…" or link
  to a subsection, that subsection MUST exist and MUST contain one clear value
  per decision.
