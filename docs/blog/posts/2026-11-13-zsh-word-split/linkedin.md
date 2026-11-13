## Post

My AI agent's for-loop ran once. No error, exit 0, a confident summary. The agent wasn't wrong, and neither was my shell: they just spoke different dialects.

Coding agents write bash. On macOS, they may run it in your login shell: zsh. And zsh doesn't split an unquoted
$var into words, so `for x in $list` loops once over the whole string. That's a zsh feature (it spares humans a class
of quoting bugs); it just isn't what the agent meant.

The fix took two settings, and my terminal stays zsh:
→ Claude Code: CLAUDE_CODE_SHELL=/opt/homebrew/bin/bash
→ Copilot chat: a bash terminal profile for its tools
→ Homebrew's bash 5, not macOS's bash 3.2 from 2006

What I got wrong: my first fix was quoting "$list". In zsh that changes nothing; in bash it turns the three items into one on purpose. The lesson I keep: "it ran without errors" is not "it worked".

Has an agent ever "succeeded" at something it didn't do for you? How did you catch it?

Hashtags: #AI #DeveloperTools #macOS

## First comment

The full write-up, with the recipe and the exact settings: {devto.url}

## In-between post

Next week: the RECIPE as a 4-slide carousel (the two loops, the two settings, the gotchas), dev.to link in the first
comment.
