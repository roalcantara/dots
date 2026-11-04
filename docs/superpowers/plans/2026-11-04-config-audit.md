# ~/.config audit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every kept `~/.config/<app>` is a folder link to `config/<app>`; secret files in it are committed SOPS-encrypted; everything else not in the repo is removed (moved aside when non-empty).

**Architecture:** Repo side: per-app folders under `config/` with a `.gitignore` for local state, one `dotfiles.toml` link per app, folder-wide `.sops.yaml` + `.gitattributes` rules for secret apps, and a re-smudge step in `setup:git:filters` so new machines decrypt SOPS files. Machine side: a one-off removal on this Mac now, and a link switch per app after the merge.

**Tech Stack:** bash (mise tasks), SOPS + age (existing `script/clean.sops.sh` / `smudge.sops.sh`), Bun `bun:test`, mise dotfiles.

Spec: [`docs/superpowers/specs/2026-11-04-config-audit-design.md`](../specs/2026-11-04-config-audit-design.md) (owner verdicts recorded there).

---

## Ground rules

- Worktree `~/Work/dots-config-audit`, branch `chore/config-audit` (from `origin/main`).
- Git: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }` for read-only commands and for commits
  that touch **no** SOPS file. Commits that add SOPS files (Task 4) must use plain `git` so the real clean filter
  encrypts them; never pass `filter.sops.clean=cat` there.
- Stage named files only; never `git add -A` / `.`. Commit subject ≤ 50 chars, capitalized description.
- **Never print a secret.** Copy secret files with `cp -p`, never `cat` them. Only ciphertext may be printed
  (`git show :<path> | head -c 60`).
- Machine changes in `~/.config`: Task 2 runs now (owner approved the verdicts); the link switch (Task 7) runs only
  after the branch is merged and `~/Work/dots` is pulled, because `~/.local/share/dots` → `~/Work/dots`.
- No push, no PR.

## File structure

| Path | Change | Responsibility |
| --- | --- | --- |
| `mise.toml` (`setup:git:filters`) | Modify | Re-smudge `filter=sops` files right after configuring the filter |
| `test/integration/bootstrap/sops-resmudge.spec.ts` | Create | Fresh clone: ciphertext before, plaintext (0600) after the snippet |
| `config/{zed,zentty,dprint,posting,gortex}/` | Create | Ported plain configs + `.gitignore` for state |
| `config/{gopass,gh,wakatime}/` | Create | Ported configs; secret files SOPS-encrypted |
| `.sops.yaml`, `.gitattributes` | Modify | Folder-wide rules for gopass, gh, wakatime |
| `config/mise/conf.d/dotfiles.toml` | Modify | One folder link per ported app |
| `config/mise/config.toml` | Modify | Drop the `~/.config/gopass` history track entry |
| `docs/REINSTALL.md` | Modify | gopass now lives in `config/gopass`; secrets-in-repo note |

---

### Task 0: Baseline

- [ ] `cd ~/Work/dots-config-audit && hk check` (clean) and, per domain, `cd test && bun test integration/<d>` for
  `backup bootstrap agents hooks bin` — write the counts down. Known: up to 3 `xc-git fixup-suggest` failures in
  `bin` (they depend on branch history).
- [ ] Confirm the SOPS filter is configured for this repo (worktrees share `.git/config`):
  `git config --get filter.sops.clean` prints `script/clean.sops.sh %f`, and `~/.config/sops/age/keys.txt` exists
  (`test -s`; do not read it). If either is missing: stop and report.

### Task 1: Re-smudge SOPS files on a fresh clone (TDD)

**Files:** create `test/integration/bootstrap/sops-resmudge.spec.ts`; modify `mise.toml` `[tasks."setup:git:filters"]`.

- [ ] **Step 1: Write the failing spec**

```ts
#!/usr/bin/env bun
// setup:git:filters re-checks-out every filter=sops file once the filter exists, so a clone made before the age key
// (as install does) ends up with decrypted files. Throwaway key and repo only.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "mise.toml"), "utf8")) as {
  tasks: Record<string, { run: string }>;
}).tasks["setup:git:filters"].run;
const SNIPPET = task.match(/# sops-resmudge: begin\n[\s\S]*?# sops-resmudge: end\n/)?.[0] ?? "";
const tools = ["git", "sops", "age-keygen", "age"].every((c) => Bun.which(c) !== null);

let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "sops-resmudge-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));

describe("setup:git:filters re-smudge", () => {
  it("is in the task, inside the configure branch", () => {
    expect(SNIPPET).toContain(":(attr:filter=sops)");
    expect(task.indexOf("# sops-resmudge: begin")).toBeGreaterThan(task.indexOf("git config --local filter.sops.clean"));
  });

  it.skipIf(!tools)("decrypts files a pre-filter clone left encrypted, mode 0600", () => {
    const cfg = join(t, "xdg");
    mkdirSync(join(cfg, "sops", "age"), { recursive: true });
    const key = join(cfg, "sops", "age", "keys.txt");
    Bun.spawnSync(["age-keygen", "-o", key], { stderr: "ignore" });
    const pub = Bun.spawnSync(["age-keygen", "-y", key]).stdout.toString().trim();
    const env = {
      PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, XDG_CONFIG_HOME: cfg, SOPS_AGE_KEY_FILE: key,
      GIT_CONFIG_GLOBAL: join(t, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1",
    };
    writeFileSync(env.GIT_CONFIG_GLOBAL, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n[init]\n  defaultBranch = main\n");
    const sh = (cwd: string, cmd: string) =>
      Bun.spawnSync(["bash", "-c", cmd], { cwd, env, stdout: "pipe", stderr: "pipe", timeout: 30_000 });

    const a = join(t, "a");
    mkdirSync(join(a, "script"), { recursive: true });
    mkdirSync(join(a, "secret"));
    for (const f of ["clean.sops.sh", "smudge.sops.sh"]) copyFileSync(join(REPO, "script", f), join(a, "script", f));
    writeFileSync(join(a, ".sops.yaml"), `creation_rules:\n  - path_regex: 'secret/.*'\n    age: ${pub}\n`);
    writeFileSync(join(a, ".gitattributes"), "secret/** filter=sops diff=sops\n");
    writeFileSync(join(a, "secret", "blob"), "plain-text-value\n");
    const setup = "git config --local filter.sops.smudge 'script/smudge.sops.sh %f' && git config --local filter.sops.required true && git config --local filter.sops.clean 'script/clean.sops.sh %f'";
    expect(sh(a, `git init -q && ${setup} && git add -A && git commit -q -m init`).exitCode).toBe(0);
    expect(sh(a, "git show HEAD:secret/blob").stdout.toString()).toContain("ENC[");

    // Clone without the filter (as install does), then configure it and run the snippet.
    const b = join(t, "b");
    expect(sh(t, `git clone -q ${a} ${b}`).exitCode).toBe(0);
    expect(readFileSync(join(b, "secret", "blob"), "utf8")).toContain("ENC[");
    const r = sh(b, `${setup}\n${SNIPPET}`);
    expect(r.exitCode).toBe(0);
    expect(readFileSync(join(b, "secret", "blob"), "utf8")).toBe("plain-text-value\n");
    expect(statSync(join(b, "secret", "blob")).mode & 0o077).toBe(0);
    expect(sh(b, "git status --porcelain").stdout.toString()).toBe("");
  });
});
```

- [ ] **Step 2:** `cd test && bun test integration/bootstrap/sops-resmudge.spec.ts` → FAIL (snippet empty).
- [ ] **Step 3: Add the snippet** inside the `if` block of `[tasks."setup:git:filters"]` in `mise.toml`, directly
  after `git config --local diff.sops.command "script/smudge.sops.sh %f"` and before `echo "✓ Git filters configured"`:

```bash
  # sops-resmudge: begin
  # install clones before the age key exists, so filter=sops files were checked out encrypted: check them out
  # again through the filter now, and make the decrypted secrets private.
  git ls-files -z ':(attr:filter=sops)' | while IFS= read -r -d '' f; do
    rm -f -- "$f" && git checkout -- "$f" && chmod go-rwx -- "$f"
  done
  # sops-resmudge: end
```

- [ ] **Step 4:** run the spec again → 2 pass. If `git status --porcelain` is not empty (index stat mismatch),
  add `git update-index -q --refresh` after the loop inside the markers and rerun.
- [ ] **Step 5:** `hk check` (taplo), then commit (no SOPS file touched):

```bash
g add mise.toml test/integration/bootstrap/sops-resmudge.spec.ts
g commit -m "fix(git): Decrypt SOPS files after filter setup" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Remove (machine, this Mac)

No repo change. Spec §3.1, §3.2, §3.3, §3.6.

- [ ] **Step 1: Dry run** — print what would happen, change nothing:

```bash
cd ~/.config
aside="$HOME/.local/state/dots/config-aside-$(date +%Y%m%d)"
links="amethyst bunfig.toml cursor glide ranma rift skhd starship tealdeer"
empty="act crewai crush devin firebase obsidian rclone swiftpm"
moves=".agents skills-lock.json .DS_Store .rz .semgrep acli aegis amp AWSVPNClient cagent configstore crossnote gcloud ghostex gitlint graphite karabiner KiwiDesk macterm marp nx openspec presenterm puppeter reveal-md sketchybar vicinae goose"
for e in $links; do [ -L "$e" ] && [ ! -e "$e" ] && echo "rm link  $e" || echo "SKIP link $e (not a broken link)"; done
for e in $empty; do [ -d "$e" ] && [ -z "$(ls -A "$e")" ] && echo "rmdir    $e" || echo "SKIP dir  $e (missing or not empty)"; done
for e in $moves; do [ -e "$e" ] && echo "mv       $e -> $aside/" || echo "SKIP mv   $e (missing)"; done
```

Expected: no `SKIP` lines. Any `SKIP`: stop and report it (something changed since the audit).

- [ ] **Step 2: Apply** (same variables):

```bash
mkdir -p "$aside" && chmod 700 "$aside"
for e in $links; do [ -L "$e" ] && [ ! -e "$e" ] && rm -- "$e"; done
for e in $empty; do [ -d "$e" ] && [ -z "$(ls -A "$e")" ] && rmdir -- "$e"; done
for e in $moves; do [ -e "$e" ] && mv -- "$e" "$aside/"; done
ls -A ~/.config
```

Expected `ls -A`: the repo links, `gnupg`, `gopass`, `ssh`, `.fallow`, `github-copilot`, and the apps still to
port: `dprint gh gortex posting wakatime zed zentty`. Report the list.

### Task 3: Port the plain configs (one commit per app)

**Files:** `config/<app>/…`, `config/<app>/.gitignore` (only where state exists), `config/mise/conf.d/dotfiles.toml`.

For each row, in order: copy into the worktree, add the `.gitignore`, add the link line to `dotfiles.toml`
(alphabetical among the `"~/.config/…"` entries), `hk check`, commit. The real `~/.config/<app>` is **not** touched
here (Task 7).

| App | Copy | `.gitignore` (state that stays local) |
| --- | --- | --- |
| `dprint` | `dprint.jsonc` | — |
| `gortex` | `config.yaml` | — |
| `posting` | `config.yaml` | `posting/` (inspect: if it holds hand-written collections, report instead of ignoring) |
| `zed` | `settings.json`, `keymap.json` | `conversations/`, `prompts/`, `themes/`, `keymap_backup.json` |
| `zentty` | `config.toml`, `bookmarks.json` | `restore-*.json`, `run/` |

- [ ] **Step per app** (example `zed`; repeat with each row's files):

```bash
cd ~/Work/dots-config-audit
mkdir -p config/zed
cp -p ~/.config/zed/settings.json ~/.config/zed/keymap.json config/zed/
printf '%s\n' '# Local state of the app; only the config files above are versioned.' 'conversations/' 'prompts/' 'themes/' 'keymap_backup.json' > config/zed/.gitignore
```

Add to `config/mise/conf.d/dotfiles.toml`:

```toml
"~/.config/zed" = { source = "~/.local/share/dots/config/zed", relative = true }
```

(likewise `dprint`, `gortex`, `posting`, `zentty`: `"~/.config/<app>" = { source = "~/.local/share/dots/config/<app>", relative = true }`).

```bash
hk check
g add config/zed/settings.json config/zed/keymap.json config/zed/.gitignore config/mise/conf.d/dotfiles.toml
g commit -m "feat(zed): Track the Zed settings in dots" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Before each commit, read the staged diff (`g diff --cached`) for anything secret-looking (tokens, keys, emails you
would not publish). Found one: stop and report; the file moves to Task 4 instead.

### Task 4: Port the secret configs (SOPS-encrypted)

**Files:** `.sops.yaml`, `.gitattributes`, `config/{gopass,gh,wakatime}/…`, `dotfiles.toml`, `config/mise/config.toml`.

- [ ] **Step 1: Rules** — append to `.sops.yaml` `creation_rules` (same recipient as the existing rules):

```yaml
  - path_regex: '(^|/)config/gopass/age/.*$'
    age: age17q0hc40w3zukdw47zagn5f0rj72ggcu5ygxxpekpua6x3trp6q0syn9lt4
  - path_regex: '(^|/)config/gh/hosts\.yml$'
    age: age17q0hc40w3zukdw47zagn5f0rj72ggcu5ygxxpekpua6x3trp6q0syn9lt4
  - path_regex: '(^|/)config/wakatime/\.wakatime\.cfg$'
    age: age17q0hc40w3zukdw47zagn5f0rj72ggcu5ygxxpekpua6x3trp6q0syn9lt4
```

and to `.gitattributes`:

```text
config/gopass/age/** filter=sops diff=sops
config/gh/hosts.yml filter=sops diff=sops
config/wakatime/.wakatime.cfg filter=sops diff=sops
```

Commit these two files alone first (`g add .sops.yaml .gitattributes`; subject `chore(sops): Encrypt gopass, gh and wakatime`).

- [ ] **Step 2: gopass**

```bash
mkdir -p config/gopass/age
cp -p ~/.config/gopass/config config/gopass/config
cp -p ~/.config/gopass/age/config ~/.config/gopass/age/identities config/gopass/age/
printf '%s\n' '# fallow cache' '.fallow/' > config/gopass/.gitignore
git add config/gopass/config config/gopass/.gitignore config/gopass/age/config config/gopass/age/identities
# Both age/ files must be ciphertext in the index:
for f in config/gopass/age/config config/gopass/age/identities; do git show ":$f" | head -c 40; echo; done
```

Expected: each starts with `{` and contains `"data": "ENC[`. Anything else: `git restore --staged` the files and
stop. Then the round-trip check: `git show :config/gopass/age/identities | SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops decrypt --filename-override config/gopass/age/identities /dev/stdin | cmp - ~/.config/gopass/age/identities && echo identical`.

Add the link and drop the history entry:

```toml
# config/mise/conf.d/dotfiles.toml
"~/.config/gopass" = { source = "~/.local/share/dots/config/gopass", relative = true }
```

In `config/mise/config.toml`, delete the two lines:

```toml
# gopass's age identity keyring (locked to the age key: docs/REINSTALL.md); the store is a git clone the bootstrap task makes.
"~/.config/gopass" = { mode = "track", encrypt = true }
```

```bash
git add config/mise/conf.d/dotfiles.toml config/mise/config.toml
git commit -m "feat(gopass): Keep the gopass config in dots" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(plain `git`: the clean filter must run.)

- [ ] **Step 3: gh** — `mkdir -p config/gh && cp -p ~/.config/gh/config.yml ~/.config/gh/hosts.yml config/gh/`;
  `git add` both; `git show :config/gh/hosts.yml | head -c 60` shows `ENC[` values (YAML keys stay readable);
  round-trip check as above with `cmp - ~/.config/gh/hosts.yml`; link line `"~/.config/gh" = …`; commit
  `feat(gh): Keep the gh config in dots`.
- [ ] **Step 4: wakatime** — `mkdir -p config/wakatime && cp -p ~/.config/wakatime/.wakatime.cfg config/wakatime/`;
  `.gitignore`:

```text
# Local state; only .wakatime.cfg (SOPS-encrypted) is versioned.
.wakatime/
ai-sqlite
offline_heartbeats.bdb
wakatime-internal.cfg
wakatime.log
```

  `git add` both; ciphertext check; round-trip check; link line; commit `feat(wakatime): Keep the wakatime config in dots`.
- [ ] **Step 5:** `git log -p origin/main.. -- config/gopass config/gh config/wakatime | rg -n 'gho_|api_key|AGE-SECRET|BEGIN .*PRIVATE'`
  must print nothing.

### Task 5: Docs and the dotfiles.toml comment

- [ ] `config/mise/conf.d/dotfiles.toml` line 41 comment: `# ~/.config/ssh and ~/.config/gnupg are real folders: synced encrypted by mise dot history (config.toml). Everything else in ~/.config links into config/; secret files there are SOPS-encrypted (.sops.yaml).`
- [ ] `docs/REINSTALL.md` "One secret: the age key": replace "The backup goes outside `~/.config/gopass`, which the history tracks:" with "The backup goes outside `config/gopass` (linked from `~/.config/gopass`):", and replace the step `mise dot save && mise dot sync                                # the history carries it to every machine` with `cd ~/Work/dots && git add config/gopass && git commit -m "chore(gopass): Lock the keyring to the age key"   # SOPS encrypts age/`.
- [ ] `docs/REINSTALL.md` §2 table row **Secrets and keys**: `` `dots-history` via age key | Encrypted repository holding SSH and GPG keys; gopass, gh and wakatime secrets are SOPS-encrypted in this repo (`config/<app>`). ``
- [ ] `hk check`; commit `docs: Describe configs linked from config/`.

### Task 6: Verification

- [ ] Per-domain specs as in Task 0: counts + 2 new (`sops-resmudge`), no new failures.
- [ ] `hk check` clean.
- [ ] `g diff --stat origin/main..`: only the files in the file-structure table, the spec and this plan.
- [ ] `git ls-files config/gopass config/gh config/wakatime` lists only the ported files (no state).
- [ ] Report commits, counts vs Task 0, the Task 2 `ls -A` output, and anything stopped or skipped.

### Task 7: Link switch (owner, after merge; on each machine)

On this Mac, after the PR is merged and `cd ~/Work/dots && git pull`:

```bash
cd ~/.config
aside="$HOME/.local/state/dots/config-aside-$(date +%Y%m%d)-port"; mkdir -p "$aside"; chmod 700 "$aside"
# A broken leftover link inside posting/ (not app state): drop it so rsync does not copy it into the repo.
[ -L posting/posting ] && [ ! -e posting/posting ] && rm posting/posting
# Folders holding decrypted secrets: owner-only, so later pulls (written with the umask) stay private.
chmod 700 ~/Work/dots/config/gopass/age ~/Work/dots/config/wakatime
chmod 600 ~/Work/dots/config/gopass/age/* ~/Work/dots/config/wakatime/.wakatime.cfg
for app in dprint gh gopass gortex posting wakatime zed zentty; do
  [ -L "$app" ] && continue
  # Local state (git-ignored in config/<app>) moves into the linked folder; versioned files are already there.
  rsync -a --ignore-existing "$app/" "$HOME/.local/share/dots/config/$app/"
  mv "$app" "$aside/"
done
mise dot apply          # creates the folder links
for app in dprint gh gopass gortex posting wakatime zed zentty; do printf '%-9s %s\n' "$app" "$([ -L "$app" ] && echo link || echo NOT-A-LINK)"; done
gopass show -o tokens/age.dots.github.com </dev/null >/dev/null && echo "gopass ok"
gh auth status >/dev/null 2>&1 && echo "gh ok"
cd ~/Work/dots && git status --short   # must be empty: apps did not rewrite tracked files
```

Other machines (e.g. the Ubuntu VM): `git pull` in the dots checkout. Where the SOPS filter is already configured,
the pull decrypts new files itself; if any SOPS file is still ciphertext (`head -c 20 config/gopass/age/identities`
shows `{`), force the re-smudge: `git config --local --unset filter.sops.clean && mise run setup:git:filters`.
Then the same block. `gh` keeps each machine's own `hosts.yml` (git-ignored): run `gh auth login` there if
`gh auth status` fails. Delete the `config-aside-*` folders after a few weeks.

The old `~/.config/gopass` checkpoints stay in the private dots-history (encrypted, no longer updated); the track
entry is gone, so nothing restores them.
