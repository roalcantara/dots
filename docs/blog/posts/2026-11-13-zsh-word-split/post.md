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

> One string to rule them all: my agent's for-loop found one item where I had three.

## ⚡ TL;DR

My agents' bash-style loops ran once in my zsh. Point the agents at bash; keep zsh for yourself.

> **Use it when:**
>
> - an AI agent's shell loops on macOS run once, or do less than they report.
>
> **You need:**
>
> - bash from Homebrew (`brew install bash`); macOS's own `/bin/bash` is 3.2 (`/bin/bash --version`).

```jsonc
// Claude Code: ~/.claude/settings.json
{ "env": { "CLAUDE_CODE_SHELL": "/opt/homebrew/bin/bash" } }

// GitHub Copilot chat: VS Code's user settings.json
"chat.tools.terminal.terminalProfile.osx": { "path": "/opt/homebrew/bin/bash", "args": ["-l"] }
```

📁 **In dots:** [config/claude/settings.json](https://github.com/roalcantara/dots/blob/main/config/claude/settings.json) ·
[config/vscode/settings.json](https://github.com/roalcantara/dots/blob/main/config/vscode/settings.json) ·
[the PR (#108)](https://github.com/roalcantara/dots/pull/108)

## 🪲 The problem

The shell my agents write is bash-style (`for x in $list; do …`), and on my Mac they ran it in my login shell, zsh.

### Symptoms

```console
$ zsh -c 'list="a b c"; for x in $list; do echo "[$x]"; done'
[a b c]
$ bash -c 'list="a b c"; for x in $list; do echo "[$x]"; done'
[a]
[b]
[c]
```

🤔 Same line, two shells, one silent difference.

💡 That is a zsh feature, not a bug (see 💡 But how?).

😬 It just isn't what the agent meant.

## 💡 But how?

- **Why the agent's command ran in zsh**
  - Claude Code runs its commands in your shell unless `CLAUDE_CODE_SHELL` says otherwise
    ([environment variables](https://code.claude.com/docs/en/env-vars)).
  - Copilot chat runs them in a VS Code terminal, whose profile was zsh in my setup until I gave its tools a bash
    one ([Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings)). My login shell is zsh.
- **Why zsh does this**
  - In zsh, an unquoted `$list` stays one word unless you ask for splitting:

    ```zsh
    for x in ${=list}; do …   # splits once
    setopt SH_WORD_SPLIT      # splits always
    list=(a b c)              # the zsh way: an array
    ```

  - It is a deliberate design ([zsh FAQ 3.1](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)).

## 🛠️ The fix

### Claude Code: run its commands in bash

```jsonc
// ~/.claude/settings.json
{ "env": { "CLAUDE_CODE_SHELL": "/opt/homebrew/bin/bash" } }
```

### GitHub Copilot chat: give its terminal a bash profile

```jsonc
// VS Code's user settings.json (in dots: config/vscode/settings.json)
"chat.tools.terminal.terminalProfile.osx": {
  "path": "/opt/homebrew/bin/bash", "args": ["-l"]
}
```

### Keep zsh for yourself

- Your interactive terminal doesn't change: both tools now run their commands in Homebrew's bash 5
  ([#108](https://github.com/roalcantara/dots/pull/108)).

## 🧪 Check it works

Ask the agent to run this; it should print a bash version, not the fallback:

```console
$ echo "${BASH_VERSION:-not bash}"
5.3.20(1)-release
```

## ⚠️ Gotchas

- quoting (`"$list"`) doesn't help
  - it makes it one word in both shells
- `setopt SH_WORD_SPLIT` also fixes it
  - but for every script you run

## 🥷🏼 vs. making the agent write zsh

|            | Tell the agent "this is zsh"               | Give the agent bash                 |
| ---------- | ------------------------------------------ | ----------------------------------- |
| Effort     | A line in every prompt or instruction file | One setting per tool, once          |
| Depends on | The agent remembering, every time          | Nothing: bash idioms run as written |
| Your shell | Unchanged                                  | Unchanged                           |

## 🤓 What I (think I) learned

- **"It ran without errors" is not "it worked".**
  - The loop exited 0. Only the result told me.
- **Agents inherit your environment, not your intentions.**
  - Whatever your login shell does, they do.
- **Check which bash you get.**
  - On macOS, a bare `bash` can be the old 3.2; point the setting at Homebrew's.

## 📚 References

- zsh FAQ: [Why does `$var` where `var="foo bar"` not do what I expect?](https://zsh.sourceforge.io/FAQ/zshfaq03.html#l18)
- [Claude Code environment variables](https://code.claude.com/docs/en/env-vars) ·
  [VS Code Copilot settings](https://code.visualstudio.com/docs/copilot/reference/copilot-settings)
- My dotfiles: [the PR that moved my agents to bash (#108)](https://github.com/roalcantara/dots/pull/108)

---

Corrections and ideas are very welcome. :)

Drafted with AI help; every claim was checked by me, and the story is mine.
