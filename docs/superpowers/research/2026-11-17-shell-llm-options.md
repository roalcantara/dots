# LLM on the zsh command line — research

Options for Warp's best AI trick in our own shell: describe a command in plain English, get it on the line, edit it,
press Enter. Measured against today's zsh + zim + fzf-tab + Lig + p10k + Ghostty setup
([`2026-11-17-shell-ux-options.md`](2026-11-17-shell-ux-options.md)). Stars and last push are from the GitHub API on
2026-11-17.

**Status:** spike in progress (TODO `Zid2`), outside the repo in `~/.cache/dots/llm-spike`.

## Criteria

- **Inline:** the answer lands in the zsh buffer for editing, never runs by itself.
- **macOS and Linux**, installed from the Brewfile.
- **No process at startup** (the anti-goal of the theme and Lig designs): a widget or hook, no daemon per shell.
- **Repository owns the config:** no installer that appends to `.zshrc`; keys come from `config/.env` (SOPS).
- **No key clash:** Ctrl-L is `scroll-and-clear-screen`, Ctrl-R fzf history, Up history-substring-search, Tab Lig.
- **Any provider**, Anthropic included; a local model is a plus.

## Recommendation

1. **Spike [zsh-ai](https://github.com/matheusml/zsh-ai).** Type `# find files over 100mb changed this week`, press
   Enter, and the command replaces the line. Pure zsh plus `curl` and `perl`, so nothing starts with the shell.
   Providers: Anthropic (default model `claude-haiku-4-5`), OpenAI, Gemini, Mistral, Grok, Qwen, Ollama, and
   [Apfel](https://apfel.franzai.com) (Apple's on-device model, no key; this Mac qualifies: arm64,
   macOS 27). Configured by `ZSH_AI_*` variables, so it fits `config/zsh/opt/plugins/`. The spike must check:
   - the `# ` hook on `accept-line` under Lig's PTY and next to `zsh-history-filter` (does the request reach history?);
   - what leaves the machine: it sends the directory path, nearby file names, git branch/status and OS;
   - Apfel needs `brew services start apfel`, a background server: acceptable, or Anthropic only?
2. **Fallback: [aichat](https://github.com/sigoden/aichat).** In Homebrew core, 20+ providers, a 10-line zsh widget
   on Alt-E (`aichat -e "$BUFFER"`) we would own. Also a chat REPL. Its last release (v0.30.0) is from 2025-07.
3. **Skip the rest** (table).

## Spike plan

The owner holds several quotas: a Gemini API key (daily), DeepSeek (`DEEPSEEK_API_KEY`), Copilot and Codex
(monthly), Claude (kept for planning and review) and local MLX models. zsh-ai talks to one provider, so routing goes
behind its `custom` provider (`_zsh_ai_query_custom`: request in `$1`, the command alone on stdout, nonzero on
failure). Two backends compete:

| | A: omp | B: own chain |
| --- | --- | --- |
| Call | `omp -p --model @smol` with tools, skills, rules, context files, extensions, LSP and session off, and zsh-ai's system prompt | zsh-ai's own providers in turn: Gemini, DeepSeek (OpenAI-compatible URL), local MLX |
| Routing | omp's `retry.fallbackChains` / `usageAwareFallback` for the `smol` role | ~20 lines of zsh |
| Reaches | Every quota omp lists: google, deepseek, opencode-zen, github-copilot, openai-codex, apple (on-device) | Only providers with an API key |
| Risk | An agent harness's start-up and prompt tokens on every request | Duplicates routing omp already has |

Decided by: Enter-to-command latency (target under ~2 s), fallback on a usage limit, whether omp's role and chain
config can live in the repository, and the zsh-ai checks above (Lig, history filter, context sent).

## Options

| Option | Verdict | Inline | Stars | Last push | Notes |
| --- | --- | --- | --- | --- | --- |
| [zsh-ai](https://github.com/matheusml/zsh-ai) | Try | `# ` + Enter | 229 | 2026-09-30 | zsh + curl; Anthropic, Ollama, Apfel; brew tap `matheusml/zsh-ai` |
| [aichat](https://github.com/sigoden/aichat) | Fallback | Alt-E | 10.6k | 2026-02-23 | Rust binary, brew core; release cadence slowing |
| [shell_gpt](https://github.com/TheR1D/shell_gpt) | Skip | Ctrl-L | 12.3k | 2026-07-02 | pip; `--install-integration` edits `.zshrc`; Ctrl-L clash; Anthropic via LiteLLM |
| [zsh-copilot](https://github.com/Myzel394/zsh-copilot) | Skip | Ctrl-Z | 178 | 2026-01-22 | Ctrl-Z clashes with suspend; OpenAI or Anthropic only |
| [llm](https://github.com/simonw/llm) + [llm-cmd](https://github.com/simonw/llm-cmd) | Skip | No | 12.8k / 480 | 2026-11-17 / 2025-05-30 | A command, not a widget; the plugin is stale |
| [ai-shell](https://github.com/BuilderIO/ai-shell) | Skip | No | 5.3k | 2026-01-05 | Node CLI with its own prompt |
| [butterfish](https://github.com/bakks/butterfish) | Skip | Wraps shell | 551 | 2026-06-03 | Another PTY wrapper beside Lig |
| [zsh_codex](https://github.com/tom-doerr/zsh_codex) | Skip | Yes | 1.7k | 2025-03-22 | Python, stale |
| [Atuin AI](https://github.com/atuinsh/atuin) | Skip | `?` | 32.5k | 2026-11-17 | Needs atuin's history DB, skipped on 2026-11-17 |
| [Fabric](https://github.com/danielmiessler/Fabric) | Keep | No | 44.7k | 2026-11-15 | Already in the Brewfile; prompt patterns over pipes, not a line editor |
| [Copilot CLI](https://github.com/github/copilot-cli) | Keep | No | 11.4k | 2026-11-17 | Already in the Brewfile; an agent, not a line editor |
| [mods](https://github.com/charmbracelet/mods), [gh-copilot](https://github.com/github/gh-copilot) | Skip | — | 4.5k / 1.2k | — | Archived |
