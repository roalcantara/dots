#!/usr/bin/env bun
// The Karabiner fn layer (config/karabiner): rules generated from src/bindings.ts into the "dots" profile
// of karabiner.json, plus hotkeys.json for the kb Hotkeys command.
import { afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const DIR = join(REPO, "config/karabiner");
const json = (p: string) => JSON.parse(readFileSync(p, "utf8"));

type Manipulator = { from: { key_code: string; modifiers: { mandatory: string[] } }; to: Array<{ shell_command?: string; key_code?: string }> };
const profile = json(join(DIR, "karabiner.json")).profiles.find((p: { name: string }) => p.name === "dots");
const manipulators: Manipulator[] = profile.complex_modifications.rules.flatMap((r: { manipulators: Manipulator[] }) => r.manipulators);
const combo = (m: Manipulator) => [m.from.key_code, ...[...m.from.modifiers.mandatory].sort()].join("+");
const find = (key: string, ...mods: string[]) =>
  manipulators.find((m) => combo(m) === [key, ...["fn", ...mods].sort()].join("+"));
const command = (key: string, ...mods: string[]) => find(key, ...mods)?.to[0]?.shell_command ?? "";

function check(dir: string) {
  const r = Bun.spawnSync(["bun", join(DIR, "src/build.ts"), "--check"], {
    env: { ...Bun.env, DOTS_KARABINER_DIR: dir },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: r.exitCode, out: r.stdout.toString() + r.stderr.toString() };
}

// build.ts imports karabiner.ts; a fresh clone has no node_modules yet.
beforeAll(() => {
  Bun.spawnSync(["bun", "install", "--frozen-lockfile", "--cwd", DIR], { stdout: "ignore", stderr: "ignore" });
});

describe("karabiner fn layer", () => {
  it("the dots profile is selected and uses an ANSI virtual keyboard", () => {
    expect(profile.selected).toBe(true);
    expect(profile.virtual_hid_keyboard.keyboard_type_v2).toBe("ansi");
  });

  it("every binding needs fn, and no two bindings share a combination", () => {
    expect(manipulators.length).toBeGreaterThan(50);
    for (const m of manipulators) expect(m.from.modifiers.mandatory).toContain("fn");
  });

  it("still works with Caps Lock on", () => {
    for (const m of manipulators) expect((m.from.modifiers as { optional?: string[] }).optional).toEqual(["caps_lock"]);
    expect(new Set(manipulators.map(combo)).size).toBe(manipulators.length);
  });

  it("fn + 1…0 focus s1…s10; with ⇧ they move the window, with ⇧⌥ without following", () => {
    const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
    keys.forEach((key, i) => {
      expect(command(key)).toEndWith(`yb" space ${i + 1}`);
      expect(command(key, "shift")).toEndWith(`yb" move ${i + 1}`);
      expect(command(key, "shift", "option")).toEndWith(`yb" move ${i + 1} --stay`);
    });
  });

  it("fn + arrows focus, ⇧ swaps, ⌥↑/↓ page", () => {
    expect(command("left_arrow")).toEndWith('yb" focus west');
    expect(command("down_arrow", "shift")).toEndWith('yb" swap south');
    expect(command("right_arrow", "shift", "control")).toEndWith('yb" send-display east');
    expect(find("up_arrow", "option")?.to).toEqual([{ key_code: "page_up" }]);
    expect(find("down_arrow", "option")?.to).toEqual([{ key_code: "page_down" }]);
  });

  it("runs yb from ~/.local/bin with Homebrew on PATH", () => {
    for (const m of manipulators.filter((x) => x.to[0]?.shell_command)) {
      expect(m.to[0]!.shell_command).toStartWith('PATH=/opt/homebrew/bin:/usr/bin:/bin "$HOME/.local/bin/yb" ');
    }
    expect(command("return_or_enter", "shift")).toEndWith("yb\" app 'Google Chrome'");
  });

  it("writes one hotkey entry per binding", () => {
    const hotkeys = json(join(DIR, "hotkeys.json"));
    expect(hotkeys).toHaveLength(manipulators.length);
    expect(hotkeys).toContainEqual({ keys: "fn ⇧ 1", label: "Move window to space 1", group: "Spaces" });
  });

  describe("--check", () => {
    let t: string;
    beforeEach(() => {
      t = mkdtempSync(join(tmpdir(), "karabiner-check-"));
      for (const f of ["karabiner.json", "hotkeys.json"]) cpSync(join(DIR, f), join(t, f));
    });
    afterEach(() => rmSync(t, { recursive: true, force: true }));

    it("passes on the committed files", () => {
      expect(check(DIR).code).toBe(0);
    });

    it("fails when a committed rule differs from the bindings", () => {
      const k = json(join(t, "karabiner.json"));
      k.profiles[0].complex_modifications.rules[0].manipulators[0].to[0].shell_command = "true";
      writeFileSync(join(t, "karabiner.json"), JSON.stringify(k));
      const r = check(t);
      expect(r.code).toBe(1);
      expect(r.out).toContain("karabiner:build");
    });

    it("fails when hotkeys.json is stale", () => {
      writeFileSync(join(t, "hotkeys.json"), "[]");
      expect(check(t).code).toBe(1);
    });

    it("ignores what Karabiner's settings window adds", () => {
      const k = json(join(t, "karabiner.json"));
      k.profiles[0].devices = [{ identifiers: { is_keyboard: true }, ignore: false }];
      k.profiles.push({ name: "other", complex_modifications: { rules: [] } });
      writeFileSync(join(t, "karabiner.json"), JSON.stringify(k, null, 4));
      expect(check(t).code).toBe(0);
    });
  });
});
