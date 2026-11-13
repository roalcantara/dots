---
title: "My AI agent's for-loop ran once: zsh doesn't split $vars"
published: false
description: My coding agents write bash-style loops, but on macOS they ran them in my zsh. One unquoted variable later, a loop ran once and reported success.
tags: ai, zsh, bash, productivity
cover_image: ./images/00-cover.png
---

> **DISCLAIMER**
> This is not a tutorial. It is a small bug I (think I) understood, and the fix lives in
> [my dotfiles](https://github.com/roalcantara/dots). Use it with a grain of salt!

![The cover: "My AI agent's for-loop ran once", a Ghostty terminal showing the loop print [a b c] once](./images/00-cover.png)

**OVERVIEW**

<author: the moment — when and how you noticed an agent's loop had run once, and what it cost you>

<!-- hook options (pick one, edit it, or write your own; each rests on commit 15ebd18, #108):
1. Pain: "Exit 0 is not 'it worked'. My agent's loop ran once over the whole list and still reported success."
   Confirm: did a run report success while doing a fraction of the work?
2. Confession: "My AI agent swore it had handled every item. It had handled one: the whole list, as a single word."
   Confirm: which task was it (files, branches, packages)?
3. Number: "One setting fixed a bug that never printed an error." Confirm: was CLAUDE_CODE_SHELL the first fix you tried?
4. Wink (The Lord of the Rings): "One string to rule them all: my agent's for-loop found one item where I had three."
5. Wink (Harry Potter): "The right spell, the wrong wand: bash idioms cast in zsh did almost nothing, quietly."
-->

The shell my agents write is bash-style (`for x in $list; do …`), and on my Mac they ran it in my login shell, zsh.
zsh doesn't split an unquoted variable into words:

```console
$ zsh -c 'list="a b c"; for x in $list; do echo "[$x]"; done'
[a b c]
$ bash -c 'list="a b c"; for x in $list; do echo "[$x]"; done'
[a]
[b]
[c]
```

Same line, two shells, one silent difference. 💡 That is a zsh feature, not a bug
([zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)). It just isn't what the agent meant.

**RECIPE**

> **Use it when:** an AI agent's shell loops on macOS run once, or do less than they report.
> **You need:** bash from Homebrew (`brew install bash`); macOS's own `/bin/bash` is 3.2 (`/bin/bash --version`).

1. Claude Code: run its commands in bash — `"env": { "CLAUDE_CODE_SHELL": "/opt/homebrew/bin/bash" }` in
   `~/.claude/settings.json`
2. GitHub Copilot chat in VS Code: give its terminal a bash profile —
   `"chat.tools.terminal.terminalProfile.osx": { "path": "/opt/homebrew/bin/bash", "args": ["-l"] }`
3. Keep zsh for yourself — your interactive terminal doesn't change.

⚠️ **Gotchas:** quoting (`"$list"`) doesn't help, it makes it one word in both shells · `setopt SH_WORD_SPLIT`
also fixes it, but for every script you run
📁 **In dots:** [config/claude/settings.json](https://github.com/roalcantara/dots/blob/main/config/claude/settings.json) ·
[config/vscode/settings.json](https://github.com/roalcantara/dots/blob/main/config/vscode/settings.json) ·
[the PR (#108)](https://github.com/roalcantara/dots/pull/108)

**HOW IT WORKS**

- **Why the agent's command ran in zsh.** Claude Code runs its commands in your shell unless `CLAUDE_CODE_SHELL`
  says otherwise ([settings](https://docs.anthropic.com/en/docs/claude-code/settings)); Copilot chat runs them in a
  VS Code terminal, whose profile was zsh in my setup until I gave its tools a bash one
  ([terminal profiles](https://code.visualstudio.com/docs/terminal/profiles)). My login shell is zsh.
- **Why zsh does this.** In zsh, an unquoted `$list` stays one word unless you ask for splitting: `${=list}` splits
  once, `setopt SH_WORD_SPLIT` splits always. The zsh way to hold several items is an array, `list=(a b c)`. It is a
  deliberate design ([zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)).
- **What I changed** ([#108](https://github.com/roalcantara/dots/pull/108)): both tools now run their commands in
  Homebrew's bash 5, and my own terminal stays zsh.

**vs. MAKING THE AGENT WRITE ZSH**

| | Tell the agent "this is zsh" | Give the agent bash |
| --- | --- | --- |
| Effort | A line in every prompt or instruction file | One setting per tool, once |
| Depends on | The agent remembering, every time | Nothing: bash idioms run as written |
| Your shell | Unchanged | Unchanged |

**WHAT I (THINK I) LEARNED**

- **"It ran without errors" is not "it worked".** The loop exited 0. Only the result told me.
- **Agents inherit your environment, not your intentions.** Whatever your login shell does, they do.
- **Check which bash you get.** On macOS, a bare `bash` can be the old 3.2; point the setting at Homebrew's.

---

**REFERENCES**

- zsh FAQ: [Why does `$var` where `var="foo bar"` not do what I expect?](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)
- [Claude Code settings](https://docs.anthropic.com/en/docs/claude-code/settings) ·
  [VS Code terminal profiles](https://code.visualstudio.com/docs/terminal/profiles)
- My dotfiles: [the PR that moved my agents to bash (#108)](https://github.com/roalcantara/dots/pull/108)

Corrections and ideas are very welcome. :)
