#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { join } from "node:path";
import { binRoot } from "./support/paths";

const helpers = join(binRoot, "src/helpers");

function runZsh(snippet: string, opts: { pipe: boolean } = { pipe: false }) {
  const script = `source ${helpers}\n${snippet}`;
  const cmd = opts.pipe ? ["zsh", "-c", `{ ${script} } | cat`] : ["zsh", "-c", script];
  const r = Bun.spawnSync(cmd, { stdout: "pipe", stderr: "pipe" });
  return {
    code: r.exitCode,
    out: new TextDecoder().decode(r.stdout).trim(),
    err: new TextDecoder().decode(r.stderr).trim(),
  };
}

describe("helpers", () => {
  describe("h::has_bin", () => {
    it("finds an existing binary", () => {
      expect(runZsh(`h::has_bin git && echo found`).out).toBe("found");
    });

    it("rejects a missing binary", () => {
      expect(runZsh(`h::has_bin definitely-not-a-real-binary || echo missing`).out).toBe("missing");
    });

    it("finds an existing binary even when stdout is not a TTY", () => {
      expect(runZsh(`h::has_bin git && echo found`, { pipe: true }).out).toBe("found");
    });
  });

  describe("h::needs_command", () => {
    it("succeeds for an existing binary when stdout is not a TTY", () => {
      expect(runZsh(`h::needs_command git && echo ok`, { pipe: true }).out).toBe("ok");
    });

    it("exits non-zero for a missing binary", () => {
      expect(runZsh(`h::needs_command definitely-not-a-real-binary`).code).not.toBe(0);
    });
  });
});
