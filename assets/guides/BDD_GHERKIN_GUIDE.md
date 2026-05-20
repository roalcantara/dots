<!-- markdownlint-disable-file -->

# Dots BDD and Gherkin guide

Dots uses Gherkin to describe user-visible behavior as executable examples.
This guide is reusable across Dots specs. The examples use `config/bin` because
the bins pilot is the first living documentation suite.

Use this guide while writing `.feature` files and matching Screenplay step
definitions under `assets/features/<domain>`.

## Writing checklist

Before committing a `.feature` file, verify every item in this checklist.

- The file has one `Feature`.
- The `Feature` names a user-visible capability, not an implementation unit.
- Each `Rule` groups scenarios around one command behavior.
- Each `Scenario` describes one behavior.
- Each scenario uses third person and present tense.
- Each scenario has one main `When`.
- Most scenarios have three to five steps.
- Every command, flag, subcommand, output value, and file path is real or comes
  from an explicit fixture.
- The scenario avoids terminal focus, key navigation, ANSI rendering, fzf
  scrolling, and other interactive mechanics in the first read-only slice.
- The scenario can be implemented through Screenplay actors, command
  interactions, and result questions.

## Feature template

Start new feature files from this structure.

```gherkin
Feature: <user-visible capability>
  <one sentence explaining why this command behavior matters>

  Rule: <one command behavior>

    Scenario: <specific observable example>
      Given <short fixture or command context>
      When Alice runs `<real command>`
      Then Alice sees the command succeed
      And Alice sees "<real output>" in the output
```

Use `Alice` as the default terminal user unless a scenario needs another named
actor.

## Step vocabulary

Use a small, reusable vocabulary. Prefer these shapes before adding new step
phrases.

| Gherkin step | Screenplay mapping |
| --- | --- |
| `Given the fixture bin directory contains executable xc tools` | Fixture precondition checked by the step definition. |
| `Given fixture Fabric patterns exist` | Fixture precondition checked by the step definition. |
| `When Alice runs \`xc list\`` | Actor performs a command interaction. |
| `When Alice runs \`xc-fabric ls --raw\`` | Actor performs a command interaction with fixture environment. |
| `Then Alice sees the command succeed` | Actor asks for the last command exit code. |
| `Then Alice sees "summarize" in the output` | Actor asks for the last command stdout. |

Add a new phrase only when the existing vocabulary cannot express the behavior
clearly.

## Rule examples

Use `Rule` when a feature has more than one command behavior.

```gherkin
Feature: Discover xc commands
  The xc launcher helps terminal users discover available Dots commands.

  Rule: The launcher lists available tools

    Scenario: User lists tools from the fixture bin directory
      Given the fixture bin directory contains executable xc tools
      When Alice runs `xc list`
      Then Alice sees the command succeed
      And Alice sees "xc-sample" in the output

  Rule: The launcher exposes help

    Scenario: User reads launcher help
      Given the xc launcher is available
      When Alice runs `xc -h`
      Then Alice sees the command succeed
      And Alice sees "list" in the output
```

## Background examples

Use `Background` only when every scenario in the feature needs the same context.
Do not use it to hide important command actions.

### ✅ Prefer: shared fixture context only

```gherkin
Feature: List Fabric patterns

  Background:
    Given fixture Fabric patterns exist

  Rule: Pattern listing is available as a read-only command

    Scenario: User lists fixture Fabric patterns as raw output
      When Alice runs `xc-fabric ls --raw`
      Then Alice sees the command succeed
      And Alice sees "summarize" in the output
```

### ❌ Avoid: hidden command action in `Background`

```gherkin
Background:
  Given Alice already ran `xc-fabric ls --raw`
```

The avoided example hides the behavior under test. Put command execution in the
scenario `When` step.

## Data table examples

Use data tables when one scenario needs to verify a small list of expected
values. Keep table rows real and fixture-backed.

```gherkin
Scenario: User lists fixture Fabric patterns
  Given fixture Fabric patterns exist
  When Alice runs `xc-fabric ls --raw`
  Then Alice sees the command succeed
  And Alice sees these patterns in the output:
    | pattern         |
    | summarize       |
    | youtube_summary |
```

Avoid tables for large command inventories in the first slice. Prefer a few
stable examples that prove the behavior.

## Bad to better

Use this section when translating rough notes into executable Gherkin.

### ❌ Avoid: vague scenario with no observable contract

```gherkin
Scenario: User can see all stuff
  Given there are many commands
  When the user opens the terminal app
  Then everything looks right
```

### ✅ Prefer: concrete command and observable output

```gherkin
Scenario: User lists tools from the fixture bin directory
  Given the fixture bin directory contains executable xc tools
  When Alice runs `xc list`
  Then Alice sees the command succeed
  And Alice sees "xc-sample" in the output
```

### ❌ Avoid: implementation-focused scenario

```gherkin
Scenario: Fabric list works
  Given the shell function parses the options
  When the script loops over pattern folders
  Then the formatter prints rows
```

### ✅ Prefer: user-visible command behavior

```gherkin
Scenario: User lists fixture Fabric patterns as raw output
  Given fixture Fabric patterns exist
  When Alice runs `xc-fabric ls --raw`
  Then Alice sees the command succeed
  And Alice sees "summarize" in the output
  And Alice sees "youtube_summary" in the output
```

## Screenplay mapping

Keep Cucumber steps thin. The step definition translates Gherkin, then
Screenplay support code performs command work and asks questions.

| Gherkin concept | Screenplay concept | Bins example |
| --- | --- | --- |
| Named user | Actor | `Alice` |
| Command action | Interaction or task | Run `zsh config/bin/xc list` with fixture `PATH`. |
| Command result | Remembered actor state | Last command exit code, stdout, and stderr. |
| Assertion target | Question | Ask for stdout and compare it with expected text. |

Do not put process-spawning details in every step definition. Put that behavior
under `assets/features/support/`.

## First slice example boundaries

The bins pilot's first executable slice is intentionally small. Later specs can
define their own boundaries in `assets/specs/<feature-slug>/design.md`.

- Include command discovery with `xc list`.
- Include launcher help with `xc -h`.
- Include Fabric listing with `xc-fabric ls --raw`.
- Exclude interactive fzf navigation.
- Exclude terminal focus assumptions.
- Exclude root `install`, Neovim, Lua, and zsh configuration specs.

After this slice is green, later specs can add interactive picker behavior,
larger command inventories, and richer reporting.
