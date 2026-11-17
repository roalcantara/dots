#!/usr/bin/env bun
// The Brewfile's groups per profile: HOMEBREW_DOTS_PROFILE is a comma-separated list (container | desktop | desktop,dev).
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
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
  it("codexbar (agent limits in the menu bar) for desktop and desktop,dev", () => {
    expect(container).not.toContain("codexbar");
    expect(desktop).toContain("codexbar");
    expect(dev).toContain("codexbar");
  });
  it("DEVTOOLS entries for desktop,dev only", () => {
    expect(desktop).not.toContain("shellcheck");
    expect(dev).toContain("shellcheck");
  });
  it("vivid (theme:build) is a dev tool, not on desktop or container", () => {
    expect(container).not.toContain("vivid");
    expect(desktop).not.toContain("vivid");
    expect(dev).toContain("vivid");
  });
  it("gomi (the rm safety net) is a desktop tool, not in containers", () => {
    expect(container).not.toContain("gomi");
    expect(desktop).toContain("gomi");
    expect(dev).toContain("gomi");
  });
  it("dev alone implies desktop", () => expect(list("dev")).toContain("gopass"));
  it("todo CLI (todo-cli from RayanBO/todo) for desktop,dev only, after rust", () => {
    expect(container).not.toContain("todo-cli");
    expect(desktop).not.toContain("todo-cli");
    expect(dev).toContain("todo-cli");
    for (const l of [container, desktop, dev]) expect(l).not.toContain("todo"); // crates.io `todo` is another crate
    const text = readFileSync(BREWFILE, "utf8"); // install order is file order: cargo needs rust first
    expect(text.indexOf('cargo "todo-cli"')).toBeGreaterThan(text.indexOf('brew "rust"'));
  });
});
