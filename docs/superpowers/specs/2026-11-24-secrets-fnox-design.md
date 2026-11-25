# Secrets from gopass through fnox, not `config/.env`

Date: 2026-11-24 · Branch: `feat/secrets-fnox` · Size: a small change (short design)

## Intent

Stop keeping secrets in a SOPS-encrypted `config/.env` that every shell sources. gopass becomes the only place the
values live; fnox, already installed (`config/homebrew/Brewfile:75`) and already used by the blog tasks
(`fnox.toml`), loads the three keys still in use into every zsh session. The change ships as a `feat` so it cuts the
first real release under ADR 0001 and exercises the whole flow (tag, GitHub Release, `publish.yml`).

## Today

- `config/mise/conf.d/dotfiles.toml:9` links `~/.config/.env` → `config/.env` (SOPS-encrypted in git, plain on disk).
- `config/zsh/opt/rc.d/sys.zsh` `sys::dotenv` sources it (`set -a`) when `sops` and `age` exist; `.zshrc:30` loads
  `sys.zsh`, and `sys.zsh:97` calls `sys::dotenv`.
- It holds 13 secrets and 16 `GUM_LOG_*` styling variables (not secrets).
- Consumers in the repo: Neovim's LLM providers (`config/nvim/lua/core/opt/llm/providers/{openai,anthropic}/api.lua`)
  read `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` from the environment; nothing in the repo reads `DEEPSEEK_API_KEY` or
  `WAKATIME_API_KEY`: the wakatime CLI reads its key from `config/wakatime/.wakatime.cfg`
  (`WAKATIME_HOME`, `.zshenv:185`), so that variable is redundant.

## Goals

1. **Three keys from gopass, in every shell** (the author's list, less `WAKATIME_API_KEY`, which is redundant):

   | Variable | gopass entry |
   | --- | --- |
   | `OPENAI_API_KEY` | `tokens/openai.com` |
   | `ANTHROPIC_API_KEY` | `tokens/anthropic.com` |
   | `DEEPSEEK_API_KEY` | `tokens/DEEPSEEK_API_KEY` |

   A global fnox config, `config/fnox/config.toml`, linked as `~/.config/fnox` (one more row in `dotfiles.toml`),
   with the `gopass` provider and `line = 1` like the existing `DEVTO_TOKEN`.
2. **`fnox activate zsh` replaces `sys::dotenv`** in the zsh startup, guarded by `_has_command fnox`.
3. **`GUM_LOG_*` move to `config/zsh/opt/rc.d/env.zsh`**, same names and values, exported.
4. **Retire the rest:** delete `config/.env` and its link; the other secrets are not carried over.
5. **Keep `DEVTO_TOKEN` out of the shell:** the repo's `fnox.toml` would otherwise export it whenever a shell is inside
   dots; mark it so the hook skips it (`env = false`), while `fnox get DEVTO_TOKEN` keeps working for the blog tasks.
6. **Docs follow:** README (lines 140 and 221), AGENTS.md's hard rule that names `config/.env`, `.sops.yaml` and
   `.gitattributes` comments, `config/zsh/README.md`'s `sys.zsh` row, `.zshrc:30`'s comment.

## Non-goals

- Rotating the retired secrets (the author's call, outside the repo; see Anti-goals).
- Changing SOPS for the files that stay encrypted (`config/ssh/keys`, `config/gopass`, …).
- The fnox daemon: resolving four keys took 0.06–0.07 s and three prompt hooks 0.07 s in total (spike,
  2026-11-24), so no cache is needed.
- `config/wakatime/.wakatime.cfg` stays SOPS-encrypted; moving its key to gopass (wakatime's `api_key_vault_cmd`) is a
  later option.
- The kodexb cheat sheets that show `git show HEAD:config/.env` as an example command.

## Anti-goals

- A secret value in the repo, a commit message, a test fixture or a log line.
- A shell that errors or slows down where gopass or its store is missing (the Docker images, a fresh machine before
  the store is cloned): the hook must stay silent there.
- Losing a key a tool still needs without saying so: the retired list goes in the PR body.

## Approaches

| Approach | Trade-off | Verdict |
| --- | --- | --- |
| **Global fnox config + `fnox activate zsh`** | Same behaviour as today (keys in every shell), nothing secret in git; one prompt hook | **Picked by the author** |
| `fnox export` once at shell start (`sys.zsh`) | Simpler, but every new shell pays the gopass reads, and leaving dots wouldn't unload repo secrets | Rejected |
| No shell env; wrap consumers (`fnox exec -- nvim`) | Fewest places a key lives; every consumer, including tools outside dots, needs a wrapper | Rejected |

Spike result (2026-11-24, fnox 1.50.0): a global config's secrets load in a directory with no project config; a
project `fnox.toml` adds to them.

## Release

The main commit is `feat(zsh): Load API keys from gopass with fnox` → semantic-release cuts 1.52.0 → a GitHub Release
→ `publish.yml` builds the images. The PR body lists the after-merge checks: the release run, the new Release and its
notes, the `publish.yml` run, and a PR comment from the success step.

## Verification

- `fnox check --all --non-interactive` with the global config resolves all three keys (no values printed).
- A new zsh has the three variables set and non-empty, and none of the retired names; `mise run zsh:verify` passes.
- With fnox's config pointing at an empty gopass store (or no gopass), a new zsh starts with no error output.
- `fnox env --json --describe` inside dots doesn't list `DEVTO_TOKEN`; `fnox get DEVTO_TOKEN` still resolves.
- `hk check --all` and `mise run test:specs` green; the Docker build and CST pass for one distro (bootstrap changed).

## Left to the builder

Where in `.zshrc` the hook goes (after mise's activation), the exact key that hides `DEVTO_TOKEN` (check
`fnox.toml`'s schema), how to keep the hook quiet when gopass is missing (`if_missing`, `FNOX_SHELL_OUTPUT`, or the
guard), and the wording of the docs.

## For the author, outside the repo

Revoke or rotate the retired tokens that still work (Bitwarden API credentials and password, FloxHub, LocalStack,
Gemini, the OpenAI project key): their encrypted copies stay in git history.
