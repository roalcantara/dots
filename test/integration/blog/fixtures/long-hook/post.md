---
title: A good post
published: false
description: Shows every part a post needs.
tags: ai, zsh, bash, productivity
cover_image: ./images/00-cover.png
---

On a new Mac, an agent's bash runs in zsh, and a loop over a list runs once.

## How I ran into it on a fresh Mac

![The wink card: the diff of the committed file and the one on disk](./images/01-wink.png)

The agent's loop over 16 file types ran once.

## The fix: two settings

```json
{ "env": { "CLAUDE_CODE_SHELL": "/opt/homebrew/bin/bash" } }
```

## Why not change zsh instead?

- Quoting doesn't help.
- `SH_WORD_SPLIT` changes every zsh.

## What I (think I) learned

- **Exit 0 is not "it worked".**

---

Corrections and ideas are very welcome. **NO, SERIOUSLY!** :)

> **DISCLAIMER** Not a tutorial.

Drafted with AI help; every claim was checked by me, and the story is mine.
