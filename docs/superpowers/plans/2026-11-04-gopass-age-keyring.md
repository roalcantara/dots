# gopass unlocked by the bootstrap age key — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One secret per machine: the bootstrap age key (`config/age/keys.txt`) also unlocks the gopass identity keyring, so `gopass show` never prompts for a PIN on macOS, Linux or containers.

**Architecture:** gopass ≥ 1.17 can encrypt its identity keyring to age recipients (`age.keyring-recipients`) and unlock it with a plaintext identity file (`age.keyring-identities`). The owner switches once on the Mac; the mise history (which tracks `~/.config/gopass`) carries the result to every machine. The repo adds a warn-only bootstrap check, docs, and tests.

**Tech Stack:** bash (mise task), Bun `bun:test`, gopass, age, expect (E2E only).

Spec: [`docs/superpowers/specs/2026-11-04-gopass-age-keyring-design.md`](../specs/2026-11-04-gopass-age-keyring-design.md).

---

## Ground rules

- Worktree: `~/Work/dots-gopass`, branch `feat/gopass-age-keyring` (based on `origin/main`).
- Every git command needs the SOPS bypass: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`.
- Stage named files only; never `git add -A` / `git add .`.
- Until `fix/hk-drop-global-rules` is merged, the live global hk config still runs commit-message rules that need `cog`; commit with `mise exec cocogitto@7.0.0 -- git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit …`. Subject ≤ 50 chars, capitalized description, body lines ≤ 72.
- Never touch real secrets: no `gopass show` of real entries, no reading `config/age/keys.txt`. Tests use throwaway `HOME`s.
- Do not push or open a PR.

## File structure

| File | Change | Responsibility |
| --- | --- | --- |
| `config/mise/conf.d/bootstrap.toml` | Modify (bootstrap task, after the gopass store clone) | Warn-only keyring check between `# gopass-keyring: begin` / `end` |
| `test/integration/bootstrap/gopass-keyring.spec.ts` | Create | Snippet behavior with a stub `gopass`; E2E switch with real tools (skipped if absent) |
| `docs/REINSTALL.md` | Modify (§7 end, §12 table) | "One secret: the age key" section; PIN troubleshooting row |
| `docs/GLOSSARY.md` | Modify (table end) | *Keyring recipient*, *Keyring identity*, *Recovery key* |
| `config/mise/config.toml:128` | Modify | Comment no longer claims a passphrase |

---

### Task 0: Baseline

