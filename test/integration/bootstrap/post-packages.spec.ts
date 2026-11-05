#!/usr/bin/env bun
// The post-packages hook in config/mise/conf.d/bootstrap.toml, run against a stub `brew`:
// the core group is fatal, the rest of the Brewfile only warns (unless CI or DOTS_STRICT).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const config = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
  bootstrap: { hooks: { "post-packages": { run: string } } };
  tasks: { bootstrap: { run: string } };
};
const HOOK = config.bootstrap.hooks["post-packages"].run;

// Fails `brew bundle install` for the profiles listed in STUB_FAIL, printing brew's real failure lines.
const STUB = `#!/bin/sh
case "$1" in
  shellenv|cleanup) exit 0 ;;
  bundle)
    echo "$HOMEBREW_DOTS_PROFILE $HOMEBREW_BUNDLE_FILE" >> "$STUB_LOG"
    case ",$STUB_FAIL," in
      *",$HOMEBREW_DOTS_PROFILE,"*)
        echo "Installing com.discordapp.Discord has failed!"
        echo "Tapping can1357/tap has failed!"
        echo "\\\`brew bundle\\\` failed! 2 Brewfile dependencies failed to install"
        exit 1 ;;
    esac
    exit 0 ;;
esac
exit 0
`;

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "post-packages-"));
  mkdirSync(join(t, "bin"));
  writeFileSync(join(t, "bin", "brew"), STUB);
  chmodSync(join(t, "bin", "brew"), 0o755);
  writeFileSync(join(t, "hook.sh"), HOOK);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const state = () => join(t, "state", "dots");
const calls = () => readFileSync(join(t, "calls"), "utf8").trim().split("\n");

function hook(env: Record<string, string>) {
  const p = Bun.spawnSync(["bash", join(t, "hook.sh")], {
    env: {
      PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, XDG_STATE_HOME: join(t, "state"),
      HOMEBREW_BUNDLE_FILE: join(t, "Brewfile"), STUB_LOG: join(t, "calls"), ...env,
    },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe("post-packages hook", () => {
  it("desktop: installs the core group, then the full Brewfile", () => {
    const r = hook({ MISE_ENV: "desktop" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`, `desktop ${join(t, "Brewfile")}`]);
    expect(existsSync(join(state(), "brew-bundle.failed"))).toBe(false);
  });

  it("desktop: a failed entry warns, names it and records it, but exits 0", () => {
    const r = hook({ MISE_ENV: "desktop", STUB_FAIL: "desktop" });
    expect(r.code).toBe(0);
    expect(r.err).toContain("WARNING: brew bundle could not install: can1357/tap com.discordapp.Discord");
    expect(r.err).toContain("retry: brew bundle install");
    expect(readFileSync(join(state(), "brew-bundle.failed"), "utf8")).toBe("can1357/tap com.discordapp.Discord\n");
    expect(readFileSync(join(state(), "brew-bundle.log"), "utf8")).toContain("has failed!");
  });

  it("desktop: a later clean run clears the recorded failure", () => {
    hook({ MISE_ENV: "desktop", STUB_FAIL: "desktop" });
    expect(hook({ MISE_ENV: "desktop" }).code).toBe(0);
    expect(existsSync(join(state(), "brew-bundle.failed"))).toBe(false);
  });

  it("CI or DOTS_STRICT makes a failed entry fatal", () => {
    for (const strict of [{ CI: "true" }, { DOTS_STRICT: "1" }]) {
      const r = hook({ MISE_ENV: "desktop", STUB_FAIL: "desktop", ...strict });
      expect(r.code).toBe(1);
      expect(r.err).toContain("brew bundle failed: can1357/tap com.discordapp.Discord");
    }
  });

  it("a failure in the core group stops the bootstrap before the full Brewfile", () => {
    const r = hook({ MISE_ENV: "desktop", STUB_FAIL: "container" });
    expect(r.code).not.toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`]);
  });

  it("container: installs only the core group", () => {
    const r = hook({ MISE_ENV: "container" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`]);
  });
});

describe("bootstrap task reminder", () => {
  // The lines from `failed_file=` to `trap remind EXIT`, run with a trivial body.
  const snippet = config.tasks.bootstrap.run.match(/failed_file=[\s\S]*?trap remind EXIT\n/)?.[0] ?? "";

  it("is present", () => expect(snippet).toContain("trap remind EXIT"));

  it("repeats the recorded failure at exit, keeping the exit code", () => {
    mkdirSync(state(), { recursive: true });
    writeFileSync(join(state(), "brew-bundle.failed"), "com.discordapp.Discord\n");
    const p = Bun.spawnSync(["bash", "-c", `${snippet}exit 3`], {
      env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state") }, stderr: "pipe",
    });
    expect(p.exitCode).toBe(3);
    expect(p.stderr.toString()).toContain("bootstrap: brew bundle could not install: com.discordapp.Discord");
  });

  it("stays quiet when nothing failed", () => {
    const p = Bun.spawnSync(["bash", "-c", `${snippet}exit 0`], {
      env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state") }, stderr: "pipe",
    });
    expect(p.exitCode).toBe(0);
    expect(p.stderr.toString()).toBe("");
  });
});

describe("Homebrew install needs sudo", () => {
  // The lines between `# brew-sudo: begin` and `# brew-sudo: end`, run with stub id/sudo and no terminal.
  const snippet = HOOK.match(/# brew-sudo: begin\n[\s\S]*?# brew-sudo: end\n/)?.[0] ?? "";
  const runSnippet = (sudoOk: boolean, detach = false) => {
    writeFileSync(join(t, "bin", "id"), "#!/bin/sh\necho 501\n");
    writeFileSync(join(t, "bin", "sudo"), `#!/bin/sh\necho "sudo $*" >> "${join(t, "sudo.log")}"\nexit ${sudoOk ? 0 : 1}\n`);
    for (const n of ["id", "sudo"]) chmodSync(join(t, "bin", n), 0o755);
    // setsid detaches from the terminal, so /dev/tty is unavailable (the no-terminal case).
    const p = Bun.spawnSync([...(detach ? ["setsid"] : []), "bash", "-c", `${snippet}echo AFTER`], {
      env: { PATH: `${join(t, "bin")}:/usr/bin:/bin` }, stdin: "ignore", stdout: "pipe", stderr: "pipe",
    });
    return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
  };

  it("is in the hook, before the installer", () => {
    expect(snippet).toContain("sudo -n true");
    expect(HOOK.indexOf("# brew-sudo: end")).toBeLessThan(HOOK.indexOf("NONINTERACTIVE=1 /bin/bash"));
  });

  it("goes on when a sudo ticket already exists (Linux, after apt)", () => {
    const r = runSnippet(true);
    expect(r.code).toBe(0);
    expect(r.out).toContain("AFTER");
  });

  it.skipIf(!Bun.which("setsid"))("without a ticket or a terminal, stops with what to run", () => {
    const r = runSnippet(false, true);
    expect(r.code).toBe(1);
    expect(r.out).not.toContain("AFTER");
    expect(r.err).toContain("run 'sudo -v', then mise bootstrap");
  });
});
