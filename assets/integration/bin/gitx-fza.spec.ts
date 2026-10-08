#!/usr/bin/env bun
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type AddFixture, gitEnv, makeAddFixture } from "./support/add-fixture";
import { scriptPath } from "./support/paths";

const script = scriptPath("gitx");

// fzf test double: records argv (one per line) and stdin, prints
// $FZF_STUB_SELECT as the selection, exits with $FZF_STUB_EXIT.
const STUB = `#!/bin/sh
log="\${FZF_STUB_LOG:?}"
: > "$log.args"
for a in "$@"; do printf '%s\\n' "$a" >> "$log.args"; done
cat > "$log.stdin"
[ -n "\${FZF_STUB_SELECT:-}" ] && printf '%s\\n' "$FZF_STUB_SELECT"
exit "\${FZF_STUB_EXIT:-0}"
`;

let stubDir = "";
let log = "";

beforeAll(() => {
  stubDir = mkdtempSync(join(tmpdir(), "gitx-fza-stub-"));
  writeFileSync(join(stubDir, "fzf"), STUB);
  chmodSync(join(stubDir, "fzf"), 0o755);
  log = join(stubDir, "log");
});

afterAll(() => rmSync(stubDir, { recursive: true, force: true }));

interface FzaRun {
  exitCode: number;
  output: string; // stdout + stderr
  stdin: string; // what gitx piped into fzf ("" if fzf never ran)
  args: string; // fzf argv, one arg per line
}

function read(path: string): string {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

function runFza(cwd: string, opts: { select?: string[]; exit?: number } = {}): FzaRun {
  rmSync(`${log}.stdin`, { force: true });
  rmSync(`${log}.args`, { force: true });
  const r = Bun.spawnSync([script, "fza"], {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
    env: {
      ...gitEnv,
      PATH: `${stubDir}:${Bun.env.PATH}`,
      FZF_STUB_LOG: log,
      FZF_STUB_SELECT: (opts.select ?? []).join("\n"),
      FZF_STUB_EXIT: String(opts.exit ?? 0),
    },
  });
  const dec = new TextDecoder();
  return {
    exitCode: r.exitCode,
    output: dec.decode(r.stdout) + dec.decode(r.stderr),
    stdin: read(`${log}.stdin`),
    args: read(`${log}.args`),
  };
}

describe("gitx fza", () => {
  let fx: AddFixture;
  beforeEach(() => {
    fx = makeAddFixture();
  });
  afterEach(() => fx.cleanup());

  describe("candidates", () => {
    it("lists only files git add would change, as XY<TAB>path", () => {
      const r = runFza(fx.work);
      expect(r.stdin).toBe(
        [
          " D\tdeleted.txt",
          " M\tmodified.txt",
          "RM\tnew-name.txt",
          "MM\tpartial.txt",
          " M\twith space.txt",
          "??\tnewdir/sub/n.txt",
        ].join("\n") + "\n",
      );
    });

    it("excludes fully staged files", () => {
      expect(runFza(fx.work).stdin).not.toContain("staged.txt");
    });
  });
});
