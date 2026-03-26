---
name: sdd
description: >
  Generates structured feature specs (requirements.md, design.md, tasks.md)
  using EARS notation, replicating Kiro's spec workflow inside Cursor.
  Use when the user asks to create a spec, PRD, feature spec, SDD,
  requirements document, design doc, or implementation plan for a new
  feature or system. Supports Requirements-First and Design-First workflows.
compatibility: Designed for Cursor Agent and similar agentic coding tools.
metadata:
  author: roalcantara
  version: "1.0"
---

# Kiro-style Feature Spec Generator

Generate a complete three-file spec for the described feature, replicating
Kiro's spec workflow. Read [references/EARS.md](references/EARS.md) before
writing any requirement. Read [references/FORMATS.md](references/FORMATS.md)
before creating any file.

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

2. Generate `docs/specs/<feature-slug>/requirements.md` following the format
   in [references/FORMATS.md](references/FORMATS.md#requirementsmd).

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

1. Generate `docs/specs/<feature-slug>/design.md` following the format
   in [references/FORMATS.md](references/FORMATS.md#designmd).

2. Every architectural decision must trace back to at least one requirement
   number from `requirements.md`.

3. Include a Mermaid sequence diagram for the main flow.

4. **STOP. Show the file and ask:**
   > "Here is `design.md`. Does the architecture look right?
   > Any changes before I generate the tasks?"

   Wait for explicit approval before continuing.

### Phase 3 — Tasks

1. Generate `docs/specs/<feature-slug>/tasks.md` following the format
   in [references/FORMATS.md](references/FORMATS.md#tasksmd).

2. Tasks rules:
   - Each task must reference the requirement number(s) it satisfies
   - Order by dependency (no task should depend on an unresolved one above it)
   - Include setup, implementation, and validation tasks

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

2. Generate `docs/specs/<feature-slug>/design.md` following the format
   in [references/FORMATS.md](references/FORMATS.md#designmd).

3. Include all constraints and non-functional requirements explicitly.

4. **STOP. Show the file and ask:**
   > "Here is `design.md`. Does the architecture match your intent?
   > Iterate here before I derive the requirements from it."

   Wait for explicit approval before continuing.

### Phase 2 — Requirements

1. Derive requirements from the confirmed design.

2. Generate `docs/specs/<feature-slug>/requirements.md` following the format
   in [references/FORMATS.md](references/FORMATS.md#requirementsmd).

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
