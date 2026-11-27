#!/usr/bin/env bun
// The tiling setup: move-aside behaviour, yabairc/bordersrc validity and safety guards, scripting addition step,
// and SwiftBar plugin/step behaviour.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const read = (p: string) => readFileSync(join(REPO, p), "utf8");

describe("tiling pre-dotfiles step", () => {
  let t: string;
  beforeEach(() => {
    t = mkdtempSync(join(tmpdir(), "yabai-links-"));
  });
  afterEach(() => rmSync(t, { recursive: true, force: true }));

  const run = () =>
    runStep("dotfiles/move-aside.sh", {
      PATH: "/usr/bin:/bin",
      HOME: t,
      DOTS_UNAME: "Darwin",
      DOTS_VSCODE_USER: join(t, "Code", "User"),
    });
  const config = () => join(t, ".config");

  it("moves a real ~/.config/karabiner aside, keeping its content", () => {
    mkdirSync(join(config(), "karabiner"), { recursive: true });
    writeFileSync(join(config(), "karabiner", "karabiner.json"), "{}\n");
    expect(run().code).toBe(0);
    expect(existsSync(join(config(), "karabiner"))).toBe(false);
    const [moved] = readdirSync(config()).filter((f) => f.startsWith("karabiner.pre-dots-"));
    expect(moved).toMatch(/^karabiner\.pre-dots-\d{14}$/);
    expect(readFileSync(join(config(), moved!, "karabiner.json"), "utf8")).toBe("{}\n");
  });

  it("leaves the dots link alone", () => {
    mkdirSync(config(), { recursive: true });
    symlinkSync(join(REPO, "config/karabiner"), join(config(), "karabiner"));
    expect(run().code).toBe(0);
    expect(lstatSync(join(config(), "karabiner")).isSymbolicLink()).toBe(true);
  });
});

describe("yabai and borders services", () => {
  const yabairc = read("config/yabai/yabairc");
  const sh = (args: string[]) => Bun.spawnSync(args, { stdout: "pipe", stderr: "pipe" });

  it("yabairc and bordersrc are valid sh that shellcheck accepts", () => {
    for (const f of ["config/yabai/yabairc", "config/borders/bordersrc"]) {
      expect(sh(["sh", "-n", join(REPO, f)]).exitCode).toBe(0);
      const r = sh(["shellcheck", "-s", "sh", join(REPO, f)]);
      expect(r.stdout.toString()).toBe("");
    }
  });

  it("loads the scripting addition without ever waiting for a password", () => {
    // `yb load-sa` runs `sudo -n <the chosen yabai> --load-sa`, the path the sudoers rule names
    expect(yabairc).toContain('"$HOME/.local/bin/yb" load-sa');
    expect(yabairc).toContain('label=load_sa action="$HOME/.local/bin/yb load-sa"');
    expect(yabairc).not.toMatch(/^[^#]*\bsudo /m);
  });

  it("leaves Mission Control to borders (the fork hides outlines there; messages during it broke that)", () => {
    expect(yabairc).not.toContain("mission_control");
  });
});

describe("scripting addition step", () => {
  function run(os: string, ybExits = 0) {
    const t = mkdtempSync(join(tmpdir(), "yabai-sa-step-"));
    try {
      mkdirSync(join(t, "config", "bin"), { recursive: true });
      writeFileSync(join(t, "config", "bin", "yb"), `#!/bin/sh\necho "$@" >> "${t}/yb.calls"\nexit ${ybExits}\n`);
      chmodSync(join(t, "config", "bin", "yb"), 0o755);
      const r = runStep("yabai/scripting-addition.sh", {
        PATH: `${t}:/usr/bin:/bin`,
        HOME: t,
        DOTS_DIR: t,
        DOTS_UNAME: os,
      });
      const calls = existsSync(join(t, "yb.calls")) ? readFileSync(join(t, "yb.calls"), "utf8") : "";
      return { ...r, calls };
    } finally {
      rmSync(t, { recursive: true, force: true });
    }
  }

  it("runs the repo's yb sa on macOS, and never fails the bootstrap", () => {
    const r = run("Darwin", 1);
    expect(r.code).toBe(0);
    expect(r.calls.trim()).toBe("sa");
  });

  it("does nothing off macOS", () => {
    const r = run("Linux");
    expect(r.code).toBe(0);
    expect(r.out + r.err).toBe("");
    expect(r.calls).toBe("");
  });
});

describe("SwiftBar space strip", () => {
  const plugin = join(REPO, "config/swiftbar/plugins/spaces.sh");

  it("the plugin is executable and prints yb bar with Homebrew on PATH", () => {
    expect(statSync(plugin).mode & 0o111).not.toBe(0);
    const body = readFileSync(plugin, "utf8");
    expect(body).toContain('exec "$HOME/.local/bin/yb" bar');
    expect(body).toContain("/opt/homebrew/bin");
    expect(body).toContain("<swiftbar.hideAbout>true</swiftbar.hideAbout>");
  });

  function runHook(os: string) {
    const t = mkdtempSync(join(tmpdir(), "swiftbar-hook-"));
    // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
    for (const [name, body] of [["brew", "exit 0"], ["defaults", `echo "$@" >> "${t}/defaults.calls"`]]) {
      writeFileSync(join(t, name!), `#!/bin/sh\n${body}\n`);
      chmodSync(join(t, name!), 0o755);
    }
    const r = runStep("macos/swiftbar.sh", { PATH: `${t}:/usr/bin:/bin`, HOME: t, DOTS_UNAME: os });
    return {
      code: r.code,
      calls: existsSync(join(t, "defaults.calls")) ? readFileSync(join(t, "defaults.calls"), "utf8") : "",
      home: t,
    };
  }

  it("points SwiftBar at the plugin folder so its first launch needs no prompt", () => {
    const r = runHook("Darwin");
    expect(r.code).toBe(0);
    expect(r.calls).toContain(`write com.ameba.SwiftBar PluginDirectory -string ${r.home}/.config/swiftbar/plugins`);
    expect(r.calls).toContain("write com.ameba.SwiftBar SUHasLaunchedBefore -bool true");
    rmSync(r.home, { recursive: true, force: true });
  });

  it("does nothing off macOS", () => {
    const r = runHook("Linux");
    expect(r.code).toBe(0);
    expect(r.calls).toBe("");
    rmSync(r.home, { recursive: true, force: true });
  });
});