- [x] **Step 1:** In `~/Work/dots-gopass`, run `MISE_AUTO_INSTALL=0 mise run test:specs 2>&1 | grep -E '^\s*[0-9]+ (pass|fail)|scenarios'` and `hk check`; write the counts down.
  Known pre-existing: up to 3 `xc-git > fixup-suggest` failures (they depend on the real repo's branch history and also fail on a clean `main`). Anything else failing: stop and report.

### Task 1: Bootstrap keyring check (TDD)

**Files:** Create `test/integration/bootstrap/gopass-keyring.spec.ts`; modify `config/mise/conf.d/bootstrap.toml`.

- [x] **Step 1: Write the failing spec**

```ts
#!/usr/bin/env bun
// The gopass-keyring check in the bootstrap task (config/mise/conf.d/bootstrap.toml): warns when the gopass
// identity keyring still uses a passphrase, or when its unlock file is missing; never fails the bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
  tasks: { bootstrap: { run: string } };
}).tasks.bootstrap.run;
const SNIPPET = task.match(/# gopass-keyring: begin\n[\s\S]*?# gopass-keyring: end\n/)?.[0] ?? "";

const SCRYPT = "age-encryption.org/v1\n-> scrypt eJReM2BS 18\nabc\n";
const X25519 = "age-encryption.org/v1\n-> X25519 biNcMGIhZRmsV0kIarefRzAg\nabc\n";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "gopass-keyring-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, ".config", "gopass", "age"), { recursive: true });
  // Stub gopass: `gopass config age.keyring-identities` prints $STUB_KID.
  writeFileSync(join(t, "bin", "gopass"), '#!/bin/sh\n[ "$1 $2" = "config age.keyring-identities" ] && printf "%s\\n" "$STUB_KID"\nexit 0\n');
  chmodSync(join(t, "bin", "gopass"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(identities: string | null, env: Record<string, string> = {}) {
  if (identities !== null) writeFileSync(join(t, ".config", "gopass", "age", "identities"), identities);
  const p = Bun.spawnSync(["bash", "-c", `${SNIPPET}echo done`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe("bootstrap gopass-keyring check", () => {
  it("is in the bootstrap task, after the store clone", () => {
    expect(SNIPPET).toContain("age.keyring-identities");
    expect(task.indexOf("# gopass-keyring: begin")).toBeGreaterThan(task.indexOf("pass-store.git"));
  });

  it("warns when the keyring still uses a passphrase, and continues", () => {
    const r = snippet(SCRYPT);
    expect(r.code).toBe(0);
    expect(r.out).toContain("done");
    expect(r.err).toContain("gopass keyring still uses a passphrase");
    expect(r.err).toContain("docs/REINSTALL.md#one-secret-the-age-key");
  });

  it("is silent when the keyring is locked to an existing key file (~ expanded)", () => {
    mkdirSync(join(t, ".config", "age"), { recursive: true });
    writeFileSync(join(t, ".config", "age", "keys.txt"), "AGE-SECRET-KEY-1TEST\n");
    const r = snippet(X25519, { STUB_KID: "~/.config/age/keys.txt" });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
  });

  it("warns when the unlock file is missing", () => {
    const r = snippet(X25519, { STUB_KID: "~/.config/age/keys.txt" });
    expect(r.code).toBe(0);
    expect(r.err).toContain(`gopass keyring identity file missing: ${join(t, ".config/age/keys.txt")}`);
  });

  it("does nothing without gopass or without an identities file", () => {
    expect(snippet(null).err).toBe("");
    rmSync(join(t, "bin", "gopass"));
    expect(snippet(SCRYPT).err).toBe("");
  });
});
```

- [x] **Step 2: Run it, expect failures**

Run: `cd test && bun test integration/bootstrap/gopass-keyring.spec.ts`
Expected: FAIL (`SNIPPET` is empty: "is in the bootstrap task" and the warning tests fail).

- [x] **Step 3: Add the snippet** in `config/mise/conf.d/bootstrap.toml`, directly after the `fi` that closes the gopass store clone block (the `clone https://github.com/roalcantara/pass-store.git` lines) and before `# oMLX models`:

```sh
# gopass-keyring: begin
# gopass's identity keyring should be locked to the age key (docs/REINSTALL.md, "One secret: the age key"),
# so gopass never asks for a PIN. Only warns: the switch is interactive and done once by the owner.
ids="$HOME/.config/gopass/age/identities"
if command -v gopass >/dev/null && [ -s "$ids" ]; then
  if head -n 3 "$ids" | grep -q -- '-> scrypt'; then
    echo "bootstrap: gopass keyring still uses a passphrase; switch it to the age key: see docs/REINSTALL.md#one-secret-the-age-key" >&2
  else
    kid="$(gopass config age.keyring-identities 2>/dev/null || true)"
    kid="${kid/#\~/$HOME}"
    [ -z "$kid" ] || [ -s "$kid" ] || echo "bootstrap: gopass keyring identity file missing: $kid" >&2
  fi
fi
# gopass-keyring: end
```

- [x] **Step 4: Run the spec, expect PASS**

Run: `cd test && bun test integration/bootstrap/gopass-keyring.spec.ts`
Expected: 5 pass, 0 fail. Then `cd test && bun test integration/bootstrap` (all bootstrap specs still pass) and `hk check` (taplo clean).

- [x] **Step 5: Commit**

```bash
g add config/mise/conf.d/bootstrap.toml test/integration/bootstrap/gopass-keyring.spec.ts
mise exec cocogitto@7.0.0 -- git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit -m "feat(bootstrap): Warn on a passphrase gopass keyring" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: End-to-end switch spec (real gopass, skipped if absent)

**Files:** Modify `test/integration/bootstrap/gopass-keyring.spec.ts` (append).

This replays the 2026-11-04 container run (spec §3) in a throwaway `HOME`. It needs `gopass`, `age-keygen`, `expect` and `git` on PATH; otherwise it is skipped. It must never see the real `~/.config/gopass` or the Keychain: it builds a fresh env (so `GOPASS_CONFIG`, `GOPASS_CONFIG_HOME`, `GOPASS_HOMEDIR` never leak in), points every XDG dir into the temp dir, and runs with a PATH of only those four tools plus `/usr/bin:/bin`, so no pinentry can run. Every call has a 30 s timeout. Also add `symlinkSync` to the spec's `node:fs` import: `import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";`.

- [x] **Step 1: Append the spec**

```ts
const tools = ["gopass", "age-keygen", "expect", "git"].every((c) => Bun.which(c) !== null);

describe.skipIf(!tools)("gopass keyring switch (end to end)", () => {
  it("after reencrypt, gopass decrypts with no tty and no passphrase; without the key it fails", () => {
    const h = mkdtempSync(join(tmpdir(), "gopass-e2e-"));
    // Only the four tools, never pinentry: pinentry-mac could open a dialog or write a Keychain item named
    // like the real one (GnuPG / pass/age-identities). /usr/bin and /bin have no pinentry.
    mkdirSync(join(h, "bin"));
    for (const c of ["gopass", "age-keygen", "expect", "git"]) symlinkSync(Bun.which(c) as string, join(h, "bin", c));
    const env: Record<string, string> = {
      PATH: `${join(h, "bin")}:/usr/bin:/bin`, HOME: h, XDG_CONFIG_HOME: join(h, ".config"),
      XDG_DATA_HOME: join(h, ".local/share"), XDG_CACHE_HOME: join(h, ".cache"), XDG_RUNTIME_DIR: join(h, "run"),
      GOPASS_NO_NOTIFY: "true", GIT_CONFIG_GLOBAL: join(h, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1", TERM: "dumb",
    };
    // A fresh env (not process.env), so GOPASS_CONFIG / GOPASS_CONFIG_HOME / GOPASS_HOMEDIR never leak in.
    const sh = (cmd: string, extra: Record<string, string> = {}) =>
      Bun.spawnSync(["bash", "-c", cmd], {
        env: { ...env, ...extra }, stdin: "ignore", stdout: "pipe", stderr: "pipe", timeout: 30_000,
      });
    try {
      mkdirSync(env.XDG_RUNTIME_DIR as string, { recursive: true, mode: 0o700 });
      writeFileSync(env.GIT_CONFIG_GLOBAL as string, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n");
      const pass = { GOPASS_AGE_PASSWORD: "lab-pass-123" };

      expect(sh("gopass setup --crypto age --storage fs --name T --email t@example.com", pass).exitCode).toBe(0);
      expect(sh("echo the-secret-value | gopass insert -f tokens/demo", pass).exitCode).toBe(0);
      expect(sh("head -n 2 ~/.config/gopass/age/identities").stdout.toString()).toContain("-> scrypt");

      expect(sh("mkdir -p ~/.config/age && (umask 077; age-keygen -o ~/.config/age/keys.txt)").exitCode).toBe(0);
      expect(sh("gopass config age.keyring-identities '~/.config/age/keys.txt'").exitCode).toBe(0);
      expect(sh('gopass config age.keyring-recipients "$(age-keygen -y ~/.config/age/keys.txt)"').exitCode).toBe(0);
      const exp = [
        "set timeout 30",
        "spawn gopass age identities reencrypt",
        "expect {",
        "  -re {\\[y/N/q\\]} { send \"y\\r\"; exp_continue }",
        "  eof {}",
        "  timeout { exit 9 }",
        "}",
        "catch wait r",
        "exit [lindex $r 3]",
      ].join("\n");
      writeFileSync(join(h, "re.exp"), exp);
      expect(sh(`expect ${join(h, "re.exp")}`, pass).exitCode).toBe(0);
      expect(sh("head -n 2 ~/.config/gopass/age/identities").stdout.toString()).toContain("-> X25519");

      sh("gopass config age.agent-enabled false");
      const after = sh("gopass show -o tokens/demo");
      expect(after.exitCode).toBe(0);
      expect(after.stdout.toString().trim()).toBe("the-secret-value");

      sh("mv ~/.config/age/keys.txt ~/keys.moved");
      expect(sh("gopass show -o tokens/demo").exitCode).not.toBe(0);
    } finally {
      sh("gopass age agent stop >/dev/null 2>&1; true");
      rmSync(h, { recursive: true, force: true });
    }
  }, 120_000);
});
```

- [x] **Step 2: Run it**

Run: `cd test && bun test integration/bootstrap/gopass-keyring.spec.ts`
Expected on this Mac (gopass and age installed; `expect` ships with macOS at `/usr/bin/expect`): 6 pass, 0 fail. If `gopass setup` fails because it tries to reach the real store, print `sh(...).stderr` and fix the env isolation (add the missing `GOPASS_*` variable pointing into `h`), never point it at the real home.
Confirm isolation afterwards: `ls -la ~/.config/gopass/age/identities` has the same mtime as before the run.

- [x] **Step 3: Commit**

```bash
g add test/integration/bootstrap/gopass-keyring.spec.ts
mise exec cocogitto@7.0.0 -- git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit -m "test(bootstrap): Replay the gopass keyring switch" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: Docs

**Files:** `docs/REINSTALL.md`, `docs/GLOSSARY.md`, `config/mise/config.toml`.

- [x] **Step 1: REINSTALL.md** — append at the end of `## 7. First-time setup` (after step 6's code block, before the `---`):

````markdown
### One secret: the age key

The age key that `install` asks for (`config/age/keys.txt`) decrypts the mise history. gopass's own identity
keyring (`~/.config/gopass/age/identities`) is locked to the same key, so a new machine needs that one secret
and gopass never asks for a PIN. Without this, the keyring has its own passphrase: macOS hides it (pinentry-mac
saved it in the Keychain), Linux asks for it on every `gopass show` and scripts fail with `pinentry error`.

Switch once, on a machine where gopass works (it asks for the old passphrase and to confirm the recipients):

```sh
cp -p ~/.config/gopass/age/identities ~/.config/gopass/age/identities.scrypt.bak
age-keygen                                                    # recovery key: save all of it as a Bitwarden secure note
gopass config age.keyring-identities '~/.config/age/keys.txt'
gopass config age.keyring-recipients "$(age-keygen -y ~/.config/age/keys.txt),<recovery public key age1…>"
gopass age identities reencrypt                               # old passphrase, then y
gopass show -o tokens/age.dots.github.com </dev/null          # prints with no prompt
head -n 2 ~/.config/gopass/age/identities                     # "-> X25519", no longer "-> scrypt"
mise dot save && mise dot sync                                # the history carries it to every machine
```

Delete the backup once a second machine decrypts. The old Keychain item (`GnuPG` / `pass/age-identities`) is no
longer used.

- **Recovery:** if `keys.txt` is lost, write the recovery key from Bitwarden to a `0600` file and run
  `gopass config age.keyring-identities <that file>`; set it back to `~/.config/age/keys.txt` afterwards.
- **Trade-off:** the age key alone now opens gopass. It already decrypts the whole history, gopass keyring
  included, so trust does not change; keep it `0600` on an encrypted disk (FileVault, LUKS).
- **Bootstrap check:** `mise bootstrap` warns while the keyring still uses a passphrase, or when the file named
  by `age.keyring-identities` is missing. It never changes gopass settings.
````

- [x] **Step 2: REINSTALL.md §12** — add a row to the Troubleshooting table, after the `password command failed` row:

```markdown
| `Enter your PIN` from gopass, or `pinentry error` in scripts | The gopass keyring still uses its own passphrase. | Lock it to the age key: [One secret: the age key](#one-secret-the-age-key). |
```

- [x] **Step 3: GLOSSARY.md** — append to the terms table:

```markdown
| **Keyring recipient** | Public age key that gopass's identity keyring is encrypted to (`age.keyring-recipients`): the bootstrap key and the recovery key. |
| **Keyring identity** | Plaintext age key file that unlocks gopass's identity keyring (`age.keyring-identities`): `~/.config/age/keys.txt`. |
| **Recovery key** | Offline age key kept as a Bitwarden secure note; a second keyring recipient for when `keys.txt` is lost. |
```

- [x] **Step 4: config/mise/config.toml:128** — replace the comment line with:

```toml
# gopass's age identity keyring (locked to the age key: docs/REINSTALL.md); the store is a git clone the bootstrap task makes.
```

- [x] **Step 5: Check and commit**

Run: `hk check` (markdownlint, taplo clean) and `rg -n 'one-secret-the-age-key' docs config` (the anchor used by the bootstrap warning exists as `### One secret: the age key`).

```bash
g add docs/REINSTALL.md docs/GLOSSARY.md config/mise/config.toml
mise exec cocogitto@7.0.0 -- git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit -m "docs: Document the age-key unlock for gopass" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: Verification

- [x] **Step 1:** `MISE_AUTO_INSTALL=0 mise run test:specs`: baseline counts + 6 new bootstrap specs, no new failures (the known `xc-git fixup-suggest` ones may now pass, since the branch has commits).
- [x] **Step 2:** `hk check` clean.
- [x] **Step 3:** `g diff --stat origin/main..` lists only the five files from the file-structure table plus this plan and the spec.
- [x] **Step 4:** Report the commits, the counts against Task 0, and anything skipped (e.g. E2E skipped for a missing tool).

### Task 5: Owner steps (not for the agent)

1. Merge `fix/hk-drop-global-rules` first (commits on this Mac need it), then this branch.
2. On the Mac: run the "One secret: the age key" commands; store the recovery key in Bitwarden.
3. On the Ubuntu VM: `mise dot pull` (or re-run `install`), then `gopass show -o tokens/age.dots.github.com </dev/null` prints with no prompt; `mise bootstrap` shows no gopass-keyring warning.
