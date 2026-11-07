# macOS defaults — design

## Intent

A fresh macOS 27 install should come out of `mise bootstrap` tuned for keyboard-driven development, with every
preference declared in the repo, explained next to its value, and re-applied idempotently. Raycast owns ⌘Space; a
later brainstorm adds yabai, so nothing here may fight a tiling window manager.

## Goals

- Declare the preferences below in mise's native `bootstrap.macos` sections; `mise bootstrap` applies them.
- Every setting carries a one-line *why* comment.
- `docs/MACOS.md` explains preview/apply/drift/rollback and lists what stays manual.
- Stop Apple Music from launching when a Bluetooth headset connects.

## Non-goals

- `sudo` settings (hostname, `pmset`, firewall, FileVault, Spotlight indexing): manual checklist in the doc.
- yabai/skhd setup, Caps Lock remapping, Spotlight tuning, Safari (sandboxed, needs Full Disk Access).
- Taste calls not yet made: hot corners, pinned Dock apps, dark mode, Raycast login item.

## Anti-goals

- A shell script of `defaults write` lines (mise already does this declaratively, with drift detection).
- Anything that changes Linux bootstraps or the Docker images (mise ignores these sections off macOS).
- Settings that conflict with yabai (edge tiling, Stage Manager, auto-rearranged Spaces).

## Approaches

1. **New `config/mise/conf.d/macos.toml` + `docs/MACOS.md`** — chosen. Keeps `bootstrap.toml` focused on
   packages/hooks; comments sit beside values.
2. Append to `bootstrap.toml` — one file fewer, but mixes preferences into the Homebrew/Linux logic.
3. Generate TOML from a docs table — docs never drift, but a generator for ~40 keys is not worth it.

Scope chosen by the owner: preferences only (option A); system-level `sudo` setup may follow later.

## Settings

Prefer mise's named keys; fall back to `[bootstrap.macos.defaults]`, and to `[[bootstrap.macos.defaults_entries]]`
for `-currentHost` or nested (`path`) keys. † = for Raycast/yabai.

| Area | Setting | Value |
| --- | --- | --- |
| Keyboard | `key_repeat` / `initial_key_repeat` | `2` / `15` (fastest the UI allows; needs logout) |
| Keyboard | `press_and_hold` | `false` (key repeat for vim motions) |
| Keyboard | auto-capitalize, spelling correction, smart quotes, smart dashes, period substitution | all `false` |
| Keyboard | `AppleKeyboardUIMode` (global) | `3` (Tab reaches every control) |
| Keyboard † | `com.apple.symbolichotkeys` `AppleSymbolicHotKeys` → `64` | Spotlight on ⌥Space: `{enabled=true, value={parameters=[32,49,524288], type="standard"}}` |
| Trackpad | `tap_to_click` | `true` |
| Trackpad | `FirstClickThreshold`, `SecondClickThreshold` (built-in and Bluetooth trackpad domains) | `0` (light click) |
| Trackpad | `com.apple.mouse.tapBehavior` (global, current host) | `1` (tap to click at the login window) |
| Trackpad | `com.apple.swipescrolldirection` (global) | `true` (natural; stated explicitly) |
| Trackpad | `com.apple.trackpad.scaling` (global) | `3.0` |
| Trackpad | `three_finger_drag` | `false` (keeps three-finger Space swipes) |
| Mouse | `com.apple.mouse.scaling` (global) | `3.0` |
| Dock | `autohide`, `autohide_delay`, `autohide_time_modifier` | `true`, `0.0`, `0.15` |
| Dock | `show_recents`; `mineffect` | `false`; `"scale"` |
| Spaces † | `mru_spaces` | `false` |
| Spaces † | `com.apple.spaces` `spans-displays` | `false` (separate Spaces per display) |
| Windows † | `com.apple.WindowManager` `EnableTilingByEdgeDrag`, `EnableTopTilingByEdgeDrag`, `EnableTilingOptionAccelerator`, `GloballyEnabled` (Stage Manager), `EnableStandardClickToShowDesktop` | all `false` |
| Finder | `show_all_files`, `show_pathbar`, `show_status_bar`, `sort_folders_first` | `true` |
| Finder | `AppleShowAllExtensions` (global); `show_extensions_warning` | `true`; `false` |
| Finder | `preferred_view_style`; `FXDefaultSearchScope` | `list`; `"SCcf"` (current folder) |
| Finder | `save_new_documents_to_cloud` | `false` |
| Dialogs | `NSNavPanelExpandedStateForSaveMode`(`2`), `PMPrintingExpandedStateForPrint`(`2`) (global) | `true` |
| Volumes | `com.apple.desktopservices` `DSDontWriteNetworkStores`, `DSDontWriteUSBStores` | `true` |
| Screenshots | `com.apple.screencapture` `type`, `disable-shadow`; `location` set by the hook | `png`, `true`; `$HOME/Pictures/Screenshots` |
| Backups | `com.apple.TimeMachine` `DoNotOfferNewDisksForBackup` | `true` (restic is the backup) |
| Devices | `com.apple.ImageCapture` `disableHotPlug` (current host) | `true` (Photos stays closed) |

