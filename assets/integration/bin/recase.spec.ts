#!/usr/bin/env bun
import { describe, expect, it, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { scriptPath } from "./support/paths";

const script = scriptPath("recase");

describe("recase", () => {
  let tmpDir: string;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "recase-test-"));
  });

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true });
  });

  describe("help and validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("recase");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("recase");
    });

    it("exits with status 1 when path is missing", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });

  describe("file renaming", () => {
    it("renames a single file to kebab-case with --kebab", () => {
      const srcFile = join(tmpDir, "MyTestFile.ts");
      writeFileSync(srcFile, "content");

      const r = Bun.spawnSync([script, srcFile, "--kebab"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(existsSync(join(tmpDir, "my-test-file.ts"))).toBe(true);
      expect(existsSync(srcFile)).toBe(false);
    });

    it("renames files recursively in a directory with -f -r --snake", () => {
      const subDir = join(tmpDir, "subDirFolder");
      mkdirSync(subDir);
      const file1 = join(subDir, "camelCaseFile.txt");
      writeFileSync(file1, "hello");

      const r = Bun.spawnSync([script, tmpDir, "-f", "-r", "--snake"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(existsSync(join(subDir, "camel_case_file.txt"))).toBe(true);
    });
  });
});
