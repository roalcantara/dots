# gopass unlocked by the bootstrap age key — design

Status: approved approach (owner, 2026-11-04): **A, the age key unlocks everything**; recovery key in Bitwarden.

> Revised after review (2026-11-04): the recovery key is the age key itself, not a second keyring recipient (the
> history is encrypted only to the age key, so a second recipient cannot recover a new machine); the backup is
> kept outside the tracked `~/.config/gopass`; the trade-off is stated as a real loss of a second factor.

## 1. Problem

`install` asks for one secret, the age key (`config/age/keys.txt`), which decrypts the mise history. The history
restores `~/.config/gopass`, whose age identity keyring is protected by a **second** secret, a passphrase.

- macOS hides that second secret: `pinentry-mac` cached it in the Keychain on 2025-10-17 (service `GnuPG`,
  account `pass/age-identities`).
- Linux has no such cache: every `gopass show` opens pinentry ("Enter your PIN"), and with no terminal
  (scripts, `password_command`, containers) it fails with `pinentry error`.

Goal: one secret per machine, typed once, on macOS, Linux and containers alike.

## 2. Options considered

| | Approach | Verdict |
| --- | --- | --- |
| A | Encrypt the gopass keyring to the bootstrap age key (`age.keyring-recipients` / `age.keyring-identities`, gopass ≥ 1.17) | **Chosen**: no second secret, no OS keyring, same on every platform |
| B | Keep the passphrase; cache it per OS (`pinentry-gnome3` + gnome-keyring via `[bootstrap.services]`, gopass agent) | Rejected: still a second password per machine; nothing to cache in headless/containers |
| C | fnox keychain provider feeding `GOPASS_AGE_PASSWORD` | Rejected for now: extra tool, keychain filled per machine, needs a Secret Service on Linux. Possible later for app secrets (fnox has a gopass provider) |

`mise bootstrap` has no keychain integration (`[bootstrap.secrets]` reads env vars or prompts), and
`[bootstrap.services]` manages long-running programs, not pinentry (gopass spawns pinentry per prompt).

## 3. Verified behavior (2026-11-04, Ubuntu container, gopass 1.17.4, throwaway store)

| Check | Result |
| --- | --- |
| Passphrase keyring, no tty, no `GOPASS_AGE_PASSWORD` | `pinentry error` |
| `gopass age identities reencrypt` | asks the old passphrase, lists the recipients, asks `Protect the keyring with these recipients? [y/N/q]`; exit 0 |
| `identities` header | `-> scrypt` before, `-> X25519` after |
| After, no tty, agent disabled | secret printed |
| `keyring-identities` file missing | `failed to decrypt` |
| `keyring-identities = ~/.config/age/keys.txt` (literal `~`) | works: one config for macOS and Linux |
| Insert then show a new secret | works |

## 4. Design

### 4.1 One-time switch (owner, on the Mac)

Interactive by nature (old passphrase plus the recipient review, which `--yes` does not bypass), so it is a
documented owner step, never automated:

```sh
bak="$HOME/.local/state/dots/gopass-identities.scrypt.bak"; mkdir -p "${bak%/*}"   # outside the tracked dir
cp -p ~/.config/gopass/age/identities "$bak"
gopass config age.keyring-identities '~/.config/age/keys.txt'
gopass config age.keyring-recipients "$(age-keygen -y ~/.config/age/keys.txt)"
gopass age identities reencrypt                # old passphrase, then y
gopass show -o tokens/age.dots.github.com </dev/null   # prints, no prompt
mise dot save && mise dot sync                 # record ~/.config/gopass in the history and push it
rm "$bak"                                      # once a second machine has decrypted
```

Optional: delete the stale Keychain item (`GnuPG` / `pass/age-identities`).

### 4.2 Recovery

The recovery key is the age key itself (`AGE-SECRET-KEY-1…`), kept as a Bitwarden secure note. The history is
encrypted only to it and is the only carrier of `~/.config/gopass`, so on a new machine it is the one thing that
recovers both: paste it when `install` asks. A second keyring recipient was considered and dropped: without the
age key there is no history, hence no keyring, to open.

### 4.3 Bootstrap check

In `config/mise/conf.d/bootstrap.toml`, the bootstrap task, after the gopass store clone, between
`# gopass-keyring: begin` and `# gopass-keyring: end` (testable like the skills snippet):

```sh
ids="$HOME/.config/gopass/age/identities"
if command -v gopass >/dev/null && [ -s "$ids" ]; then
  if head -n 3 "$ids" | grep -q -- '-> scrypt'; then
    echo "bootstrap: gopass keyring still uses a passphrase; switch it to the age key: see docs/REINSTALL.md#one-secret-the-age-key" >&2
  else
    kid="$(gopass config age.keyring-identities 2>/dev/null)"; kid="${kid/#\~/$HOME}"
    [ -z "$kid" ] || [ -s "$kid" ] || echo "bootstrap: gopass keyring identity file missing: $kid" >&2
  fi
fi
```

It only warns; it never exits non-zero and never edits gopass config. `install` and step order are unchanged
(the history restores `~/.config/gopass` before the store clone).

### 4.4 Docs

- `docs/REINSTALL.md`: section **One secret: the age key** — why, the §4.1 steps, recovery (§4.2), the
  trade-off (§5), and a Troubleshooting row for "Enter your PIN" / `pinentry error`.
- `docs/GLOSSARY.md`: *keyring recipient*, *keyring identity*, *recovery key*.
- `config/mise/config.toml:128`: the comment no longer says the identity is passphrase-protected.

### 4.5 Tests

`test/integration/bootstrap/gopass-keyring.spec.ts`:

- Snippet present between the markers.
- Stub `gopass` on PATH; fixture `identities` with `-> scrypt` → warning naming the doc; with `-> X25519` and an
  existing key file → silent; with `-> X25519` and a missing key file → the "missing" warning; exit 0 in all.
- End to end, skipped unless real `gopass`, `age-keygen` and `expect` are on PATH (the §3 container run, as a
  spec): throwaway `HOME`, passphrase store via `GOPASS_AGE_PASSWORD`, `reencrypt` driven by `expect` answering
  `[y/N/q]` with `y`, then `gopass show -o` with stdin closed returns the value, and fails once the key file is
  moved away.

### 4.6 Related, out of scope

`mise.toml` `setup:age` fetches the age key from Bitwarden through `bw` (macOS only, credentials in the Keychain).
`bw` is no longer installed and `install` asks for the key instead. Bitwarden stays the off-machine home of the
age key (the recovery key); whether to drop or port `setup:age` is a separate decision.

## 5. Risks and trade-offs

| Risk | Mitigation |
| --- | --- |
| The age key alone now opens gopass (before: key + passphrase, a second factor) | Accepted for one-secret bootstrap: `0600` file, FileVault / LUKS, off-machine copy only in Bitwarden |
| `keys.txt` lost | The age key's copy in Bitwarden (§4.2) |
| Bitwarden copy lost too | Same as today: the history (and so gopass) is unrecoverable |
| A new gopass version changes the feature | The E2E spec catches regressions on machines that run it |
| Migration interrupted | Backup in §4.1; gopass verifies decryption of the new keyring before replacing the old |

## 6. Done when

1. Spec, plan and implementation merged; `mise run test:specs` and `hk check` clean.
2. On the Mac, `head -2 ~/.config/gopass/age/identities` shows `X25519`.
3. On a fresh Ubuntu VM after `install`, `gopass show -o tokens/age.dots.github.com </dev/null` prints with no prompt.
