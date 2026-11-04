#!/usr/bin/env python3
"""One-off: config/mise/conf.d/packages.toml + [tools] -> config/homebrew/Brewfile (keeps comments)."""
import re, sys, pathlib

CORE = ["zoxide", "fzf", "eza", "bat", "ripgrep", "fd", "jq", "neovim", "git-delta"]
UV_TOOLS = ["pynvim", "debugpy", "commit-check"]  # graphifyy, code-review-graph: bootstrap task (Python 3.13)

src = pathlib.Path("config/mise/conf.d/packages.toml").read_text().splitlines()
taps, formulae, casks, flatpaks = [], [], [], []
section = None
entry = re.compile(r'^"(brew|brew-cask|flatpak|apt):([^"]+)"\s*=\s*(\{[^}]*\}|"[^"]*")\s*(#.*)?$')
for line in src:
    if line.startswith("[bootstrap.brew.taps]"): section = "taps"; continue
    if line.startswith("[bootstrap.packages]"): section = "packages"; continue
    if section == "taps":
        m = re.match(r'^"([^"]+)"\s*=\s*"([^"]+)"', line)
        if m: taps.append(f'tap "{m[1]}", "{m[2]}"')
        continue
    if section != "packages": continue
    m = entry.match(line)
    if not m:
        if line.startswith("#") and formulae is not None: formulae.append(("#", line))
        continue
    mgr, name, value, comment = m[1], m[2], m[3], (m[4] or "").strip()
    if mgr == "apt": continue                       # goes to conf.d/system.toml (Task 3)
    os_ = re.search(r'os\s*=\s*"(\w+)"', value)
    gate = {"macos": " if OS.mac?", "linux": " if OS.linux?"}.get(os_[1], "") if os_ else ""
    pad = f"  {comment}" if comment else ""
    if mgr == "brew":
        if name in CORE: continue
        formulae.append((name, f'brew "{name}"{gate}{pad}'))
    elif mgr == "brew-cask":
        casks.append(f'cask "{name}"{gate or " if OS.mac?"}{pad}')
    elif mgr == "flatpak":
        flatpaks.append(f'flatpak "{name}"{gate or " if OS.linux?"}{pad}')

out = [
    "# Every user package (assets/specs/brewfile-packages/design.md). Installed by the post-packages hook in",
    "# config/mise/conf.d/bootstrap.toml; `brew bundle …` reads it through HOMEBREW_BUNDLE_FILE.",
    "# HOMEBREW_DOTS_PROFILE selects the groups (brew passes only HOMEBREW_* variables to a Brewfile):",
    "# container gets the first group only; desktop (the default) gets everything.",
    'desktop = ENV.fetch("HOMEBREW_DOTS_PROFILE", "desktop") == "desktop"',
    "",
    *taps,
    "",
    "# Everywhere, containers included: the minimal shell set",
    *[f'brew "{n}"' for n in CORE],
    "",
    "# Desktop only below. `brew bundle add` appends here, so new packages are desktop-only unless moved up.",
    "return unless desktop",
    "",
    "# Desktop: formulae",
    'brew "uv"                                  # Python tool installer (the uv entries below)',
    *[l for _, l in formulae],
    "",
    "# Desktop: Python tools (graphifyy and code-review-graph need Python 3.13: the bootstrap task installs them)",
    *[f'uv "{t}"' for t in UV_TOOLS],
    "",
    "# Desktop: casks (macOS)",
    *casks,
    "",
    "# Desktop: Flatpak apps (Linux; Flathub is configured by conf.d/bootstrap.toml)",
    *flatpaks,
    "",
]
missing = [n for n in CORE if not any(f'"brew:{n}"' in l for l in src)] 
print("core not in packages.toml (added anyway):", missing, file=sys.stderr)
dest = pathlib.Path("config/homebrew/Brewfile"); dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text("\n".join(out))
print(f"taps {len(taps)} core {len(CORE)} formulae {sum(1 for n,_ in formulae if n!='#')} casks {len(casks)} flatpaks {len(flatpaks)}")
