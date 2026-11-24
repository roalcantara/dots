#!/usr/bin/env bun
// zsh completion for lida: the committed _lida is `lida completion zsh`, and it completes by calling back
// `lida __complete_word__`, so task IDs and tags come from the TODO file in the current directory.
import { describe, expect, it } from "bun:test";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "../../..");
const FIXTURE = join(ROOT, "test/integration/blog/fixtures/TODO.yaml");
const COMPLETIONS = join(ROOT, "config/zsh/opt/completions");
const HOME = process.env.HOME as string;
const LIDA = Bun.which("lida", {
  PATH: `${process.env.PATH ?? ""}:${process.env.CARGO_HOME ?? join(HOME, ".local/share/cargo")}/bin`,
});
const committed = () => readFileSync(join(COMPLETIONS, "_lida"), "utf8");

const fixtureDir = () => {
  const dir = mkdtempSync(join(tmpdir(), "lida-fixture-"));
  copyFileSync(FIXTURE, join(dir, "TODO.yaml"));
  mkdirSync(join(dir, ".lida"));
  writeFileSync(join(dir, ".lida/config"), "yaml\n");
  return dir;
};

// The first column of each candidate line `lida __complete_word__` prints, sorted.
const complete = (line: string) => {
  const p = Bun.spawnSync([LIDA as string, "__complete_word__", "--shell", "zsh", "--line", line], {
    cwd: fixtureDir(), stdout: "pipe", stderr: "pipe",
  });
  expect(p.exitCode).toBe(0);
  return p.stdout.toString().split("\n").filter(Boolean).map((l) => l.split("\t")[0]).sort();
};

describe("lida zsh completion", () => {
  it("_lida is lida's own script, with nothing left of todo-cli", () => {
    expect(committed().startsWith("#compdef lida\n")).toBe(true);
    expect(committed()).not.toContain("todo");
  });

  it.skipIf(!Bun.which("zsh"))("compinit binds lida to _lida", () => {
    const r = Bun.spawnSync(["zsh", "-fc",
      `fpath=(${COMPLETIONS} $fpath); autoload -Uz compinit; compinit -D -u; print $_comps[lida]`]);
    expect(r.stdout.toString().trim()).toBe("_lida");
  });

  describe.skipIf(!LIDA)("with lida installed", () => {
    it("the committed _lida is what `lida completion zsh` writes (mise run zsh:completions:lida)", () => {
      const p = Bun.spawnSync([LIDA as string, "completion", "zsh"], { stdout: "pipe" });
      expect(p.stdout.toString()).toBe(committed());
    });
    it("task IDs come from the TODO file", () => {
      const ids = (Bun.YAML.parse(readFileSync(FIXTURE, "utf8")) as { tasks: { id: string }[] }).tasks.map((t) => t.id);
      expect(complete("lida done ")).toEqual(ids.sort());
    });
    it("tags come from the TODO file", () => {
      expect(complete("lida list -t ")).toEqual(["post", "series", "topic-1"]);
    });
    it("priorities are fixed", () => {
      expect(complete("lida add -p ")).toEqual(["high", "low", "medium", "none"]);
    });
  });
});
