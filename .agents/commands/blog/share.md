---
description: Get a published post's LinkedIn post and first comment ready to paste; with URLs, record them and close the post
argument-hint: Optional post folder, linkedin=<url>, community=<url>, then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:stats:*), Bash(mise run blog:done:*), Bash(pbcopy)
---

<task>
Help the author share a published post: the LinkedIn text ready to paste, the first comment with the dev.to link,
and, once the author gives the URLs, record them. Arguments: $ARGUMENTS
</task>

<context>
- Where things stand: !`mise run -q blog:status $1`
- LinkedIn rules: @docs/blog/STYLE.md (Voice → LinkedIn)
</context>

<workflow>
1. Name the post (argument, else the latest post that isn't closed). Its stage must be `share` or `measure`. If the
   status says the dev.to URL is missing, run `mise run blog:stats` first.
2. Read `docs/blog/posts/<post>/linkedin.md`. Replace `{devto.url}` with the post's `devto.url` (from
   `mise run -q blog:report`). Print **the post** and **the first comment** as two separate blocks, and copy the
   post to the clipboard with `pbcopy`.
3. Remind the author: post it, then add the first comment right away, and stay an hour or two for replies; the
   community post (if any) goes out a few days later.
4. If `linkedin=` (and `community=`) URLs were given, run
   `mise run blog:done <post> --linkedin <url> [--community <url>]`; it records them, runs the stats, marks the
   task done and commits locally. Tell the author to push.
5. Never post anywhere yourself.
</workflow>

<checklist>
- [ ] `{devto.url}` replaced; post copied to the clipboard.
- [ ] URLs recorded only when given; committed locally, not pushed.
</checklist>
