#!/usr/bin/env bun
// install links ~/.config/age to config/age before `mise bootstrap --adopt`: the mise config names
// ~/.config/age/keys.txt as the only age identity, so without the link the history cannot be decrypted.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { lstatSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const INSTALL = readFileSync(join(REPO, "install"), "utf8");
const SNIPPET = INSTALL.match(/# age-link: begin\n[\s\S]*?# age-link: end\n/)?.[0] ?? "";
const CONFIG = readFileSync(join(REPO, "config/mise/config.toml"), "utf8");

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "install-age-link-"));
  mkdirSync(join(t, ".local", "share", "dots", "config", "age"), { recursive: true });
  writeFileSync(join(t, ".local", "share", "dots", "config", "age", "keys.txt"), "AGE-SECRET-KEY-1TEST\n");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));
const run = () => Bun.spawnSync(["bash", "-c", `set -euo pipefail\n${SNIPPET}`], { env: { PATH: "/usr/bin:/bin", HOME: t } }).exitCode;
const age = () => join(t, ".config", "age");

describe("install age-link", () => {
  it("runs before mise bootstrap --adopt", () => {
    expect(SNIPPET).toContain("config/age");
    expect(INSTALL.indexOf("# age-link: begin")).toBeLessThan(INSTALL.indexOf("mise bootstrap --adopt"));
  });

  it("points at the path the mise config names as the age identity", () => {
    expect(CONFIG).toContain('identity_files = ["~/.config/age/keys.txt"]');
    expect(run()).toBe(0);
    expect(readlinkSync(age())).toBe("../.local/share/dots/config/age");
    expect(readFileSync(join(age(), "keys.txt"), "utf8")).toBe("AGE-SECRET-KEY-1TEST\n");
  });

  it("replaces a broken link and leaves a real folder alone", () => {
    mkdirSync(join(t, ".config"), { recursive: true });
    symlinkSync("../nowhere", age());
    expect(run()).toBe(0);
    expect(readlinkSync(age())).toBe("../.local/share/dots/config/age");
    rmSync(age());
    mkdirSync(age());
    expect(run()).toBe(0);
    expect(lstatSync(age()).isDirectory()).toBe(true);
  });
});
