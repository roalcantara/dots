<!-- markdownlint-disable-file -->

# Dots glossary

This glossary defines terms used across Dots configuration, documentation, and tooling.

## Terms

| Term | Definition |
| --- | --- |
| **Dots** | This cross-platform dotfiles repository. |
| **Guide** | Canonical documentation and operational runbooks located under `docs/`. |
| **Integration spec** | A Bun subprocess specification under `test/integration/<domain>/` verifying script execution and output. |
| **`config/bin`** | Repository directory containing portable CLI helper scripts on PATH. |
| **`xc-*` tool** | A command-line script in `config/bin` with the `xc-` prefix. |
| **`xc` launcher** | Interactive menu and dispatcher discovering and executing `xc-*` tools. |
| **`gen`** | Shell completion generator (`config/bin/gen`) powered by Usage CLI specifications. |
| **Mise task** | Automation workflow declared in `mise.toml` or `test/mise.toml`, run via `mise run <task>`. |
| **Quality gate** | Concrete verification command (e.g. `mise run test:specs`, `hk check --all`) that must be green before merging. |
| **Backup root** | Storage directory holding backups, `/Volumes/backups` by default; overridden by `DOTS_BACKUP_ROOT`. |
| **Backup manifest** | `config/restic/backup.toml`: defines repository path, the allowlist of source paths, retention policy, and exclusions with reasons. |
| **restic repository** | Encrypted, deduplicated restic storage at `<backup root>/machines/<host>/restic`. |
| **Theme** | One folder under `config/theme/themes/` holding the shell-side tools' colours, one small file per tool (`env.zsh`, `ls_colors`, `theme.ghostty`, …). |
| **Current theme** | The theme folder the `current` link under `~/.local/state/dots/theme` points at; a missing link means `catppuccin-mocha`. |
| **Warning pattern** | A command shape (`rm -rf`, `sudo rm`, `git push --force`, …) whose whole typed line `warn-highlight.zsh` paints in `DOTS_WARN_STYLE`. |
| **Lig** | The completion popup under the cursor (Fig's successor), started from `config/zsh/opt/rc.d/lig.zsh` and themed by the active theme's `lig.toml`; fzf-tab answers Tab when it is closed. |
| **Safety net** | gomi aliased to `rm` in interactive shells: files move to a restorable trash, and `\rm` or `command rm` still delete. |
| **Snapshot** | Point-in-time backup archive inside a restic repository, tagged with the machine host name and `home:<home>` (the folder `restore` maps from). |
| **Export** | Dated folder under `machines/<host>/exports/` holding machine audit reports and manual exports. |
| **Reinstall audit** | `mise run reinstall:audit`: read-only evaluation of uncommitted git state, non-cask apps, and machine risk (`MANIFEST.md`). |
| **Keyring recipient** | Public age key that gopass's identity keyring is encrypted to (`age.keyring-recipients`): the bootstrap age key. |
| **Keyring identity** | Plaintext age key file that unlocks gopass's identity keyring (`age.keyring-identities`): `~/.config/age/keys.txt`. |
| **Recovery key** | The bootstrap age key itself, kept as a Bitwarden secure note: it decrypts the history and the repo's SOPS files, gopass's keyring included. |
