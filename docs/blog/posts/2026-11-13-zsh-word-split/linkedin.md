## Post

My AI agent writes bash. My Mac runs zsh. On a fresh install, that meant a loop over 16 file types ran once.. and
still exited 0. :(

Since Catalina, new Mac accounts use zsh, and Claude Code runs in your shell. zsh doesn't split an unquoted $var;
setting CLAUDE_CODE_SHELL to Homebrew's bash gives the agents bash, and my terminal stays zsh.

→ first comment

Hashtags: #AI #zsh #macOS

## First comment

{devto.url}
