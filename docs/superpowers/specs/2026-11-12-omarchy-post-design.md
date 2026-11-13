# Blog post: Omarchy on macOS — design

## Intent

A dev.to post that shows off the setup giving macOS an Omarchy-like, keyboard-first desktop: yabai tiling with the
focus outline (JankyBorders), the fn layer (Karabiner), the spaces strip (SwiftBar), and the Raycast side (the Hotkeys
list with pictures, TUIs in floating Ghostty windows). A showcase, not a tutorial: the reader should *see* the result
and get the idea; whoever wants the code follows the links.

## Goals

- Written in the voice of the author's FCIS post: first person, humble ("what I think I've learned"), a DISCLAIMER
  note up top, bold ALL-CAPS section labels, short lists, 💡 callouts, "vs." comparisons, references at the end.
- A header image (1000 × 420, dev.to cover) and 6–8 framed screenshots of the real desktop, each with sensitive
  content blurred.
- Side-by-side moments with Omarchy where the user has their own Omarchy screenshots (the keybindings window).
- Links: dots is public (github.com/roalcantara/dots) — link PRs #109 (yabai, fn layer) and #110 (TUIs, shortcuts)
  and key files (`config/bin/yb`, `config/karabiner/src/bindings.ts`, `config/tuis.toml`, `docs/TILING.md`).

## Non-goals

- A setup guide or a deep dive; no install steps beyond "it's all in dots".
- Links into kb-raycast (private): its parts appear in screenshots only.
- Omarchy's own images (use the user's screenshots, or link omarchy.org).

## Anti-goals

- Any secret, email, token name, client or repo name readable in a screenshot.
- Screenshots that look like a cluttered real desktop rather than a clean showcase.

## Approach

A + B (chosen by the user): Claude stages and captures a first pass of every screenshot (yabai to arrange windows,
`screencapture`), blurs the sensitive regions and frames each image with a script (Pillow run through `uv`, nothing
installed), designs the header as SVG and exports PNG, and writes the draft. The user reviews and re-captures
whatever needs it. Alternatives considered: the user captures everything from a shot list (safer, slower); drawn
mockups (clean, but a showcase loses its point if the screens are not real).

## Shot list (first pass)

1. **Header** — generated: a stylised screen of tiled windows, one with the cyan → green focus outline, key caps
   (globe, ⇧, 1) and the title "Omarchy-ish macOS".
2. **The desktop** — two or three tiled windows on a space, focus outline visible, the menu bar strip on top;
   window contents blurred.
3. **The strip** — menu bar close-up: the spaces of each screen (SwiftBar).
4. **fn + k** — the Hotkeys list (descriptions + key caps), then with → the pane (key caps, picture, description).
   Side by side with the user's Omarchy keybindings screenshot.
5. **A TUI** — "Copy a secret" (psc) floating, centred over tiled windows; secret names blurred.
6. **Zoom** — fn + f: one window filling the space with the amber outline.
7. **Scratchpad or pin** — a floating window above the tiling (if it stages cleanly).

## Post outline

DISCLAIMER → OVERVIEW (why: Omarchy envy on a Mac) → THE PIECES (one short paragraph + screenshot each: tiling and
the outline, the fn layer, the strip, Hotkeys, TUIs) → vs. OMARCHY (a small table: what maps 1:1, what macOS makes
harder) → WHAT I (THINK I) LEARNED (a few lessons: the scripting addition on a new macOS, one-shot yabai rules,
focus races with Raycast) → REFERENCES (Omarchy, yabai, Karabiner-Elements, SwiftBar, JankyBorders, Raycast, Ghostty,
the dots PRs). About 1,200–1,500 words.

## Where it goes

`docs/posts/omarchy-on-macos/` in dots: `post.md`, `images/*.png` (final), `raw/` (unblurred captures, git-ignored),
`tools/frame.py`. Committing is the user's call.

## Left to the builder

The header's exact composition and palette (matching the outline gradient); which windows stage each scene; the
blur regions (chosen by looking at each capture); the wording.
