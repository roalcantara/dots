# Root TODO.yaml for the dots repo — design

Small change. Branch: `chore/add-todos`.

## Intent

Organise and record the next tasks to run on this repo itself, the way `docs/blog/TODO.yaml` does for the blog,
with the same `todo` CLI (RayanBO/todo). The CLI comes from the Brewfile, so every dependency is declared there.

## Goals

- A root `TODO.yaml` (`todo init --yaml`, project `dots`), driven by plain `todo` from the repo root. No wrapper:
  the root list has no custom schema (unlike the blog's), the Brewfile pins the tool, and `todo` reads only
  `./TODO.yaml`, so it is run from the root.
- `todo` installed by `config/homebrew/Brewfile` on the dev profile, pinned to v0.2.9, and found on `PATH`.
- `mise run blog:todo` keeps working, now with the Brewfile's binary.
- `/wip:resume` shows the root list (its probe already prefers a root `TODO.yaml`; no change).

## Non-goals

- No link between the root and blog lists; the blog stays as is.
- No `TODO.md` (markdownlint fights the CLI's output; `/wip:resume` would not see it).
- No `todo` on the desktop or container profiles (both would need a Rust toolchain to build it).
- No seed tasks beyond what verification adds and removes.

## Approaches

- **A. Root `TODO.yaml` (picked):** same tool and format as the blog, read by `/wip:resume` as is; noisier diffs.
- **B. Root `TODO.md`:** reads better, but two formats in one repo, a markdownlint exclusion or fix-up after every
  write, and a `/wip:resume` probe change.

## Decided

- Brewfile, DEVTOOLS, after `brew "rust"`:
  `cargo "todo-cli", source: "https://github.com/RayanBO/todo?tag=v0.2.9"`. The crates.io `todo` is an unrelated
  macro crate and crates.io `todo-cli` another project; brew bundle's `cargo` entry accepts a git source with a tag.
- Remove the misplaced `cargo "todo"` desktop entry, its section header and the two stray blank lines.
- Drop `#MISE tools={"github:RayanBO/todo"="0.2.9"}` (and its comment) from `.mise/tasks/blog/todo`, so the mise
  shim no longer shadows the Brewfile's binary.
- Keep blog and root separate.

## My calls (correct if wrong)

- Fix `config/zsh/opt/rc.d/env.zsh:137`: `${CARGO_HOME:-$XDG_DATA_HOME/cargo/bin}` adds `~/.local/share/cargo`, not
  its `bin`, because `.zshenv` always sets `CARGO_HOME`. Use `${CARGO_HOME:-$XDG_DATA_HOME/cargo}/bin`, appended
  after `$path` so rustup's proxies there never shadow the `cargo` already in use.
- Uninstall the mise-installed `github:RayanBO/todo` once the brew one works, so its shim goes away.
- A line for the root list in `AGENTS.md` (Layout or Workflow) and `README.md` day-to-day commands.
- A `brewfile-profiles` spec case: `todo-cli` on `desktop,dev` only.

## Verification

- `HOMEBREW_DOTS_PROFILE=desktop,dev brew bundle install --no-upgrade` builds it; `brew bundle check` passes.
- New zsh: `command -v todo` is `~/.local/share/cargo/bin/todo`; `todo --version` is 0.2.9; `cargo` resolves as before.
- `todo list` at the root and `mise run blog:todo -- list` both work; add and remove a task round-trips.
- The `/wip:resume` probe prints the root tasks.
- Gates: `mise run test:specs`, `hk check --all`, `mise run zsh:verify`.

## Left to the builder

The order of the steps, the wording of the doc lines, and the exact test assertion.
