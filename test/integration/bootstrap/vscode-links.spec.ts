#!/usr/bin/env bun
// mise links VS Code's user settings.json, keybindings.json and snippets (Application Support, macOS) back
// to the repo, so the live copy cannot drift from config/vscode. A link never replaces a real file, so the
// pre-dotfiles hook moves what VS Code or Settings Sync wrote aside first, keeping it as a dated backup.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/dotfiles.toml"), "utf8")) as any;
const HOOK: string = conf.bootstrap.hooks["pre-dotfiles"].run;
const VS = "~/Library/Application Support/Code/User";

let t: string;
let user: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "vscode-links-"));
  user = join(t, "Code", "User");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function hook(os = "Darwin") {
  const bin = join(t, "bin");
  mkdirSync(bin, { recursive: true });
  writeFileSync(join(bin, "uname"), `#!/bin/sh\necho ${os}\n`);
  chmodSync(join(bin, "uname"), 0o755);
  const p = Bun.spawnSync(["sh", "-o", "errexit", "-c", HOOK], {
    env: { PATH: `${bin}:/usr/bin:/bin`, HOME: t, DOTS_VSCODE_USER: user }, stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, err: p.stderr.toString() };
}
const backups = () => readdirSync(user).filter((f) => f.includes(".pre-dots-")).sort();

describe("VS Code links", () => {
  it("links settings.json and keybindings.json to config/vscode and snippets to ~/.config/snippets, on macOS only", () => {
    expect(conf.dotfiles["vscode-settings"]).toEqual({
      source: "~/.local/share/dots/config/vscode/settings.json",
      relative: true,
      variants: [{ os: "macos", target: `${VS}/settings.json` }],
    });
    expect(conf.dotfiles["vscode-keybindings"]).toEqual({
      source: "~/.local/share/dots/config/vscode/keybindings.json",
      relative: true,
      variants: [{ os: "macos", target: `${VS}/keybindings.json` }],
    });
    expect(conf.dotfiles["vscode-snippets"]).toEqual({
      source: "~/.config/snippets",
      relative: true,
      variants: [{ os: "macos", target: `${VS}/snippets` }],
    });
  });

  it("hook: does nothing off macOS", () => {
    expect(hook("Linux").code).toBe(0);
    expect(existsSync(user)).toBe(false);
  });

  it("hook: creates the User folder on a fresh machine", () => {
    expect(hook().code).toBe(0);
    expect(lstatSync(user).isDirectory()).toBe(true);
    expect(backups()).toEqual([]);
  });

  it("hook: moves a real settings.json, keybindings.json and snippets folder aside, keeping their content", () => {
    mkdirSync(join(user, "snippets"), { recursive: true });
    writeFileSync(join(user, "settings.json"), '{ "old": true }\n');
    writeFileSync(join(user, "keybindings.json"), "[]\n");
    writeFileSync(join(user, "snippets", "bash.json"), "{}\n");
    const r = hook();
    expect(r.code).toBe(0);
    expect(existsSync(join(user, "settings.json"))).toBe(false);
    expect(existsSync(join(user, "keybindings.json"))).toBe(false);
    expect(existsSync(join(user, "snippets"))).toBe(false);
    const [keybindings, settings, snippets] = backups();
    expect(keybindings).toMatch(/^keybindings\.json\.pre-dots-\d{14}$/);
    expect(settings).toMatch(/^settings\.json\.pre-dots-\d{14}$/);
    expect(snippets).toMatch(/^snippets\.pre-dots-\d{14}$/);
    expect(readFileSync(join(user, settings!), "utf8")).toBe('{ "old": true }\n');
    expect(readFileSync(join(user, keybindings!), "utf8")).toBe("[]\n");
    expect(readFileSync(join(user, snippets!, "bash.json"), "utf8")).toBe("{}\n");
    expect(r.err).toContain("moved");
  });

  it("hook: leaves the dots links alone", () => {
    mkdirSync(user, { recursive: true });
    symlinkSync(join(REPO, "config/vscode/settings.json"), join(user, "settings.json"));
    symlinkSync(join(REPO, "config/vscode/keybindings.json"), join(user, "keybindings.json"));
    symlinkSync(join(REPO, "config/snippets"), join(user, "snippets"));
    expect(hook().code).toBe(0);
    expect(lstatSync(join(user, "settings.json")).isSymbolicLink()).toBe(true);
    expect(lstatSync(join(user, "keybindings.json")).isSymbolicLink()).toBe(true);
    expect(lstatSync(join(user, "snippets")).isSymbolicLink()).toBe(true);
    expect(backups()).toEqual([]);
  });
});
