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

From a topic on the roadmap to its numbers a week later. `<post>` is the post's folder, `YYYY-MM-DD-slug`; `<id>` is
its task in `TODO.yaml`. The details are in [PLAYBOOK.md](PLAYBOOK.md), "How a post moves".

1. See what's next: `mise run blog:todo -- list` (or `mise run blog:todo -- dashboard`).
2. The Tuesday before, have an agent run [`prompts/next-pick.md`](prompts/next-pick.md); decide keep or swap and record
   it: `mise run blog:todo -- add --comment "pick: <date> keep <reason>" --task-id <id>`.
3. Branch `feat/post-<slug>`, copy [`templates/`](templates/) into `posts/<post>/`, and point the task at it:
   `mise run blog:todo -- update <id> --tag post,topic-<n> --position docs/blog/posts/<post>`.
4. Draft `post.md` (skill `technical-article-writer`), `linkedin.md` (`linkedin-ghostwriting`) and, from topic 2,
   `community.md` (`reddit-posts`).
5. Make the images, from the repo root: `uv run --with pillow docs/blog/tools/header.py
   docs/blog/posts/<post>/images/00-cover.png --title … --series <n> --keys …`; captures go in
   `docs/blog/posts/<post>/raw/`, framed (and blurred where sensitive) with `docs/blog/tools/frame.py`.
6. Check until there are no blocks: `mise run blog:check <post>`.
7. Have a fresh agent run [`prompts/gate.md`](prompts/gate.md) → `posts/<post>/review.md`; fix every **Must fix**,
   take the **Consider** items you agree with, and record `gate:` and `vars:` comments on the task.
8. Open a pull request: the `Blog` workflow creates the dev.to draft and comments its preview link; every push
   updates it.
9. Publish: set `published: true` in `post.md`, push, merge. The run on `main` publishes it with images from `main`.
10. Post on LinkedIn (`linkedin.md`), then the first comment with the dev.to link; stay for replies. Community post a
    few days later.
11. Record: `mise run blog:stats` (dev.to id and numbers), `linkedin.url:` and `community.url:` comments, the task
    done (`mise run blog:todo -- status <id> --set done`), and `mise run blog:report --write` for the index above.
12. At 48 hours and 7 days: `mise run blog:stats` and
    `mise run blog:record <post> linkedin impressions=… reactions=… comments=… reposts=…`; at 7 days, the
    `log.keep:`, `log.change:` and `log.best-comment:` comments.

The token comes from [`fnox.toml`](../../fnox.toml) (gopass `tokens/dev.to`); nothing else needs setting up.
