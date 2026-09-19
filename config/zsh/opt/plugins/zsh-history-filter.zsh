# Zsh History Filter Plugin Configuration
# https://github.com/MichaelAquilina/zsh-history-filter
# - Prevent matching commands from being written to `HISTFILE` using the native `zshaddhistory` return `2` behavior.
# - No external binary call per command, no fail-soft external-process dependency.

# Patterns to exclude from persistent history
# Keep these specific enough to avoid too many false positives.
export HISTORY_FILTER_EXCLUDE=(
  "ghp_" "gho_" "ghu_" "ghs_" "ghr_"
  "Authorization: Bearer " "authorization: bearer " "Bearer "
  "GITHUB_TOKEN=" "GH_TOKEN="
  "OPENAI_API_KEY=" "ANTHROPIC_API_KEY="
  "AWS_SECRET_ACCESS_KEY=" "AWS_SESSION_TOKEN="
  "DATABASE_URL="
  "TOKEN=" "SECRET=" "PASSWORD=" "PASSWD=" "PRIVATE_KEY="
  "sk-ant-" "sk-proj-" "xoxb-" "xoxp-" "AKIA"
  "-----BEGIN PRIVATE KEY-----"
)

# silence "Excluding command from history" (Optional)
export HISTORY_FILTER_SILENT=1

# Keep history safety defaults; Ignore commands that start with a space
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_ALL_DUPS