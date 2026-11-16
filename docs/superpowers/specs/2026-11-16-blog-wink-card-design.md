# Blog wink card

**Status:** approved 2026-11-16

## Intent

The pop-culture wink read out of place in the article's text and competed with the author's own beats ("presto!").
It moves into an image, the **wink card**, in the series look: the reference frames a real command and its real
output. Every post gets it in the article; LinkedIn uses it now and then instead of the link card, so the posts
don't all look alike.

## Goals, non-goals, anti-goals

- **Goals:** the wink lives in the card, never in the article's text; the card teaches on its own (the Trojan Horse
  test: the lesson can't be shared without the joke, nor the joke without the lesson); two images per post.
- **Non-goals:** a meme; franchise artwork, logos or fonts (a short quote only).
- **Anti-goals:** output git or a tool never prints; a real secret, key or token name in the window.

## Approaches

Rendered and compared: stacked windows (A), editorial split (A1), all terminal (A2) and a **diff card (A3, picked)**.
A3 first showed a `git diff` that the textconv would never print; it now runs the real
`diff -u <(git show HEAD:config/.env) config/.env`. A disclaimer caption was the fallback, kept for cards that can't
be real output.

## Design

- **The card:** the quote as the title (key words on pink), a one-line subtitle tying it to the topic, one focused
  window with a real command and its output (syntax colours: `{b:}` keys, `{g:}` strings, `{o:}` values, `{r:}`
  ciphertext, `{c:}` comments; whole-line `{del:}` / `{add:}` for diffs), the window's label as the wink word, a
  footer with the post's title and the `dots #N` pill. 1080 wide, height from `wink.json` (default 800, at most
  1080). Trims and notes are grey comments; a card that can't be real output carries a small italic caption.
- **Files:** `docs/blog/tools/wink.html`, `docs/blog/templates/wink.json`, per post `wink.json` →
  `images/01-wink.png`, rendered by `mise run blog:cover` with `raw/01-wink-phone.png`.
- **The article:** the card at the top of `## How I ran into it`; no pop-culture line in the text.
- **Checks:** `blog:check` blocks a new (unpublished, non-legacy) post without `./images/01-wink.png` or without
  `wink.json`; the gate checks the command is real and the phone test.
- **LinkedIn:** an image post now and then, only when the card stands alone; the link goes in the text;
  `vars: linkedin=image|link`.
- **This post:** the Marauder's Map lines leave the text; the card above goes in.
