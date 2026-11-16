#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { existsSync } from "node:fs";
import { join } from "node:path";

const HOME = process.env.HOME as string;

const styles = (script: string) => {
  const p = Bun.spawnSync(
    ["env", "-i", `HOME=${HOME}`, "TERM=xterm-256color", `ZDOTDIR=${HOME}/.config/zsh`, "zsh", "-ic", script],
    {
      stdout: "pipe",
      stderr: "pipe",
    },
  );
  return p.stdout.toString();
};

describe.skipIf(!existsSync(join(HOME, ".config/zsh/.zshrc")))("fzf-tab effective styles", () => {
  it("zsh's own menu is off, per fzf-tab", () =>
    expect(styles(`zstyle -s ':completion:*' menu m; print -r -- $m`).trim()).toBe("no"));
  it("descriptions carry no escape sequences, so fzf-tab can group", () =>
    expect(styles(`zstyle -s ':completion:*:descriptions' format f; print -r -- $f`).trim()).toBe("[%d]"));
  it("list-colors is split into entries", () =>
    expect(Number(styles(`zstyle -a ':completion:*' list-colors c; print $#c`).trim())).toBeGreaterThan(1));
  it("Tab keeps continuing; the dead tab:accept bind is gone", () => {
    expect(styles(`zstyle -s ':fzf-tab:*' continuous-trigger t; print -r -- $t`).trim()).toBe("tab");
    expect(styles(`zstyle -a ':fzf-tab:*' fzf-flags f; print -rl -- $f`)).not.toContain("--bind=tab:accept");
  });
  it("no zstyles fzf-tab never reads", () => {
    expect(styles(`zstyle -L ':fzf-tab:complete:*' menu; zstyle -L ':fzf-tab:*' list-colors`).trim()).toBe("");
  });
  it("previews: todo task details and mise tool info", () => {
    expect(styles(`zstyle -L ':fzf-tab:complete:todo*:*' fzf-preview`)).toContain("todo list --tasks");
    expect(styles(`zstyle -L ':fzf-tab:complete:mise:argument-rest' fzf-preview`)).toContain("mise tool");
  });
});
