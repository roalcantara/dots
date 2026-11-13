---
description: Draft a blog post (dev.to post, LinkedIn post, community post, shot list) from its roadmap topic
argument-hint: Optional post folder (YYYY-MM-DD-slug), note="…" (angle, story, constraints), then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:check:*), Bash(mise run blog:cover:*), Bash(mise run -q blog:todo:*), Bash(git log:*), Bash(git show:*)
---

<task>
Write the first draft of one post of the dots blog, in its folder, ready for the gate. Arguments: $ARGUMENTS
</task>

<context>
- Rules and the topic table (hook, RECIPE, sources): @docs/blog/PLAYBOOK.md
- Voice, look and rubric: @docs/blog/STYLE.md
- Templates: @docs/blog/templates/post.md @docs/blog/templates/linkedin.md @docs/blog/templates/community.md
- Where things stand: !`mise run -q blog:status $1`
</context>

<workflow>
1. Name the post (argument, else the current `feat/post-*` branch). Its folder must exist (`mise run blog:new`
   first); find its topic row in PLAYBOOK.md ("Topics") and its task in `mise run -q blog:todo -- list`.
2. Read every source the topic row names, and the commits behind them (`git log`), until each claim in the draft is
   backed by the repo. Write the information-gain sentence first; if it can't be written, stop and say so.
3. Draft `post.md` with the `technical-article-writer` skill (objective: personal branding / authority; audience:
   peer developers; 800–1,300 words), in the template's structure and STYLE.md's voice. Ten title options; keep the
   most specific. Tags: the large ones first.
4. Draft `linkedin.md` with the `linkedin-ghostwriting` skill (hook ≤ 210 characters, 900–1,300 characters, the
   recipe in 3 bullets, one honest lesson, a question; the first comment keeps `{devto.url}`).
5. From topic 2, draft `community.md` with the `reddit-posts` skill for the community the topic table names.
6. **Never invent a story, number or quote.** Where only the author knows (how they noticed, what it cost, a real
   anecdote), write `<author: what is needed>`; `blog:check` **blocks** on these, and `blog:publish` refuses until
   they are gone.
7. Add a shot list (2–4 images) as a comment at the end of `post.md`, and propose the cover command:
   `mise run blog:cover <post> --title … --highlight … --subtitle … --keys …`.
8. Run `mise run blog:check <post>` until it has no blocks. Do not commit; end with: "Next: /blog:gate".
</workflow>

<checklist>
- [ ] Every claim backed by the repo; no invented stories.
- [ ] `post.md`, `linkedin.md` (and `community.md` from topic 2) drafted; `<author: …>` where needed.
- [ ] `blog:check` has no blocks.
- [ ] Nothing committed, pushed or published.
</checklist>
