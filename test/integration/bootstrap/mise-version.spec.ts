#!/usr/bin/env bun
// mise run mise:version: lists every MISE_VERSION pin, --check fails on drift from this Mac's mise, and
// --sync rewrites the pins (keeping each file's v prefix) to it.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const SCRIPT = join(REPO, ".mise/tasks/mise/version.sh");
// Built at run time so this file never looks like a pin to `git grep`.
const PIN = "MISE_VERSION";
const OLD = "2026.11.4";
const LOCAL = "2026.11.14";

let t: string;
const install = () => join(t, "install");
const dockerfile = () => join(t, "distros", "debian", "Dockerfile");
const pinLine = (v: string) => `${PIN}="${v}"`;
const dockerLine = (v: string) => `RUN curl -fsSL https://mise.run | ${PIN}=v${v} sh\n`;

function git(...args: string[]) {
  const p = Bun.spawnSync(["git", ...args], { cwd: t, stdout: "pipe", stderr: "pipe" });
  if (p.exitCode !== 0) throw new Error(p.stderr.toString());
}

beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "mise-version-"));
  mkdirSync(join(t, "distros", "debian"), { recursive: true });
  writeFileSync(install(), `#!/usr/bin/env bash\n${pinLine(OLD)}\n`);
  writeFileSync(dockerfile(), dockerLine(OLD));
  git("init", "-q");
  git("add", "-A");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function run(args: string[] = [], env: Record<string, string> = {}) {
  const p = Bun.spawnSync(["bash", SCRIPT, ...args], {
    env: {
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      HOME: t,
      DOTS_DIR: t,
      DOTS_MISE_VERSION: LOCAL,
      DOTS_UNAME: "Darwin",
      ...env,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe("mise:version", () => {
  it("lists every pin with file, line, pinned and local version", () => {
    const r = run();
    expect(r.code).toBe(0);
    expect(r.out.trim().split("\n").sort()).toEqual([
      `distros/debian/Dockerfile:1\tv${OLD}\t${LOCAL}`,
      `install:2\t${OLD}\t${LOCAL}`,
    ]);
  });

  it("--check exits 0 when all pins match", () => {
    writeFileSync(install(), `#!/usr/bin/env bash\n${pinLine(LOCAL)}\n`);
    writeFileSync(dockerfile(), dockerLine(LOCAL));
    git("add", "-A");
    const r = run(["--check"]);
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
  });

  it("--check exits 1 and names the drifting file when one differs", () => {
    const r = run(["--check"]);
    expect(r.code).toBe(1);
    expect(r.err).toContain("install:2");
    expect(r.err).toContain(LOCAL);
  });

  it("--sync rewrites install (no v) and the Dockerfile (v prefix) to the local version", () => {
    const r = run(["--sync"]);
    expect(r.code).toBe(0);
    expect(readFileSync(install(), "utf8")).toBe(`#!/usr/bin/env bash\n${pinLine(LOCAL)}\n`);
    expect(readFileSync(dockerfile(), "utf8")).toBe(dockerLine(LOCAL));
  });

  it("--sync is idempotent", () => {
    expect(run(["--sync"]).code).toBe(0);
    const once = [readFileSync(install(), "utf8"), readFileSync(dockerfile(), "utf8")];
    expect(run(["--sync"]).code).toBe(0);
    expect([readFileSync(install(), "utf8"), readFileSync(dockerfile(), "utf8")]).toEqual(once);
  });

  it("--sync refuses off macOS and changes nothing", () => {
    const before = [readFileSync(install(), "utf8"), readFileSync(dockerfile(), "utf8")];
    const r = run(["--sync"], { DOTS_UNAME: "Linux" });
    expect(r.code).toBe(1);
    expect(r.err).toContain("run --sync on macOS");
    expect([readFileSync(install(), "utf8"), readFileSync(dockerfile(), "utf8")]).toEqual(before);
  });

  it("finds a pin added in a new file", () => {
    writeFileSync(join(t, "ci.sh"), `${PIN}=v2026.1.1\n`);
    git("add", "-A");
    const r = run();
    expect(r.code).toBe(0);
    expect(r.out).toContain(`ci.sh:1\tv2026.1.1\t${LOCAL}`);
  });

  it("ignores code examples under docs/ and config/kodexb/", () => {
    mkdirSync(join(t, "docs"), { recursive: true });
    mkdirSync(join(t, "config", "kodexb"), { recursive: true });
    writeFileSync(join(t, "docs", "note.md"), "Run `" + PIN + "=v2026.1.1`\n");
    writeFileSync(join(t, "config", "kodexb", "note.yml"), `- ${PIN}=v2026.1.1\n`);
    git("add", "-A");
    const r = run(["--check"]);
    expect(r.code).toBe(1);
    expect(r.out).not.toContain("docs/note.md");
    expect(r.out).not.toContain("config/kodexb/note.yml");
    expect(r.err).not.toContain("docs/note.md");
  });

  it("--check and --sync are mutually exclusive", () => {
    const r = run(["--check", "--sync"]);
    expect(r.code).toBe(2);
    expect(r.err).toContain("mutually exclusive");
  });
});
