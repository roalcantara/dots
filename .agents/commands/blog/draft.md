---
description: Draft a blog post (hook options to pick, dev.to post, LinkedIn post, community post, cover) from its roadmap topic
argument-hint: Optional post folder (YYYY-MM-DD-slug), note="…" (angle, story, constraints), then free notes
allowed-tools: AskUserQuestion, Bash(mise run -q blog:report:*), Bash(mise run -q blog:status:*), Bash(mise run blog:new:*), Bash(mise run blog:check:*), Bash(mise run blog:cover:*), Bash(mise run -q blog:todo:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat log:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat show:*)
---

<task>
Write the first draft of one post of the dots blog, in its folder, ready for the gate. Arguments: $ARGUMENTS
</task>

<context>
- Rules: @docs/blog/PLAYBOOK.md; the topic's own data (`hook:`, `recipe:`, `sources:`) are comments on its task
- Voice, look and rubric: @docs/blog/STYLE.md
- Templates: @docs/blog/templates/post.md @docs/blog/templates/linkedin.md @docs/blog/templates/community.md
- Where things stand: !`mise run -q blog:status $1`
</context>

<workflow>
1. Name the post (argument, else the current `feat/post-*` branch). Its folder must exist (`mise run blog:new`
   first). Find its task and read the topic's `hook:`, `recipe:` and `sources:` comments (`mise run -q blog:report`,
   `mise run -q blog:todo -- list`).
2. Read every source, and the commits behind them (`git log`, `git show`), until each claim in the draft is **lived
   or proven** (STYLE.md). Write the information-gain sentence first; if it can't be written, stop and say so.
3. **Hook options.** From that evidence, propose **3–5 hooks** of different kinds: a relatable pain, a small
   confession, a surprising number from the repo, and one or two framed by a geeky wink from the author's
   interests (STYLE.md, "The hook"). For each, name the repo fact it rests on and what the author must confirm
   ("did you notice it in a real run?"). Ask the author (AskUserQuestion) to pick one, edit it, or write their own.
   - Picked or edited: it opens OVERVIEW in the author's words; a shortened form opens the LinkedIn post.
   - Skipped: keep `<author: the moment — how you noticed, what it cost>` and write the options right below it as
     `<!-- hook options: 1. … 2. … -->`, so a later session picks up from them.
   No option goes into the post without the author's pick.
4. Draft `post.md` with the `technical-article-writer` skill (objective: personal branding / authority; audience:
   peer developers; 800–1,300 words), in the template's structure and STYLE.md's voice: each fact once, nothing the
   author hasn't lived or the repo doesn't show. Ten title options; keep the most specific. Tags: large ones first.
5. Draft `linkedin.md`: the hook (≤ 210 characters), **one sentence with the insight**, "→ the first comment";
   250–450 characters, no bullet list, 1–3 hashtags; the first comment is `{devto.url}`.
6. From topic 2, draft `community.md` with the `reddit-posts` skill for the community its task names.
7. Write `cover.json` (from `docs/blog/templates/cover.json`): two title lines, the highlight, a subtitle with one
   emoji wink, and the window (`terminal` with the post's real moment in 3–5 lines, or `app` with code and/or
   skeleton bars). Run `mise run blog:cover <post>` and look at the image. List any screenshots worth taking (2–4).
8. Run `mise run blog:check <post>` until it has no blocks (markers block until the author replaces them). Do not
   commit; end with: "Next: /blog:gate" (or "replace the <author: …> markers first").
</workflow>

<checklist>
- [ ] Hook options proposed; only the author's pick (or a marker) is in the post.
- [ ] Every claim lived or proven; each fact once.
- [ ] `post.md`, `linkedin.md` (and `community.md` from topic 2), `cover.json` and the cover done.
- [ ] Nothing committed, pushed or published.
</checklist>
