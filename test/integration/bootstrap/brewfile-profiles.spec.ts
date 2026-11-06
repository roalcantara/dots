#!/usr/bin/env bun
// The Brewfile's groups per profile: HOMEBREW_DOTS_PROFILE is a comma-separated list (container | desktop | desktop,dev).
import { describe, expect, it } from "bun:test";
import { join } from "node:path";

const BREWFILE = join(import.meta.dir, "../../../config/homebrew/Brewfile");
const brew = Bun.which("brew");
const list = (profile: string) => {
  const p = Bun.spawnSync([brew as string, "bundle", "list", "--all", "--file", BREWFILE], {
    env: { ...process.env, HOMEBREW_DOTS_PROFILE: profile, HOMEBREW_NO_AUTO_UPDATE: "1" }, stdout: "pipe", stderr: "pipe",
  });
  return p.stdout.toString().split("\n");
};

describe.skipIf(!brew)("Brewfile profiles", () => {
  const container = list("container");
  const desktop = list("desktop");
  const dev = list("desktop,dev");
  it("minimal group everywhere", () => {
    for (const l of [container, desktop, dev]) expect(l).toContain("fzf");
  });
  it("desktop entries for desktop and desktop,dev only", () => {
    expect(container).not.toContain("gopass");
    expect(desktop).toContain("gopass");
    expect(dev).toContain("gopass");
  });
  it("DEVTOOLS entries for desktop,dev only", () => {
    expect(desktop).not.toContain("shellcheck");
    expect(dev).toContain("shellcheck");
  });
  it("dev alone implies desktop", () => expect(list("dev")).toContain("gopass"));
});