Keep the existing `org.gpgtools.common` entry in `bootstrap.toml` where it is.

## Apple Music on headset connect

No preference controls it (`rcd` hands the play key to Music; its launch agent is SIP-protected). Install the
`notunes` cask (Brewfile, desktop casks, beside Raycast) and add `/Applications/noTunes.app` to
`[bootstrap.macos.login_items] apps` (additive, not `exclusive`). Trade-off, documented: Music won't open on purpose
until noTunes is quit.

## SSH key in Keychain (added 2026-11-06)

Git signs with `~/.ssh/id_ed25519_github` through the agent only, so a commit hangs without it. The bootstrap task
(`# ssh-keychain` snippet, macOS desktop only, never fails) loads it from Keychain, or asks once on the terminal for
`/usr/bin/ssh-add --apple-use-keychain`; without a terminal it prints the command. A LaunchAgent
`[bootstrap.macos.launchd.agents.ssh-add]` runs `/usr/bin/ssh-add --apple-load-keychain` at every login. The
passphrase is typed by the owner, never stored in the repo or gopass.

## Touch ID, default apps, Dock and login items (added 2026-11-06)

- Touch ID for `sudo`: `/etc/pam.d/sudo_local` (`auth sufficient pam_tid.so`), root-owned via `[bootstrap.files]`,
  `phase = "pre-packages"`. The only `sudo` the macOS preferences need; mise asks only when the file differs.
- Default apps: `duti` (Brewfile) reads `config/duti/defaults.duti` (linked to `~/.config/duti`) from the
  post-defaults hook; text, code and config UTIs open in VS Code. Real UTIs only (`dyn.*` fail with -50).
- Dock: browser, terminal, editor, AI, chat, settings (Chrome, Ghostty, VS Code, Claude, ChatGPT, WhatsApp, Discord,
  System Settings), all Brewfile casks. Login items (additive): noTunes, Raycast, Vorssaint, Bitwarden, Google Drive.

## Hooks

`[bootstrap.hooks] post-defaults` (macOS only, never fails the bootstrap): write the screenshot `location` with
`$HOME` (mise writes values verbatim, so it cannot be declared), then
`activateSettings -u` (applies the Spotlight hotkey without logout), then `killall Dock Finder SystemUIServer`.
Runs on every bootstrap; a brief Dock/Finder flicker on no-op runs is accepted.

`~/Pictures/Screenshots` is added to `bootstrap.directories` (`os = "macos"`) so the screenshot location exists.

## Docs

`docs/MACOS.md`: what the file manages, `mise bootstrap macos defaults apply --dry-run`, `apply`, `status --missing`,
`mise doctor`; logout-required settings; how to undo (mise never deletes: `defaults delete <domain> <key>`); the
manual/`sudo` checklist; the noTunes trade-off. Link it from `README.md` and `AGENTS.md`'s Docs list.

## Verification

- `mise bootstrap macos defaults apply --dry-run` lists the expected writes with no warnings (unknown keys and wrong
  types only warn, so warnings are failures here).
- Apply, log out/in, then `status --missing` exits 0; spot-check: key repeat, ⌥Space opens Spotlight and ⌘Space
  Raycast, Dock autohides, connecting a headset leaves Music closed.
- A Bun spec under `test/integration/bootstrap/` parses `macos.toml` and pins the yabai/Raycast-critical values
  (`mru_spaces`, tiling off, hotkey 64) and that the hook tolerates failure.
- `hk check --all` and `mise run test:specs` green.

## Left to the builder

- Confirm each key still exists/takes effect on macOS 27 (dry-run warnings, then a quick visual check); drop any that
  don't and note it in the doc.
- Whether `login_items` needs the app present when the defaults step runs (packages run first; verify the order).
- Exact TOML shape for the hotkey (`key = "AppleSymbolicHotKeys"`, `path = ["64"]` (path is relative to key), integers stay integers).
