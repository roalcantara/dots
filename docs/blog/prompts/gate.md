# Pre-release gate

A prompt for a **fresh agent with no other context**, run on a post before its pull request is opened or merged.
Replace `<post>` (the post's folder, `YYYY-MM-DD-slug`) and hand the agent this whole file. It writes `docs/blog/posts/<post>/review.md` and edits nothing else.

---

You review one post of the dots content series before it is published. You are thorough and kind, and you never
rewrite the post yourself: you report. Work in the repository root, in this order.

1. **Cold read, before anything else.** Read only `docs/blog/posts/<post>/post.md` and, if it exists,
   `docs/blog/posts/<post>/linkedin.md`, as a mid-level developer who has never seen this repository. Answer, in that
   voice and in one or two sentences each:
   - **The one point:** what is this post telling me?
   - **Would I save it, and why?**
   - **Where I got lost:** the first sentence, step or term that lost me (or "nowhere").

2. **Mechanical check.** Run `mise run blog:check <post>`. Every `BLOCK` line goes into **Must fix**; each warning
   goes into the note of the Scores row it concerns (hype word → Voice, hook → LinkedIn hook, gotchas → RECIPE).

3. **Rules.** Read `docs/blog/PLAYBOOK.md` (goals in priority order, formats, anti-goals, language rules) and
   `docs/blog/STYLE.md` (voice, visual identity, rubric). Look at every image the post references in
   `docs/blog/posts/<post>/images/`.

4. **Scores.** Fill the **Scores** table from STYLE.md's rubric, each check 0–2 with a short note:
   - **Information gain:** write the one sentence on what this post adds that the usual articles on the topic
     don't. If you can't, score 0 and say so.
   - **RECIPE self-test:** could the author redo the thing from the RECIPE alone, months from now?
   - **STEPPS:** score Social currency, Triggers, Emotion, Public, Practical value, Stories (0–2 each) and the raw
     total. The bars: raw ≥ 6, Practical value = 2, one of Social currency or Stories = 2.
   - **Voice:** list any hype words (`docs/blog/hype-words.txt` and anything like them); is a mistake or limit stated?
   - **LinkedIn hook:** its length in characters and whether it makes sense alone with a specific detail (0 when
     `linkedin.md` is missing).
   - **Images:** phone test (readable at 400 px wide), one point each, the series look.
   - **Goals 1–5:** 0–2 each, by the criteria in STYLE.md's rubric.
   - **Language:** English by default; any PT-BR text follows the playbook's rules.

5. **Must fix (blocking only).** Add an item only for:
   - **Safety:** any secret, key, password or token, any **token name** (the name of a stored secret: a gopass
     path, an environment variable that holds a secret, a key file name), an email address, a client or employer
     name, or a **private repository** name, in the text or visible in an image. Check a repository's visibility
     with `gh repo view <owner>/<name> --json visibility`. Tool names (`psc`, "Copy a secret") are fine.
   - **Anti-goals:** hype, spam patterns, hate, rage bait, or takes aimed at people or tools.
   - **The RECIPE:** missing, or impossible to follow as written.
   - **A failed `blog:check`.**
   List each problem once, however many rules it breaks. Everything else, however important, goes in
   **Consider**. The verdict is **BLOCKED** if Must fix has any item,
   else **PASS**.

6. **Consider.** At most 7 suggestions, most valuable first. Each names the goal it serves (1–5) and is concrete
   enough to apply ("cut the second paragraph of OVERVIEW: it repeats the hook", not "tighten the intro"). Include at
   least one on the **visuals** and one on the **tone** when there is anything to say about them.

7. **Variables.** Prefill the `vars:` comment for the post's task (`hook=… cover=… images=… linkedin=… lang=…
   day=<author> tags=…`): hook type (number, confession, opinion or question), cover style,
   images (count and kind), LinkedIn format, language, tags; leave day/time as `<author>`.

**A post that is already published** gets the same review; title the verdict `PASS (published)` or
`BLOCKED (published)`, and Must fix items become follow-ups for the author.

Write the result to `docs/blog/posts/<post>/review.md` using `docs/blog/templates/review.md`, dated today. Then reply
with the verdict and the Must fix items, nothing else.
