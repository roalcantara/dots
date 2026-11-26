#!/usr/bin/env bun
// The pass-link step: links ~/.local/bin/pass to Homebrew's gopass (else any gopass on PATH), and never replaces a
// real pass.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const STEP = "gopass/pass-link.sh";

let t: string;
const exe = (path: string) => {
  writeFileSync(path, "#!/bin/sh\nexit 0\n");
  chmodSync(path, 0o755);
};
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "pass-link-"));
  mkdirSync(join(t, "brew", "bin"), { recursive: true });
  mkdirSync(join(t, "other"));
  mkdirSync(join(t, "bin"));
  exe(join(t, "brew", "bin", "gopass"));
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  exe(join(t, "bin", "brew"));
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const link = () => join(t, ".local", "bin", "pass");
function snippet(env: Record<string, string>) {
  return runStep(STEP, {
    ...env,
    PATH: `${env.PATH ?? "/usr/bin:/bin"}:${join(t, "bin")}`,
    HOME: t,
    DOTS_PROFILE: "desktop",
  });
}

// Only meaningful where neither pass nor gopass is a system package.
const clean = !["/usr/bin/pass", "/bin/pass", "/usr/bin/gopass", "/bin/gopass"].some(existsSync);

describe.skipIf(!clean)("bootstrap pass-link", () => {
  it("is in the final phase, after the gopass store clone", () => {
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap", STEP), "utf8")).toContain("$HOME/.local/bin/pass");
    const phases = Bun.TOML.parse(readFileSync(join(REPO, ".mise/tasks/bootstrap/phases.toml"), "utf8")) as {
      "bootstrap:hook:final": { run: { task: string }[] };
    };
    const order = phases["bootstrap:hook:final"].run.map((s) => s.task);
    expect(order.indexOf("bootstrap:gopass:pass-link")).toBeGreaterThan(order.indexOf("bootstrap:gopass:store"));
  });

  it("links pass to gopass in $HOMEBREW_PREFIX", () => {
    const r = snippet({ HOMEBREW_PREFIX: join(t, "brew") });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
    expect(readlinkSync(link())).toBe(join(t, "brew", "bin", "gopass"));
  });

  it("falls back to gopass on PATH without a Homebrew prefix", () => {
    exe(join(t, "other", "gopass"));
    snippet({ PATH: `${join(t, "other")}:/usr/bin:/bin` });
    expect(readlinkSync(link())).toBe(join(t, "other", "gopass"));
  });

  it("refreshes its own link", () => {
    mkdirSync(join(t, ".local", "bin"), { recursive: true });
    symlinkSync(join(t, "gone", "gopass"), link());
    snippet({ HOMEBREW_PREFIX: join(t, "brew"), PATH: `${join(t, ".local", "bin")}:/usr/bin:/bin` });
    expect(readlinkSync(link())).toBe(join(t, "brew", "bin", "gopass"));
  });

  it("never replaces a real pass", () => {
    exe(join(t, "other", "pass"));
    snippet({ HOMEBREW_PREFIX: join(t, "brew"), PATH: `${join(t, "other")}:/usr/bin:/bin` });
    expect(existsSync(link())).toBe(false);
  });

  it("does nothing without gopass", () => {
    expect(snippet({}).code).toBe(0);
    expect(() => lstatSync(link())).toThrow();
  });
});
