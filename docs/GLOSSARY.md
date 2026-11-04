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
| **Backup manifest** | `config/restic/backup.toml`: defines repository path, source paths, retention policy, and exclusions with reasons. |
| **restic repository** | Encrypted, deduplicated restic storage at `<backup root>/machines/<host>/restic`. |
| **Snapshot** | Point-in-time backup archive inside a restic repository, tagged with the machine host name. |
| **Export** | Dated folder under `machines/<host>/exports/` holding machine audit reports and manual exports. |
| **Reinstall audit** | `mise run reinstall:audit`: read-only evaluation of uncommitted git state, non-cask apps, and machine risk (`MANIFEST.md`). |
| **Keyring recipient** | Public age key that gopass's identity keyring is encrypted to (`age.keyring-recipients`): the bootstrap key and the recovery key. |
| **Keyring identity** | Plaintext age key file that unlocks gopass's identity keyring (`age.keyring-identities`): `~/.config/age/keys.txt`. |
| **Recovery key** | Offline age key kept as a Bitwarden secure note; a second keyring recipient for when `keys.txt` is lost. |
