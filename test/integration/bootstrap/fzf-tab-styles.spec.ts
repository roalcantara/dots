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
  it("any other command previews files, else coloured --help via cmdhelp; specific previews still win", () => {
    const generic = styles(`zstyle -s ':fzf-tab:complete:vim:argument-rest' fzf-preview p; print -r -- $p`);
    expect(generic).toContain("cmdhelp");
    expect(generic).toContain("DOTS_LA_CMD");
    expect(generic).toContain("bat --style=numbers,changes");
    expect(styles(`zstyle -s ':fzf-tab:complete:git-log:argument-1' fzf-preview p; print -r -- $p`)).toContain("git show");
  });
  it("menus are framed and themed", () => {
    const flags = styles(`zstyle -a ':fzf-tab:*' fzf-flags f; print -rl -- $f`);
    expect(flags).toContain("--style=full");
    const theme = styles(`print -r -- $FZF_THEME_OPTS`);
    const bg = theme.split(/\s+/).find((flag) => flag.startsWith("--color=bg:"));
    expect(bg).toBeString();
    expect(flags).toContain(bg as string);
  });
  it("no ls -l rows", () => {
    const value = styles(`zstyle -s ':completion:*' file-list v && print -r -- $v || print unset`).trim();
    expect(value).not.toBe("all");
  });
  it("la and the directory preview share one command", () => {
    const command = styles("print -r -- $DOTS_LA_CMD").trim();
    expect(command).toContain("eza");
    expect(command).toContain("--color=always");
    expect(styles("alias la").trim()).toContain(command);
    expect(styles(`zstyle -s ':fzf-tab:complete:cd:*' fzf-preview p; print -r -- $p`)).toContain("DOTS_LA_CMD");
  });
  it("group colours follow the theme", () => {
    const theme = styles(`print -r -- \${(j:|:)DOTS_FZF_TAB_GROUP_COLORS}`).trim();
    const groups = styles(`zstyle -a ':fzf-tab:*' group-colors c; print -r -- \${(j:|:)c}`).trim();
    expect(theme.length).toBeGreaterThan(0);
    expect(groups).toBe(theme);
  });
});
