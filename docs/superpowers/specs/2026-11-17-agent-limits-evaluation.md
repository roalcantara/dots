# Agent limits on macOS — evaluation

Hands-on comparison for [the design](2026-11-17-agent-limits-design.md). One candidate installed at a time.

## References

Read in the same minute as each candidate:

| Agent | Reference |
| --- | --- |
| Claude | `claude -p /usage`: session (5h), week (all models), week (Fable). The VS Code panel lagged it by 8 points, so it is not used |
| Codex | `omp usage`: 30-day window (free plan) |
| Copilot | `omp usage`: monthly premium requests |
| Gemini | `agy -p /usage`: Gemini 5h and weekly, Claude-and-GPT 5h and weekly, per-model weekly (Google AI Pro) |
| Tokens and cost | `npx ccusage@latest daily`, `weekly`, `monthly` (Claude Code); `npx @ccusage/codex@latest daily` (Codex) |

## Cut on paper

Rule: no release in the last 6 months, paid with no trial, or missing two or more of the four agents.

| Candidate | Source | Reason |
| --- | --- | --- |
| Usage4Claude | [f-is-h/Usage4Claude](https://github.com/f-is-h/Usage4Claude) | Claude and Codex only: misses Copilot and Gemini |
| Claude Usage Tracker | [hamed-elfayome/Claude-Usage-Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker) | Claude, optional Codex: misses Copilot and Gemini |
| TokenBar | dev.to comparison | Paid ($5/month or $15), closed; built on CodexBar, which is tested |
| Fetchy | [App Store](https://apps.apple.com/app/id6786673900) | Closed, in-app purchase; no Copilot |
| LLM Usage Widget | [flukelaster/LLM-Usage-Widget](https://github.com/flukelaster/LLM-Usage-Widget) | No license, 4 stars, no Gemini; covered by stronger candidates |
| AI Usage | [codiak/ai-usage-menubar](https://github.com/codiak/ai-usage-menubar) | No releases; Claude, Codex, Copilot only |

## Shortlist

| Candidate | Install | Last release | License | Known agents | Widgets | Tokens/cost |
| --- | --- | --- | --- | --- | --- | --- |
| [CodexBar](https://github.com/steipete/CodexBar) | `brew install --cask codexbar` | v0.84.0, 2026-11-07 | MIT | all four | WidgetKit | yes |
| [ClaudeBar](https://github.com/tddworks/ClaudeBar) | `brew install --cask claudebar` | v0.5.27, 2026-11-13 | Apache-2.0 | all four | no (notch, Touch Bar) | unknown |
| [AgentLimits](https://github.com/Nihondo/AgentLimits) | zip release | v1.3.2, 2026-10-31 | MIT | Claude, Codex, Copilot; Antigravity only via a custom script | Notification Center | ccusage |
| [QuotaBar](https://github.com/QuotaBar/QuotaBar) | `gentpan/tap/quotabar` cask | v0.6.1, 2026-10-30 | MIT | all four (Gemini through Antigravity) | desktop cards | estimated from logs |
| [OpenUsage](https://github.com/robinebers/openusage) | `brew install --cask openusage` | v0.8.0, 2026-11-12 | MIT | all four (Gemini through Antigravity) | no | partial |

## Scored

Agent cells: `pass` / `wrong: <what>` / `missing`, with the tool's reading against the reference's.

| Candidate | Version | Claude | Codex | Copilot | Gemini | Fable | Tokens/cost | Menu bar | Widgets | Credentials read | Prompts | Install | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CodexBar | 0.84.0 | pass: 41/24 = `/usage` 41/24 | pass: 30-day 34% = `omp` 34%, drawn as one window | pass: 0.3% = `omp` 21/7K | pass: Claude/GPT 28.6% used, Gemini 1.4% = `agy` 71%/99% left | pass: 0% | pass: Claude 30-day $309.38 / 909M vs ccusage $311.57 / 984M (window differs by 2 days); daily chart, per model | pass | WidgetKit (bundled) | Claude Code Keychain item (OAuth) or runs `claude /usage`; Codex CLI login; GitHub device flow; Antigravity sign-in | one Keychain "Always Allow" for Claude; skips browser-cookie prompts in background | cask, Notarized Developer ID, CLI linked as `codexbar` | pending: expired-login check, 30-minute watch, widget |
