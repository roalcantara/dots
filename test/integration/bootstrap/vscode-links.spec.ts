#!/usr/bin/env bun
// mise links VS Code's user settings.json, keybindings.json and snippets (Application Support, macOS) back
// to the repo, so the live copy cannot drift from config/vscode. A link never replaces a real file, so the
// pre-dotfiles step moves what VS Code or Settings Sync wrote aside first, keeping it as a dated backup.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Database } from "bun:sqlite";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/dotfiles.toml"), "utf8")) as any;
const MOVE = "dotfiles/move-aside.sh";
const SYNC = "vscode/settings-sync.sh";
const VS = "~/Library/Application Support/Code/User";

let t: string;
let user: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "vscode-links-"));
  user = join(t, "Code", "User");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function step(rel: string, env: Record<string, string> = {}) {
  return runStep(rel, {
    PATH: "/usr/bin:/bin",
    HOME: t,
    DOTS_UNAME: "Darwin",
    DOTS_VSCODE_USER: user,
    DOTS_VSCODE_STATE: join(user, "globalStorage", "state.vscdb"),
    ...env,
  });
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

  it("step: does nothing off macOS", () => {
    expect(step(MOVE, { DOTS_UNAME: "Linux" }).code).toBe(0);
    expect(existsSync(user)).toBe(false);
  });

  it("step: creates the User folder on a fresh machine", () => {
    expect(step(MOVE).code).toBe(0);
    expect(lstatSync(user).isDirectory()).toBe(true);
    expect(backups()).toEqual([]);
  });

  it("step: moves a real settings.json, keybindings.json and snippets folder aside, keeping their content", () => {
    mkdirSync(join(user, "snippets"), { recursive: true });
    writeFileSync(join(user, "settings.json"), '{ "old": true }\n');
    writeFileSync(join(user, "keybindings.json"), "[]\n");
    writeFileSync(join(user, "snippets", "bash.json"), "{}\n");
    const r = step(MOVE);
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

  it("step: leaves the dots links alone", () => {
    mkdirSync(user, { recursive: true });
    symlinkSync(join(REPO, "config/vscode/settings.json"), join(user, "settings.json"));
    symlinkSync(join(REPO, "config/vscode/keybindings.json"), join(user, "keybindings.json"));
    symlinkSync(join(REPO, "config/snippets"), join(user, "snippets"));
    expect(step(MOVE).code).toBe(0);
    expect(lstatSync(join(user, "settings.json")).isSymbolicLink()).toBe(true);
    expect(lstatSync(join(user, "keybindings.json")).isSymbolicLink()).toBe(true);
    expect(lstatSync(join(user, "snippets")).isSymbolicLink()).toBe(true);
    expect(backups()).toEqual([]);
  });

  it("step: running it twice moves nothing the second time and says nothing", () => {
    mkdirSync(join(user, "snippets"), { recursive: true });
    writeFileSync(join(user, "settings.json"), "{}\n");
    expect(step(MOVE).code).toBe(0);
    const first = backups();
    const second = step(MOVE);
    expect(second.code).toBe(0);
    expect(second.err).toBe("");
    expect(backups()).toEqual(first);
  });

  describe("Settings Sync", () => {
    const db = () => join(user, "globalStorage", "state.vscdb");
    const rows = () => {
      const d = new Database(db(), { readonly: true });
      try {
        return Object.fromEntries(
          (d.query("select key, value from ItemTable where key like 'sync.%' order by key").all() as { key: string; value: string }[])
            .map((r) => [r.key, String(r.value)]),
        );
      } finally {
        d.close();
      }
    };
    const OFF = { "sync.enable.keybindings": "false", "sync.enable.settings": "false", "sync.enable.snippets": "false" };

    it("does nothing off macOS", () => {
      expect(step(SYNC, { DOTS_UNAME: "Linux" }).code).toBe(0);
      expect(existsSync(db())).toBe(false);
    });

    it("turns settings, keybindings and snippets off in a fresh state database", () => {
      expect(step(SYNC).code).toBe(0);
      expect(rows()).toEqual(OFF);
    });

    it("switches them off in VS Code's existing database and leaves the other keys alone", () => {
      mkdirSync(join(user, "globalStorage"), { recursive: true });
      const d = new Database(db());
      d.run("CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)");
      d.run("INSERT INTO ItemTable VALUES ('sync.enable', 'true'), ('sync.enable.settings', 'true'), ('sync.enable.prompts', 'true')");
      d.close();
      expect(step(SYNC).code).toBe(0);
      expect(step(SYNC).code).toBe(0);
      expect(rows()).toEqual({ ...OFF, "sync.enable": "true", "sync.enable.prompts": "true" });
    });
  });
});
