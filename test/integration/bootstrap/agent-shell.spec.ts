#!/usr/bin/env bun
// Agent shell invariants: shared commands layout, bashrc activation without _has_command, and bash word splitting.
import { describe, expect, it } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (p: string) => readFileSync(join(REPO, p), "utf8");
const bashrc = read("config/bash/bashrc");

describe("agent shell", () => {
  it("keeps every command in config/agents/commands", () => {
    expect(existsSync(join(REPO, "config/claude/commands"))).toBe(false);
    expect(existsSync(join(REPO, "config/agents/commands/opsx/apply.md"))).toBe(true);
  });

  it("bashrc activates mise and loads the bash shell integration in VS Code", () => {
    expect(bashrc).toContain('eval "$(mise activate bash)"');
    expect(bashrc).toContain("--locate-shell-integration-path bash");
    expect(bashrc).not.toContain("_has_command");
  });

  it("bash splits an unquoted variable, as agents expect", () => {
    const p = Bun.spawnSync(["bash", "--norc", "--noprofile", "-c", 'list="a b c"; n=0; for x in $list; do n=$((n+1)); done; echo $n']);
    expect(p.stdout.toString().trim()).toBe("3");
  });
});
