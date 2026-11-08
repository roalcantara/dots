#!/usr/bin/env bun
// Coding agents run their shell commands in bash, not the login zsh: zsh leaves an unquoted $var
// unsplit, so the bash idioms agents write (for x in $list) silently run once.
// Claude Code reads CLAUDE_CODE_SHELL from ~/.claude/settings.json; Copilot chat reads
// chat.tools.terminal.terminalProfile.<platform> from the VS Code settings.
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (p: string) => readFileSync(join(REPO, p), "utf8");
const claude = JSON.parse(read("config/claude/settings.json"));
const vscode = Bun.JSONC.parse(read("config/vscode/settings.json")) as Record<string, any>;
const links = (Bun.TOML.parse(read("config/mise/conf.d/dotfiles.toml")) as any).dotfiles;
const bashrc = read("config/bash/bashrc");

describe("agent shell", () => {
  it("Claude Code runs the Bash tool in Homebrew's bash", () => {
    expect(claude.env.CLAUDE_CODE_SHELL).toBe("/opt/homebrew/bin/bash");
  });

  it("links ~/.claude/settings.json to config/claude/settings.json", () => {
    expect(links["~/.claude/settings.json"]).toEqual({
      source: "~/.local/share/dots/config/claude/settings.json",
      relative: true,
    });
  });

  it("links ~/.claude/agents to config/claude/agents", () => {
    expect(links["~/.claude/agents"]).toEqual({
      source: "~/.local/share/dots/config/claude/agents",
      relative: true,
    });
    expect(links["~/.config/claude"].source).toBe("~/.local/share/dots/config/claude");
  });

  it("the lookup agent runs on Haiku with read-only tools", () => {
    const front = read("config/claude/agents/lookup.md").match(/^---\n([\s\S]*?)\n---\n/)?.[1] ?? "";
    const field = (k: string) => front.match(new RegExp(`^${k}: (.*)$`, "m"))?.[1];
    expect(field("name")).toBe("lookup");
    expect(field("model")).toBe("haiku");
    expect(field("tools")?.split(/,\s*/).sort()).toEqual(["Glob", "Grep", "Read"]);
  });

  it("Copilot chat runs terminal commands in a bash login shell", () => {
    expect(vscode["chat.tools.terminal.terminalProfile.osx"]).toEqual({ path: "/opt/homebrew/bin/bash", args: ["-l"] });
    expect(vscode["chat.tools.terminal.terminalProfile.linux"]).toEqual({ path: "bash", args: ["-l"] });
  });

  it("leaves the integrated terminal on zsh", () => {
    expect(vscode["terminal.integrated.defaultProfile.osx"]).toBe("zsh");
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
