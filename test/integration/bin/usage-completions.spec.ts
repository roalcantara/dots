#!/usr/bin/env bun
// Every config/bin script with a #USAGE spec ships a zsh completion generated from it (mise run zsh:completions:usage).
import { describe, expect, it } from "bun:test";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { repoRoot } from "./support/paths";

const BIN = join(repoRoot, "config/bin");
const COMPLETIONS = join(repoRoot, "config/zsh/opt/completions");
const scripts = readdirSync(BIN, { withFileTypes: true })
  .filter((e) => e.isFile() && e.name !== "README.md")
  .map((e) => e.name)
  .filter((name) => /^#USAGE /m.test(readFileSync(join(BIN, name), "utf8")));

const generate = (name: string) =>
  Bun.spawnSync(["usage", "generate", "completion", "zsh", name, "-f", join(BIN, name)], { stdout: "pipe" }).stdout.toString();

describe.skipIf(!Bun.which("usage"))("usage completions", () => {
  it("finds the usage scripts", () => expect(scripts).toContain("dots"));
  it.each(scripts)("_%s is committed and matches its #USAGE spec", (name) => {
    const file = join(COMPLETIONS, `_${name}`);
    expect(existsSync(file)).toBe(true);
    // A stale completion means a #USAGE block changed without `mise run zsh:completions:usage`.
    expect(readFileSync(file, "utf8")).toBe(generate(name));
  });
  it("dots <Tab> offers its subcommands, not files", () => {
    const r = Bun.spawnSync(["usage", "complete-word", "--shell", "zsh", "-f", join(BIN, "dots"), "--", "dots", ""], { stdout: "pipe" });
    const words = r.stdout.toString().split("\n").filter(Boolean).map((line) => line.split("\t")[0]);
    expect(words).toContain("env");
    expect(words).toContain("palette");
  });
});
