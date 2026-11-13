# Recipes from dots

Short write-ups of how things are done in this repo: each post tells the story of a problem and ends in a
**RECIPE**, a TL;DR you can follow without reading the rest. They are published on
[dev.to](https://dev.to/roalcantara) and shared on LinkedIn; this folder is the original.

<!-- index:start -->
| Date | Post | What it is | dev.to | LinkedIn |
| --- | --- | --- | --- | --- |
| 2026-11-12 | [Omarchy-ish macOS: tiling, an fn layer and Raycast](posts/2026-11-12-omarchy-on-macos/post.md) | How I got most of Omarchy's keyboard-first desktop on a Mac, with yabai, Karabiner-Elements, SwiftBar and Raycast. | [dev.to](https://dev.to/roalcantara/omarchy-ish-macos-tiling-an-fn-layer-and-raycast-3fd8) | — |
| 2026-11-13 | [My AI agent's for-loop ran once: zsh doesn't split $vars](posts/2026-11-13-zsh-word-split/post.md) | Coding agents write bash, but on macOS they may run it in your zsh. One unquoted variable later, a loop runs once and nobody notices. | — | — |
<!-- index:end -->

The table is generated from `TODO.yaml` by `mise run blog:report --write`.

**How the series works:** [PLAYBOOK.md](PLAYBOOK.md) (goals, rules, decisions) · [STYLE.md](STYLE.md) (voice, look,
rubric) · [TODO.yaml](TODO.yaml) (the roadmap, and every post's links, numbers and lessons: `mise run blog:report`).

### QUICK REFERENCE

One command per step; `mise run blog:status` (or `/blog:next`) says where each post stands and which comes next.
`<post>` is the post's folder, `YYYY-MM-DD-slug`; inside its `feat/post-<slug>` branch it can be left out. Details:
[PLAYBOOK.md](PLAYBOOK.md), "How a post moves".

1. `/blog:pick [note=…]`: choose the next topic (schedule, news, comments); you decide keep or swap.
2. `mise run blog:new <slug> [--task <id>]`: branch `feat/post-<slug>`, copy the templates, point the task at the
   folder.
3. `/blog:draft [note=…]`: draft the post, the LinkedIn post and the community post; `<author: …>` marks what only
   you can write, and `blog:check` blocks until they are replaced.
4. `mise run blog:cover <post> --title … [--highlight …] [--subtitle …] --keys …`: the cover; captures go in
   `posts/<post>/raw/`, framed with `docs/blog/tools/frame.py`.
5. `mise run blog:check <post>`: until there are no blocks.
6. `/blog:gate`: a fresh agent reviews the post and records the verdict.
7. `/blog:pr`: commit, push the branch and open the PR (title and body written); check the dev.to draft preview.
8. `mise run blog:publish`: then **merge the PR** (that publishes it).
9. `/blog:share`: the LinkedIn post (copied) and the first comment, to post by hand; then
   `/blog:share linkedin=<url>` records it and closes the task.
10. `mise run blog:stats` at 48 hours; `/blog:retro` at 7 days (numbers and lessons).

Writes after the merge commit locally and stop: push them when ready. The token comes from
[`fnox.toml`](../../fnox.toml) (gopass `tokens/dev.to`); nothing else needs setting up.
