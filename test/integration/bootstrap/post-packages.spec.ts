#!/usr/bin/env bun
// The post-packages phase: brew/bundle.sh is the Brewfile (core group fatal, the rest only warns), brew/install.sh
// asks for sudo, brew/config-link.sh keeps brew's trust store in the repo.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep, STEPS } from "./step";

const REPO = join(import.meta.dir, "../../..");
const BUNDLE = "brew/bundle.sh";
const INSTALL = "brew/install.sh";
const CONFIG = "brew/config-link.sh";

// Fails `brew bundle install` for the profiles listed in STUB_FAIL, printing brew's real failure lines.
const STUB = `#!/bin/sh
case "$1" in
  shellenv|cleanup) exit 0 ;;
  bundle)
    echo "$HOMEBREW_DOTS_PROFILE $HOMEBREW_BUNDLE_FILE" >> "$STUB_LOG"
    echo "\${XDG_CONFIG_HOME:-unset}" > "$STUB_LOG.xdg"
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
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const state = () => join(t, "state", "dots");
const calls = () => readFileSync(join(t, "calls"), "utf8").trim().split("\n");

function env(extra: Record<string, string> = {}) {
  return {
    PATH: `${join(t, "bin")}:/usr/bin:/bin`,
    HOME: t,
    XDG_STATE_HOME: join(t, "state"),
    HOMEBREW_BUNDLE_FILE: join(t, "Brewfile"),
    STUB_LOG: join(t, "calls"),
    ...extra,
  };
}

const bundle = (extra: Record<string, string> = {}) => runStep(BUNDLE, env(extra));

// The phase order the hook runs: config-link before bundle, so brew sees the linked trust store.
function phase(extra: Record<string, string> = {}) {
  const link = runStep(CONFIG, env(extra));
  return { link, bundle: bundle(extra) };
}

describe("brew/bundle.sh", () => {
  it("desktop: installs the core group, then the full Brewfile", () => {
    const r = bundle({ usage_profile: "desktop" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`, `desktop ${join(t, "Brewfile")}`]);
    expect(existsSync(join(state(), "brew-bundle.failed"))).toBe(false);
  });

  it("desktop: a failed entry warns, names it and records it, but exits 0", () => {
    const r = bundle({ usage_profile: "desktop", STUB_FAIL: "desktop" });
    expect(r.code).toBe(0);
    expect(r.err).toContain("WARNING: brew bundle could not install: can1357/tap com.discordapp.Discord");
    expect(r.err).toContain("retry: brew bundle install");
    expect(readFileSync(join(state(), "brew-bundle.failed"), "utf8")).toBe("can1357/tap com.discordapp.Discord\n");
    expect(readFileSync(join(state(), "brew-bundle.log"), "utf8")).toContain("has failed!");
  });

  it("desktop: a later clean run clears the recorded failure", () => {
    bundle({ usage_profile: "desktop", STUB_FAIL: "desktop" });
    expect(bundle({ usage_profile: "desktop" }).code).toBe(0);
    expect(existsSync(join(state(), "brew-bundle.failed"))).toBe(false);
  });

  it("CI or DOTS_STRICT makes a failed entry fatal", () => {
    for (const strict of [{ CI: "true" }, { DOTS_STRICT: "1" }] as Record<string, string>[]) {
      const r = bundle({ usage_profile: "desktop", STUB_FAIL: "desktop", ...strict });
      expect(r.code).toBe(1);
      expect(r.err).toContain("brew bundle failed: can1357/tap com.discordapp.Discord");
    }
  });

  it("a failure in the core group stops the bootstrap before the full Brewfile", () => {
    const r = bundle({ usage_profile: "desktop", STUB_FAIL: "container" });
    expect(r.code).not.toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`]);
  });

  it("desktop,dev: passes the whole list to the full Brewfile run", () => {
    const r = bundle({ usage_profile: "desktop,dev" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`, `desktop,dev ${join(t, "Brewfile")}`]);
  });

  it("defaults to desktop when usage_profile is unset", () => {
    const r = bundle({});
    expect(r.code).toBe(0);
    expect(calls()[1]).toBe(`desktop ${join(t, "Brewfile")}`);
  });

  it("container: installs only the core group", () => {
    const r = bundle({ usage_profile: "container" });
    expect(r.code).toBe(0);
    expect(calls()).toEqual([`container ${join(t, "Brewfile")}`]);
  });
});

