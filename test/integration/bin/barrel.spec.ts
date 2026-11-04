#!/usr/bin/env bun
import { describe, expect, it, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync, existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { scriptPath } from "./support/paths";

const script = scriptPath("barrel");

describe("barrel", () => {
  let tmpDir: string;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "barrel-test-"));
  });

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true });
  });

  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("barrel");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("barrel");
    });

    it("exits with status 1 when required folder is missing or invalid", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });

    it("exits with status 1 when folder does not exist", () => {
      const r = Bun.spawnSync([script, "/nonexistent-folder-xyz"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });

  describe("barrel generation", () => {
    it("generates index.ts for ts files", () => {
      writeFileSync(join(tmpDir, "foo.ts"), "export const foo = 1;");
      writeFileSync(join(tmpDir, "bar.ts"), "export const bar = 2;");

      const r = Bun.spawnSync([script, tmpDir], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);

      const indexPath = join(tmpDir, "index.ts");
      expect(existsSync(indexPath)).toBe(true);
      const content = readFileSync(indexPath, "utf8");
      expect(content).toContain("export * from './bar.ts'");
      expect(content).toContain("export * from './foo.ts'");
    });

    it("generates index.js with --js flag", () => {
      writeFileSync(join(tmpDir, "foo.js"), "export const foo = 1;");

      const r = Bun.spawnSync([script, tmpDir, "--js"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);

      const indexPath = join(tmpDir, "index.js");
      expect(existsSync(indexPath)).toBe(true);
      const content = readFileSync(indexPath, "utf8");
      expect(content).toContain("export * from './foo.js'");
    });
  });
});
