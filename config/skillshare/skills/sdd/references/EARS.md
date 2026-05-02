# EARS Quick Reference

EARS (Easy Approach to Requirements Syntax) constrains natural language
requirements into deterministic, testable patterns.

---

## Kiro's Primary Pattern

Kiro uses a simplified two-clause form for most product requirements:

```
WHEN <condition or triggering event>
THE SYSTEM SHALL <expected behavior>
```

Use this as your default for all acceptance criteria.

---

## Full EARS Patterns

Use these when the simplified form loses important nuance.

### Ubiquitous — always active, no condition

```
THE SYSTEM SHALL <response>
```

Example:
```
THE SYSTEM SHALL respond to all API requests within 500ms under normal load.
```

### State-driven — active while a condition holds

```
WHILE <precondition>
THE SYSTEM SHALL <response>
```

Example:
```
WHILE the user session is expired
THE SYSTEM SHALL redirect all requests to /login.
```

### Event-driven — triggered by an event (Kiro's default)

```
WHEN <trigger>
THE SYSTEM SHALL <response>
```

Example:
```
WHEN a user submits the checkout form
THE SYSTEM SHALL validate all required fields before processing payment.
```

### Unwanted behaviour — error and edge case handling

```
IF <undesired trigger>
THEN THE SYSTEM SHALL <response>
```

Example:
```
IF the payment gateway returns a timeout error
THEN THE SYSTEM SHALL display "Payment could not be processed. Please try again."
```

### Complex — precondition + trigger combined

```
WHILE <precondition>
WHEN <trigger>
THE SYSTEM SHALL <response>
```

Example:
```
WHILE the cart contains at least one item
WHEN the user clicks "Checkout"
THE SYSTEM SHALL present the order summary screen.
```

---

## Rules

1. Clause order is always: WHILE → WHEN/IF → SHALL. Never reorder.
2. Each requirement has exactly one system name and one or more system responses.
3. Split compound behaviors: avoid "and" to chain unrelated responses.
4. Avoid "not" as the primary verb — use the Unwanted Behaviour pattern instead.
5. Avoid vague terms: "appropriate", "user-friendly", "as needed", "quickly".
6. Every criterion must be independently testable.

---

## Choosing the Right Pattern

| Situation | Pattern |
|---|---|
| Default product behavior | Event-driven (`WHEN … SHALL`) |
| Always-on constraint | Ubiquitous (`SHALL`) |
| Mode or session state | State-driven (`WHILE … SHALL`) |
| Error / failure case | Unwanted behaviour (`IF … THEN SHALL`) |
| State + event combined | Complex (`WHILE … WHEN … SHALL`) |