describe("brew/remind.sh", () => {
  it("repeats the recorded failure and always exits 0", () => {
    mkdirSync(state(), { recursive: true });
    writeFileSync(join(state(), "brew-bundle.failed"), "com.discordapp.Discord\n");
    const r = runStep("brew/remind.sh", env({ usage_profile: "desktop" }));
    expect(r.code).toBe(0);
    expect(r.err).toContain("bootstrap: brew bundle could not install: com.discordapp.Discord");
    expect(r.err).toContain(`retry: brew bundle install (log: ${join(state(), "brew-bundle.log")})`);
  });

  it("stays quiet when nothing failed", () => {
    const r = runStep("brew/remind.sh", env({ usage_profile: "desktop" }));
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
  });
});

describe("Homebrew install needs sudo", () => {
  const step = readFileSync(join(STEPS, INSTALL), "utf8");
  const runInstall = (sudoOk: boolean) => {
    writeFileSync(join(t, "bin", "id"), "#!/bin/sh\necho 501\n");
    writeFileSync(join(t, "bin", "sudo"), `#!/bin/sh\necho "sudo $*" >> "${join(t, "sudo.log")}"\nexit ${sudoOk ? 0 : 1}\n`);
    // The installer body itself: a no-op, so the test never reaches the network.
    writeFileSync(join(t, "bin", "curl"), "#!/bin/sh\necho 'exit 0'\n");
    for (const n of ["id", "sudo", "curl"]) chmodSync(join(t, "bin", n), 0o755);
    return runStep(INSTALL, env(), { stdin: "ignore" });
  };

  it("asks for sudo before running the installer", () => {
    expect(step).toContain("sudo -n true");
    expect(step.indexOf("sudo -n true")).toBeLessThan(step.indexOf("NONINTERACTIVE=1 /bin/bash"));
  });

  it("goes on when a sudo ticket already exists (Linux, after apt)", () => {
    const r = runInstall(true);
    expect(r.code).toBe(0);
    expect(readFileSync(join(t, "sudo.log"), "utf8")).toContain("sudo -n true");
  });

  it("without a ticket or a terminal, stops with what to run", () => {
    const r = runInstall(false);
    expect(r.code).toBe(1);
    expect(r.err).toContain("run 'sudo -v', then mise bootstrap");
  });
});

// Shells set XDG_CONFIG_HOME, so brew reads its trust store from ~/.config/homebrew (the link into
// config/homebrew); the phase must use that store too, and make the link before brew creates a real folder there.
describe("brew's user config folder", () => {
  const link = () => join(t, ".config", "homebrew");
  const xdg = () => readFileSync(join(t, "calls.xdg"), "utf8").trim();
  beforeEach(() => mkdirSync(join(t, ".local", "share", "dots", "config", "homebrew"), { recursive: true }));

  it("links ~/.config/homebrew into the repo and runs brew bundle with XDG_CONFIG_HOME=~/.config", () => {
    expect(phase({ MISE_ENV: "desktop" }).bundle.code).toBe(0);
    expect(readlinkSync(link())).toBe("../.local/share/dots/config/homebrew");
    expect(xdg()).toBe(join(t, ".config"));
  });

  it("keeps an existing ~/.config/homebrew and the caller's XDG_CONFIG_HOME", () => {
    mkdirSync(join(t, ".config"), { recursive: true });
    symlinkSync("/elsewhere", link());
    expect(phase({ MISE_ENV: "desktop", XDG_CONFIG_HOME: join(t, ".config") }).bundle.code).toBe(0);
    expect(readlinkSync(link())).toBe("/elsewhere");
    expect(xdg()).toBe(join(t, ".config"));
  });

  it("makes no link when XDG_CONFIG_HOME is somewhere else", () => {
    expect(phase({ MISE_ENV: "desktop", XDG_CONFIG_HOME: join(t, "xdg") }).bundle.code).toBe(0);
    expect(existsSync(link())).toBe(false);
    expect(xdg()).toBe(join(t, "xdg"));
  });
});
