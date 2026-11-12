#!/usr/bin/env bun
// The macOS preferences in config/mise/conf.d/macos.toml: pins the values Raycast and yabai rely on (and their TOML
// types: mise rewrites a preference whose type differs), and checks the post-defaults hook never fails a bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
type Entry = { domain: string; key?: string; path?: string[]; host?: string; value: unknown };
type Config = {
  bootstrap: {
    directories: Record<string, unknown>;
    files: Record<string, Record<string, unknown>>;
    hooks: { "post-defaults": { run: string } };
    macos: {
      keyboard: Record<string, unknown>;
      trackpad: Record<string, unknown>;
      dock: Record<string, unknown>;
      finder: Record<string, unknown>;
      login_items: { apps: string[]; exclusive?: boolean };
      defaults: Record<string, Record<string, unknown>>;
      defaults_entries: Entry[];
      launchd: { agents: Record<string, Record<string, unknown>> };
    };
  };
};
const config = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/macos.toml"), "utf8")) as Config;
const macos = config.bootstrap.macos;
const entry = (domain: string, key: string) =>
  macos.defaults_entries.find((e) => e.domain === domain && (e.key === key || e.path?.at(-1) === key));

describe("macOS defaults (config/mise/conf.d/macos.toml)", () => {
  it("sets a fast key repeat and turns off press-and-hold", () => {
    expect(macos.keyboard.key_repeat).toBe(2);
    expect(macos.keyboard.initial_key_repeat).toBe(15);
    expect(macos.keyboard.press_and_hold).toBe(false);
    expect(macos.defaults.NSGlobalDomain!.AppleKeyboardUIMode).toBe(3);
  });

  it("auto-hides the Dock and never rearranges Spaces (yabai)", () => {
    expect(macos.dock.autohide).toBe(true);
    expect(macos.dock.mru_spaces).toBe(false);
    expect(macos.dock.show_recents).toBe(false);
    expect(macos.defaults["com.apple.spaces"]!["spans-displays"]).toBe(false);
  });

  it("taps to click and keeps three-finger swipes for Spaces", () => {
    expect(macos.trackpad.tap_to_click).toBe(true);
    expect(macos.trackpad.three_finger_drag).toBe(false);
  });

  it("writes pointer speeds as reals", () => {
    const g = macos.defaults.NSGlobalDomain!;
    expect(g["com.apple.trackpad.scaling"]).toBe(3);
    expect(g["com.apple.mouse.scaling"]).toBe(3);
    // Bun parses `3.0` and `3` alike; the source must say 3.0 so mise writes a real.
    const src = readFileSync(join(REPO, "config/mise/conf.d/macos.toml"), "utf8");
    expect(src).toMatch(/"com\.apple\.trackpad\.scaling" = 3\.0/);
    expect(src).toMatch(/"com\.apple\.mouse\.scaling" = 3\.0/);
  });

  it("turns off the window tiling and Stage Manager that fight yabai", () => {
    const wm = macos.defaults["com.apple.WindowManager"]!;
    for (const k of ["EnableTilingByEdgeDrag", "EnableTopTilingByEdgeDrag", "EnableTilingOptionAccelerator",
      "GloballyEnabled", "EnableStandardClickToShowDesktop"]) expect(wm[k]).toBe(false);
  });

  it("moves Spotlight to Option-Space, leaving Command-Space to Raycast", () => {
    const e = macos.defaults_entries.find((x) => x.domain === "com.apple.symbolichotkeys");
    expect(e?.key).toBe("AppleSymbolicHotKeys");
    expect(e?.path).toEqual(["64"]);
    expect(e?.value).toEqual({ enabled: true, value: { parameters: [32, 49, 524288], type: "standard" } });
    const params = (e?.value as { value: { parameters: number[] } }).value.parameters;
    for (const p of params) expect(Number.isInteger(p)).toBe(true);
  });

  it("keeps Photos closed when a device connects (current host)", () => {
    const e = entry("com.apple.ImageCapture", "disableHotPlug");
    expect(e?.host).toBe("current");
    expect(e?.value).toBe(true);
  });

  it("declares the screenshots folder; the hook sets it (mise does not expand ~ or templates in values)", () => {
    expect(macos.defaults["com.apple.screencapture"]).not.toHaveProperty("location");
    // macOS only: Linux bootstraps and the Docker images must not change.
    expect(config.bootstrap.directories["~/Pictures/Screenshots"]).toMatchObject({ os: "macos" });
  });

  it("sets the light click on built-in and Bluetooth trackpads", () => {
    for (const d of ["com.apple.AppleMultitouchTrackpad", "com.apple.driver.AppleBluetoothMultitouch.trackpad"]) {
      expect(macos.defaults[d]!.FirstClickThreshold).toBe(0);
      expect(macos.defaults[d]!.SecondClickThreshold).toBe(0);
    }
  });

  it("taps to click at the login window too (current host)", () => {
    const e = entry("NSGlobalDomain", "com.apple.mouse.tapBehavior");
    expect(e?.host).toBe("current");
    expect(e?.value).toBe(1);
  });

  it("loads the SSH keys from Keychain at every login (Apple's ssh-add)", () => {
    const agent = macos.launchd.agents["ssh-add"]!;
    expect(agent.program).toBe("/usr/bin/ssh-add");
    expect(agent.args).toEqual(["--apple-load-keychain"]);
    expect(agent.run_at_load).toBe(true);
    expect(agent.keep_alive).not.toBe(true);
  });

  it("starts noTunes and the menu-bar helpers at login without removing other login items", () => {
    expect(macos.login_items.apps).toEqual(["/Applications/noTunes.app", "/Applications/Raycast.app",
      "/Applications/Vorssaint.app", "/Applications/Bitwarden.app", "/Applications/Google Drive.app",
      "/Applications/SwiftBar.app"]);
    expect(macos.login_items.exclusive).not.toBe(true);
  });

  it("pins a short Dock: browser, terminal, editor, AI, chat, settings", () => {
    expect(macos.dock.apps).toEqual(["/Applications/Google Chrome.app", "/Applications/Ghostty.app",
      "/Applications/Visual Studio Code.app", "/Applications/Claude.app", "/Applications/ChatGPT.app",
      "/Applications/WhatsApp.app", "/Applications/Discord.app", "/System/Applications/System Settings.app"]);
  });

  it("pins and starts only apps the Brewfile installs (or macOS ships)", () => {
    const brewfile = readFileSync(join(REPO, "config/homebrew/Brewfile"), "utf8");
    const casks: Record<string, string> = { "Google Chrome": "google-chrome", Ghostty: "ghostty",
      "Visual Studio Code": "visual-studio-code", Claude: "claude", ChatGPT: "chatgpt", WhatsApp: "whatsapp",
      Discord: "discord", noTunes: "notunes", Raycast: "raycast", Vorssaint: "vorssaint", Bitwarden: "bitwarden",
      "Google Drive": "google-drive", SwiftBar: "swiftbar" };
    for (const app of [...(macos.dock.apps as string[]), ...macos.login_items.apps]) {
      if (app.startsWith("/System/")) continue;
      const name = app.replace(/^\/Applications\//, "").replace(/\.app$/, "");
      expect(casks[name]).toBeDefined();
      expect(brewfile).toContain(`cask "${casks[name]}" if OS.mac?`);
    }
  });

  it("enables Touch ID for sudo in the file macOS updates keep", () => {
    const f = config.bootstrap.files["/etc/pam.d/sudo_local"]!;
    expect(f).toMatchObject({ os: "macos", owner: "root", group: "wheel", mode: "0444", phase: "pre-packages" });
    expect(f.content as string).toMatch(/^auth\s+sufficient\s+pam_tid\.so$/m);
  });
});

describe("post-defaults hook", () => {
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
    stub("uname", `echo ${os}`);
    stub("killall", `echo "$@" >> "${t}/killall.calls"; exit ${killallExit}`);
    stub("defaults", `echo "$@" >> "${t}/defaults.calls"; exit 1`);
    stub("duti", `echo "$@" >> "${t}/duti.calls"; exit 1`);
    stub("activate", `echo "$@" >> "${t}/activate.calls"; exit 1`);
    const p = Bun.spawnSync(["bash", "-c", config.bootstrap.hooks["post-defaults"].run], {
      env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, DOTS_ACTIVATE_SETTINGS: activate ?? join(t, "bin", "activate") },
      stdout: "pipe", stderr: "pipe",
    });
    return p.exitCode;
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
