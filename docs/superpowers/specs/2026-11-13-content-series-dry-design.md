# Content series: DRY the structure — design

Follow-up to [the content series design](2026-11-13-content-series-design.md), after the preflight setup proved the
structure. Asked by the author: fnox for secrets, mise arguments over environment variables, chronological post
folders, and one place for every post's metadata (`docs/posts/TODO.yaml`).

## Decisions

1. **Secrets through fnox.** A committed `fnox.toml` at the repo root holds references only:
   `[providers.gopass] type = "gopass"` and `DEVTO_TOKEN = { provider = "gopass", value = "tokens/dev.to" }`.
   The tasks read `DEVTO_TOKEN` from the environment (CI: the repo secret) or else run `fnox get DEVTO_TOKEN`. No
   task calls gopass directly.
2. **Arguments, not environment variables.** Every task parses its argv with `node:util`'s `parseArgs` (mise passes
   the arguments it validated through `#USAGE` to the script). The `usage_*` variables are not read; CI runs the
   same command line (`bun mise-tasks/posts/push.ts <post> --ref main`). The only environment variables left are
   the token and `CI`.
3. **Chronological folders.** `docs/posts/articles/<YYYY-MM-DD>-<slug>/`, the date being the planned publish date,
   fixed once published (renaming a published post's folder moves its image URLs). ISO dates sort, read without
   ambiguity and match the spec and plan file names. The folder name is the post's id everywhere (tasks, CI,
   metadata). Series-wide files (PLAYBOOK, STYLE, TODO.yaml, prompts, templates, tools) stay in `docs/posts/`.
4. **Metadata in `TODO.yaml`, through the todo CLI's own model.** The CLI drops unknown fields when it rewrites the
   file (verified), so the metadata uses what it keeps:
   - one **post task** per post, tagged `post`, with `position` = the post's folder (`docs/posts/articles/<dir>`);
     its status, due date (publish date) and tags are the post's;
   - **comments** on that task, one fact each, `key: value` with a small schema (below), added with
     `todo add --comment` (by the tasks or by hand) and never edited;
   - a **series task** (tag `series`) holds account-wide numbers (repo traffic) and the baseline.
5. **What goes away:** `stats.csv` and `LOG.md` (their content becomes comments), the `id:` front matter line (the
   dev.to id becomes a `devto.id` comment), and the workflow's id write-back commit (CI never writes the repo).
   **What stays a file:** the post itself, `linkedin.md`, `community.md`, `review.md` and images. They are
   artifacts found by convention in the post's folder, so references to them would only repeat the folder.
6. **Reports are generated.** `posts:report` prints each post's metadata (what LOG.md held) and rewrites the index
   table in `docs/posts/README.md` between `<!-- index:start -->` and `<!-- index:end -->`.

## Comment schema

| Key | Value | Written by |
| --- | --- | --- |
| `devto.id` | the article id | `posts:push` (when it creates one), `posts:stats` (when it finds one by title) |
| `devto.url`, `linkedin.url`, `community.url` | a URL | `posts:push` / the author |
| `stats` | `<YYYY-MM-DD> <platform> <metric>=<n> [<metric>=<n>…] (<api\|manual>)` | `posts:stats`, `posts:record` |
| `gate` | `<YYYY-MM-DD> <PASS\|BLOCKED> steps=<n>/12` | the gate run |
| `vars` | `hook=… cover=… images=… linkedin=… lang=… day=… tags=…` | the author / the gate |
| `log.keep`, `log.change`, `log.best-comment` | text | the author at 7 days |
| `pick` | `<YYYY-MM-DD> keep\|swap <reason> <source>` | the next-pick run, after the author decides |
| `decision` | `<YYYY-MM-DD> <text>` | recalibrations (series or recal tasks) |

Platforms and metrics are the ones the first design lists. A line that doesn't match the schema is reported by
`posts:report`, never dropped.

## Approaches considered

- **A sidecar `posts.yaml` with our own schema.** Free-form and typed, but a second file next to the roadmap, which
  is what the author asked to avoid.
- **Custom fields inside `TODO.yaml`.** Rejected: the todo CLI deletes them on its next write.
- **Comments on post tasks (chosen).** One file, preserved by the CLI, append-only like a log; the schema keeps it
  parseable. Cost: many small comments per post, and `TODO.yaml` becomes a shared file, so parallel branches can
  conflict on it (resolved by keeping both sides: comments are independent lines).

## Constraints kept from the first design

Publishing only from main and only by merge; a pull request never touches a live article; the tooling never
unpublishes; every tool from the Brewfile where possible (fnox already is).
