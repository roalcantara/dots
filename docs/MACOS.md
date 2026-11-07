---
title: macOS preferences guide
description: The macOS defaults that mise bootstrap applies, how to preview, check and undo them, and what stays manual
---

# macOS preferences guide

> Last reviewed: 2026-11-06

`mise bootstrap` applies a set of macOS preferences tuned for keyboard-driven development. They live in
[`config/mise/conf.d/macos.toml`](../config/mise/conf.d/macos.toml), each with a one-line reason above it. Linux
bootstraps and the Docker images ignore them.

## What is managed

Items marked † are there for Raycast (launcher on ⌘Space) or yabai (tiling window manager, planned).

| Area | Settings |
| --- | --- |
| Keyboard | Fastest key repeat System Settings allows (`2`/`15`); held keys repeat instead of opening the accent menu; no auto-capitalize, autocorrect, smart quotes, smart dashes or double-space period; Tab reaches every control. |
| Spotlight † | Moved to ⌥Space, so ⌘Space is free for Raycast. |
| Trackpad and mouse | Tap to click (login window included), light click on built-in and Magic trackpads, natural scrolling, maximum tracking speed for both; three-finger drag off (keeps three-finger Space swipes). |
| Dock and Spaces | Eight pinned apps (Chrome, Ghostty, VS Code, Claude, ChatGPT, WhatsApp, Discord, System Settings); auto-hides at once, no recent apps, "scale" minimize; † Spaces never rearranged, one set per display. |
| Windows † | macOS edge tiling, Stage Manager and click-wallpaper-to-show-desktop off. |
| Finder | Hidden files, all extensions, path and status bars, folders first, list view, search the current folder, no extension-change warning, new documents save locally, expanded save/print dialogs. |
| Volumes | No `.DS_Store` on network shares or USB drives. |
| Screenshots | PNG, no window shadow, saved to `~/Pictures/Screenshots`. |
| Odds and ends | Time Machine stops offering new disks (restic is the backup); Photos stays closed when a phone connects. |
| Login items | noTunes, Raycast, Vorssaint, Bitwarden and Google Drive open at login; other login items stay. |
| Default apps | Text, code and config files open in VS Code ([`config/duti/defaults.duti`](../config/duti/defaults.duti)). |
| Touch ID for `sudo` | `/etc/pam.d/sudo_local` (root-owned, written with `sudo`; the one bootstrap step that asks for a password, once). |
| SSH key | The GitHub key (git's signing key) is stored in Keychain once and loaded into the agent at every login. |

After the defaults step a `post-defaults` hook sets the screenshot folder (mise writes values as given and cannot
expand `$HOME`), sets the default apps with `duti`, applies the Spotlight shortcut without a logout, and restarts Dock, Finder and the menu bar. It runs
on every bootstrap, so expect a brief flicker even when nothing changed. It never fails the bootstrap.

## Preview, apply, check

```sh
mise bootstrap macos defaults apply --dry-run   # what would be written
mise bootstrap macos defaults apply             # write them (asks first; --yes skips the prompt)
mise bootstrap macos defaults status --missing  # exit 1 if any declared preference is unset or differs
mise doctor                                     # the same drift, summarized
```

`mise bootstrap` runs the apply step for you, after Homebrew and before the login shell. Applying by hand skips the
hook; restart the apps yourself: `killall Dock Finder SystemUIServer`.

The screenshot folder is set by the hook, not declared, so these checks do not cover it; every bootstrap rewrites it.

A setting changed in System Settings shows as `differs`; the next bootstrap puts it back. To keep the new value, change
it in `macos.toml` too.

## Needs a logout

Log out and back in after the first apply for:

- Key repeat (`KeyRepeat`, `InitialKeyRepeat`) and press-and-hold.
- Tap to click.
- Separate Spaces per display (`spans-displays`); restarting the Dock does not apply it.

## Undo a setting

mise never deletes a preference. Remove the setting from `macos.toml`, then delete it so macOS falls back to its own
default:

```sh
defaults delete NSGlobalDomain KeyRepeat
defaults -currentHost delete com.apple.ImageCapture disableHotPlug   # entries with host = "current"
killall Dock Finder SystemUIServer
```

- **Dock apps:** removing `apps` from `[bootstrap.macos.dock]` leaves the Dock as it is; rearrange it by hand.
- **Login items:** removing an app leaves it in Open at Login; remove it in System Settings → General → Login Items.
- **Default apps:** remove the line from `defaults.duti`, then pick another app in Finder (Get Info → Open with →
  Change All).
- **Touch ID for `sudo`:** remove the `sudo_local` entry, then `sudo rm /etc/pam.d/sudo_local`.

## Dock, login items and default apps

The Dock is short on purpose: it auto-hides and Raycast opens everything else. `apps` replaces Apple's tiles in that
order; Finder, Trash and the Downloads stack stay. Every listed app must be installed when the defaults step runs, so
each one is a Brewfile cask (the Homebrew step runs first); a test checks this.

Login items are additive: apps you add yourself stay. Raycast is listed even though it can start itself, so a new Mac
gets it without opening its settings.

Default apps come from [`config/duti/defaults.duti`](../config/duti/defaults.duti): one line per type, tab-separated
bundle ID, UTI and role. Use real type identifiers (`mdls -name kMDItemContentType <file>`); an extension that macOS
does not know has a dynamic `dyn.*` type, which duti cannot set (error -50). `.ts` is left alone because macOS treats it
as a video file. LaunchServices applies changes a few seconds after duti exits; check with `duti -x sh` or
`duti -d public.json`.

## Touch ID for sudo

`/etc/pam.d/sudo` includes `/etc/pam.d/sudo_local`, which macOS updates keep, so Touch ID survives them. The
bootstrap writes it before Homebrew, so later `sudo` prompts (Homebrew's included) take a fingerprint. Over SSH, with
the lid closed and no Touch ID keyboard, or inside tmux/screen, `sudo` falls back to the password. Apply it alone with
`mise bootstrap files apply`.

## Apple Music and headphones

A Bluetooth headset sends a "play" key when it connects, and macOS starts Apple Music to handle it. No preference
turns this off, and the background service behind it (`rcd`) is protected by System Integrity Protection.
[noTunes](https://github.com/tombonez/noTunes) (the `notunes` cask) runs at login and closes Music whenever it
opens. To open Music on purpose, quit noTunes from its menu-bar icon first.

## SSH key and commit signing

Git signs commits with `~/.ssh/id_ed25519_github` ([`config/git/config`](../config/git/config)). Signing goes
through `ssh-keygen -Y sign`, which uses the SSH agent and never reads Keychain, so without the key in the agent a
commit waits for a passphrase (and hangs where there is no terminal).

- **Once per Mac:** the bootstrap task loads the key from Keychain; if Keychain does not have it yet, it asks for the
  passphrase on the terminal (`ssh-add --apple-use-keychain`). Without a terminal it prints the command to run.
- **Every login:** the `dev.mise.ssh-add` LaunchAgent runs `/usr/bin/ssh-add --apple-load-keychain`.
- **`ssh` itself:** `AddKeysToAgent yes` and `UseKeychain yes` in the SSH config load other keys on first use.

Apple's `/usr/bin/ssh-add` is used on purpose: Homebrew's OpenSSH has no `--apple-*` flags. Check with
`ssh-add -l`; check the agent with `mise bootstrap macos launchd-agents status`.

## Manual checklist

These need `sudo`, a choice of taste, or an app's own settings, so the bootstrap leaves them alone:

- [ ] Computer name: `sudo scutil --set ComputerName <name>` (and `HostName`, `LocalHostName`).
- [ ] FileVault: System Settings → Privacy & Security.
- [ ] Firewall: System Settings → Network → Firewall.
- [ ] Sleep and power: `pmset` or System Settings → Battery.
- [ ] Raycast: set its hotkey to ⌘Space in Raycast's settings.
- [ ] Hot corners, appearance (light/dark).
- [ ] Caps Lock remapping: planned with the yabai setup.

## Dropped keys

None so far: every key applied on macOS 27.2 without a warning. Record here any key a future macOS stops honoring.
