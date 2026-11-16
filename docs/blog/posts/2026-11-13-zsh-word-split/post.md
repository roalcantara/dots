---
title: "Your AI agent writes bash. Your Mac runs zsh."
published: false
description: Since Catalina, a new Mac's shell is zsh, and Claude Code runs its commands in it. One unquoted $var later, an agent's loop over 16 file types ran once and exited 0.
tags: ai, zsh, bash, productivity
cover_image: ./images/00-cover.png
---

Since macOS Catalina, new Mac accounts get zsh as their shell ([Apple](https://support.apple.com/en-us/102360)).
Claude Code runs its commands in your shell unless told otherwise
([Claude Code docs](https://code.claude.com/docs/en/env-vars)). And the shell code it writes is.. bash.

Most days the gap doesn't show. Loops over a list are where it does:

```console
$ bash -c 'v="a b c"; for x in $v; do echo "$x"; done'
a
b
c
$ zsh -c 'v="a b c"; for x in $v; do echo "$x"; done'
a b c
```

bash splits `$v` and loops three times. zsh keeps it whole and loops once. Neither says a word. :(

## How I ran into it

Setting up a fresh Mac, I had Claude Code make VS Code the app for 16 kinds of text files, feeding a list of types
to `duti` in a loop. One string to rule them all: in zsh, the loop ran once with all 16 glued together. `duti` said
`unrecognized`.. and exited 0.

The agent caught it on its own:

> *"My loop didn't split the list, a zsh word-splitting quirk."*

I had read that same line before. Twice is a pattern. Time for a setting.

## The fix: two settings

Claude Code reads its shell from `CLAUDE_CODE_SHELL`:

```jsonc
// ~/.claude/settings.json
{ "env": { "CLAUDE_CODE_SHELL": "/opt/homebrew/bin/bash" } }
```

GitHub Copilot chat runs commands in a VS Code terminal, which opened zsh too. It takes a profile of its own:

```jsonc
// VS Code's user settings.json
"chat.tools.terminal.terminalProfile.osx": {
  "path": "/opt/homebrew/bin/bash", "args": ["-l"]
}
```

Both point at Homebrew's bash 5 (`brew install bash`), because macOS's own `/bin/bash` is much older:

```console
$ /bin/bash --version | head -1
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin26)
```

Ask the agent to run:

```console
$ echo "${BASH_VERSION:-not bash}"
5.3.20(1)-release
```

And **presto!** My own terminal still opens zsh; only the agents moved.

## Why not change zsh instead?

zsh does this on purpose ([zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)). `setopt SH_WORD_SPLIT`
would change every zsh I open, and scripts never read `~/.zshrc` anyway
([zsh startup files](https://zsh.sourceforge.io/Doc/Release/Files.html)). Quoting doesn't help either: `"$v"` is one
word in bash too.

```console
$ bash -c 'v="a b c"; for x in "$v"; do echo "$x"; done'
a b c
```

Telling the agent to write zsh works until it forgets. A setting has nothing to forget.

## What I (think I) learned

- **Exit 0 is not "it worked".** `duti` complained and exited 0; only the output told.
- **Agents inherit your machine, not your intentions.** Including choices I made for me, not for them.
- **The fix came from the same agent** (err.. Claude found `CLAUDE_CODE_SHELL`, actually).

The settings live in my dotfiles:
[Claude Code](https://github.com/roalcantara/dots/blob/main/config/claude/settings.json),
[VS Code](https://github.com/roalcantara/dots/blob/main/config/vscode/settings.json), and
[the PR (#108)](https://github.com/roalcantara/dots/pull/108).

---

Corrections and ideas are very welcome. **NO, SERIOUSLY!** :)

> **DISCLAIMER**
> This is not a tutorial. It is a small bug I (think I) understood, and the fix lives in
> [my dotfiles](https://github.com/roalcantara/dots).
> **PLEASE:** use it with a grain of salt! **YOU HAVE BEEN WARNED!**

Drafted with AI help; every claim was checked by me, and the story is mine.
