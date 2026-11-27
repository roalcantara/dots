#!/usr/bin/env bun
// The macOS preferences in config/mise/conf.d/macos.toml: checks cross-file invariants (TOML float type,
// screenshots folder vs hook, Dock/login-items against Brewfile) and the post-defaults step behaviour.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
type Config = {
  bootstrap: {
    directories: Record<string, unknown>;
    settings: {
      macos: {
        dock: Record<string, unknown>;
        login_items: { apps: string[]; exclusive?: boolean };
        defaults: Record<string, Record<string, unknown>>;
      };
    };
  };
};
const config = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/macos.toml"), "utf8")) as Config;
const macos = config.bootstrap.settings.macos;

describe("macOS defaults (config/mise/conf.d/macos.toml)", () => {
  it("writes pointer speeds as reals", () => {
    const g = macos.defaults.NSGlobalDomain!;
    expect(g["com.apple.trackpad.scaling"]).toBe(3);
    expect(g["com.apple.mouse.scaling"]).toBe(3);
    // Bun parses `3.0` and `3` alike; the source must say 3.0 so mise writes a real.
    const src = readFileSync(join(REPO, "config/mise/conf.d/macos.toml"), "utf8");
    expect(src).toMatch(/"com\.apple\.trackpad\.scaling" = 3\.0/);
    expect(src).toMatch(/"com\.apple\.mouse\.scaling" = 3\.0/);
  });

  it("declares the screenshots folder; the hook sets it (mise does not expand ~ or templates in values)", () => {
    expect(macos.defaults["com.apple.screencapture"]).not.toHaveProperty("location");
    // macOS only: Linux bootstraps and the Docker images must not change.
    expect(config.bootstrap.directories["~/Pictures/Screenshots"]).toMatchObject({ os: "macos" });
  });

  it("pins and starts only apps the Brewfile installs (or macOS ships)", () => {
    const brewfile = readFileSync(join(REPO, "config/homebrew/Brewfile"), "utf8");
    const casks: Record<string, string> = { "Google Chrome": "google-chrome", Ghostty: "ghostty",
      "Visual Studio Code": "visual-studio-code", Claude: "claude", ChatGPT: "chatgpt", WhatsApp: "whatsapp",
      Discord: "discord", noTunes: "notunes", Raycast: "raycast", Vorssaint: "vorssaint", Bitwarden: "bitwarden",
      "Google Drive": "google-drive", SwiftBar: "swiftbar", CodexBar: "codexbar" };
    for (const app of [...(macos.dock.apps as string[]), ...macos.login_items.apps]) {
      if (app.startsWith("/System/")) continue;
      const name = app.replace(/^\/Applications\//, "").replace(/\.app$/, "");
      expect(casks[name]).toBeDefined();
      expect(brewfile).toContain(`cask "${casks[name]}" if OS.mac?`);
    }
  });
});

describe("post-defaults step", () => {
  let t: string;
  beforeEach(() => {
    t = mkdtempSync(join(tmpdir(), "macos-hook-"));
    mkdirSync(join(t, "bin"));
  });
  afterEach(() => rmSync(t, { recursive: true, force: true }));

  function hook(os: string, killallExit: number, activate?: string) {
    const stub = (name: string, body: string) => {
      writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
      chmodSync(join(t, "bin", name), 0o755);
    };
    // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin (and duti) first.
    stub("brew", "exit 0");
    stub("killall", `echo "$@" >> "${t}/killall.calls"; exit ${killallExit}`);
    stub("defaults", `echo "$@" >> "${t}/defaults.calls"; exit 1`);
    stub("duti", `echo "$@" >> "${t}/duti.calls"; exit 1`);
    stub("activate", `echo "$@" >> "${t}/activate.calls"; exit 1`);
    return runStep("macos/activate.sh", {
      PATH: `${join(t, "bin")}:/usr/bin:/bin`,
      HOME: t,
      DOTS_UNAME: os,
      DOTS_ACTIVATE_SETTINGS: activate ?? join(t, "bin", "activate"),
    }).code;
  }

  it("does nothing off macOS", () => {
    expect(hook("Linux", 0)).toBe(0);
    expect(existsSync(join(t, "killall.calls"))).toBe(false);
    expect(existsSync(join(t, "activate.calls"))).toBe(false);
    expect(existsSync(join(t, "defaults.calls"))).toBe(false);
    expect(existsSync(join(t, "duti.calls"))).toBe(false);
  });

  it("sets the default apps from ~/.config/duti/defaults.duti", () => {
    expect(hook("Darwin", 0)).toBe(0);
    expect(readFileSync(join(t, "duti.calls"), "utf8").trim()).toBe(`${t}/.config/duti/defaults.duti`);
  });

  it("points screenshots at an absolute folder under HOME", () => {
    expect(hook("Darwin", 0)).toBe(0);
    expect(readFileSync(join(t, "defaults.calls"), "utf8").trim())
      .toBe(`write com.apple.screencapture location -string ${t}/Pictures/Screenshots`);
  });

  it("still restarts the apps when activateSettings is missing", () => {
    expect(hook("Darwin", 0, join(t, "missing"))).toBe(0);
    expect(readFileSync(join(t, "killall.calls"), "utf8")).toContain("Dock Finder SystemUIServer");
  });

  it("applies the hotkeys and restarts Dock, Finder and the menu bar, never failing", () => {
    expect(hook("Darwin", 1)).toBe(0);
    expect(readFileSync(join(t, "activate.calls"), "utf8").trim()).toBe("-u");
    expect(readFileSync(join(t, "killall.calls"), "utf8")).toContain("Dock Finder SystemUIServer");
  });
});
