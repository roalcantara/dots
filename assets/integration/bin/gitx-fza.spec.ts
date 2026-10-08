#!/usr/bin/env bun
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type AddFixture, gitEnv, makeAddFixture, makeCleanRepo, makeNonRepo, stagedFiles } from "./support/add-fixture";
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

  describe("picker", () => {
    it("multi-selects and returns only the path field", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--multi\n");
      expect(args).toContain("--delimiter=\t\n");
      expect(args).toContain("--accept-nth=2\n");
    });

    it("shows every shortcut in a bordered keys header", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--header-border=rounded\n");
      expect(args).toContain("--header-label= keys \n");
      for (const key of ["tab toggle", "⇧tab toggle↑", "^a all", "^d none", "enter add", "^p patch", "^/ preview", "esc cancel"]) {
        expect(args).toContain(key);
      }
    });

    it("opens the diff preview on start", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--preview-window=right,60%,border-left,nohidden\n");
      expect(args).toContain("git diff --no-index --color=always -- /dev/null {2}");
      expect(args).toContain("git diff --color=always -- {2}");
    });

    it("binds select-all, deselect-all, preview toggle and patch mode", () => {
      const { args } = runFza(fx.work);
      expect(args).toContain("--bind=ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview\n");
      expect(args).toContain("--bind=ctrl-p:become(git add -p -- {+2})\n");
    });
  });

  describe("staging", () => {
    it("stages the selected paths, including spaces and untracked files", () => {
      const r = runFza(fx.work, { select: ["with space.txt", "newdir/sub/n.txt"] });
      expect(r.exitCode).toBe(0);
      const staged = stagedFiles(fx.work);
      expect(staged).toContain("with space.txt");
      expect(staged).toContain("newdir/sub/n.txt");
      expect(staged).not.toContain("modified.txt");
    });

    it("prints git status after staging", () => {
      const r = runFza(fx.work, { select: ["modified.txt"] });
      expect(r.output).toContain("M  modified.txt");
    });

    it("stages nothing when fzf is cancelled", () => {
      const before = stagedFiles(fx.work);
      const r = runFza(fx.work, { exit: 130 });
      expect(r.exitCode).toBe(0);
      expect(stagedFiles(fx.work)).toEqual(before);
    });

    it("stages nothing on an empty selection", () => {
      const before = stagedFiles(fx.work);
      const r = runFza(fx.work, { select: [] });
      expect(r.exitCode).toBe(0);
      expect(stagedFiles(fx.work)).toEqual(before);
    });
  });
});

describe("gitx fza guards", () => {
  it("says there is nothing to add in a clean repo without opening fzf", () => {
    const fx = makeCleanRepo();
    try {
      const r = runFza(fx.work);
      expect(r.exitCode).toBe(0);
      expect(r.output).toContain("Nothing to add");
      expect(r.args).toBe("");
    } finally {
      fx.cleanup();
    }
  });

  it("fails outside a git repository", () => {
    const fx = makeNonRepo();
    try {
      const r = runFza(fx.work);
      expect(r.exitCode).toBe(1);
      expect(r.output).toContain("Not a git repository");
      expect(r.args).toBe("");
    } finally {
      fx.cleanup();
    }
  });
});
