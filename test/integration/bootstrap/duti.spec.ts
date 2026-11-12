#!/usr/bin/env bun
// config/duti/defaults.duti: the default apps the post-defaults hook sets with duti. duti exits 0 even on a bad
// line, so the format is checked here: whole-line comments only, real UTIs (dynamic dyn.* ones fail with error -50).
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const lines = readFileSync(join(REPO, "config/duti/defaults.duti"), "utf8").split("\n")
  .filter((l) => l.trim() !== "" && !l.startsWith("#"));

describe("default apps (config/duti/defaults.duti)", () => {
  it("has bundle ID, UTI and role on every line, tab-separated, with no trailing comments", () => {
    expect(lines.length).toBeGreaterThan(0);
    for (const l of lines) expect(l).toMatch(/^[\w.-]+\t[\w.-]+\tall$/);
  });

  it("names real UTIs only, never a video type such as .ts's", () => {
    for (const l of lines) {
      const uti = l.split("\t")[1] ?? "";
      expect(uti.startsWith("dyn.")).toBe(false);
      expect(uti).not.toBe("public.mpeg-2-transport-stream");
    }
  });

  it("opens text, code and config in VS Code", () => {
    const utis = lines.filter((l) => l.startsWith("com.microsoft.VSCode\t")).map((l) => l.split("\t")[1]);
    for (const u of ["public.plain-text", "public.source-code", "public.shell-script", "public.json", "public.yaml",
      "net.daringfireball.markdown"]) expect(utis).toContain(u);
  });

  it("is linked into ~/.config and installed on macOS", () => {
    expect(readFileSync(join(REPO, "config/mise/conf.d/dotfiles.toml"), "utf8"))
      .toContain('"~/.config/duti" = { source = "~/.local/share/dots/config/duti", relative = true }');
    expect(readFileSync(join(REPO, "config/homebrew/Brewfile"), "utf8")).toContain('brew "duti" if OS.mac?');
  });
});
