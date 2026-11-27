#!/usr/bin/env bun
// Lig, the completion popup (docs/THEME.md): the cached shell integration (`mise run zsh:lig`), the bootstrap hook
// that writes it, and config/zsh/opt/rc.d/lig.zsh, which sources it without running `lig` at startup.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const THEMES = join(REPO, "config/theme/themes");

let t: string;
let bin: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "dots-lig-"));
  bin = join(t, "bin");
  mkdirSync(bin);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

// A fake on PATH that logs its arguments; `lig init zsh pre|post` prints a marker line.
const fake = (name: string, body = "") => {
  writeFileSync(join(bin, name), `#!/bin/sh\nprintf '%s\\n' "$*" >> "${t}/${name}.log"\n${body}`);
  chmodSync(join(bin, name), 0o755);
};
const fakeLig = () => fake("lig", `[ "$1 $2" = "init zsh" ] && printf '# %s\\n' "$3"\nexit 0\n`);
const log = (name: string) => (existsSync(join(t, `${name}.log`)) ? readFileSync(join(t, `${name}.log`), "utf8") : "");

describe("mise run zsh:lig", () => {
  const run = (path: string) =>
    Bun.spawnSync(["mise", "run", "zsh:lig"], {
      cwd: REPO,
      env: { ...process.env, PATH: path, DOTS_LIG_CACHE: join(t, "cache") },
      stdout: "pipe",
      stderr: "pipe",
    });
  // mise alone on PATH: its own folder (Homebrew's bin) also holds the real lig.
  const miseOnly = () => {
    mkdirSync(join(t, "mise-bin"), { recursive: true });
    symlinkSync(Bun.which("mise") as string, join(t, "mise-bin/mise"));
    return join(t, "mise-bin");
  };

  it("writes both cached blocks", () => {
    fakeLig();
    const r = run(`${bin}:${miseOnly()}:/usr/bin:/bin`);
    expect(r.exitCode).toBe(0);
    expect(readFileSync(join(t, "cache/pre.zsh"), "utf8")).toBe("# pre\n");
    expect(readFileSync(join(t, "cache/post.zsh"), "utf8")).toBe("# post\n");
    expect(readFileSync(join(t, "cache/bin"), "utf8")).toBe(`${realpathSync(join(bin, "lig"))}\n`);
  });

  it("fails clearly without lig", () => {
    const r = run(`${miseOnly()}:/usr/bin:/bin`);
    expect(r.exitCode).not.toBe(0);
    expect(r.stderr.toString()).toContain("brew install kevengoncalves/tap/lig");
    expect(existsSync(join(t, "cache/pre.zsh"))).toBe(false);
  });
});

describe("lig/zsh.sh", () => {
  const step = (extra: Record<string, string> = {}) =>
    runStep("lig/zsh.sh", {
      PATH: `${bin}:/usr/bin:/bin`,
      HOME: t,
      DOTS_DIR: t,
      DOTS_UNAME: "Darwin",
      ...extra,
    });

  it("asks mise to cache the integration when lig is installed", () => {
    fake("brew");
    fakeLig();
    fake("mise");
    const r = step();
    expect(r.code).toBe(0);
    expect(log("mise").trim()).toBe(`-C ${t} run zsh:lig`);
  });

  it("does nothing without lig", () => {
    fake("brew");
    fake("mise");
    const r = step();
    expect(r.code).toBe(0);
    expect(log("mise")).toBe("");
    expect(r.out + r.err).toBe("");
  });
});

describe("config/zsh/opt/rc.d/lig.zsh", () => {
  const MODULE = join(REPO, "config/zsh/opt/rc.d/lig.zsh");
  // The cached blocks only set a marker, so the module's own checks are what is tested. `from` is the binary the
  // cache records: the fake lig unless a test says otherwise.
  const cache = (from?: string) => {
    mkdirSync(join(t, "cache"), { recursive: true });
    writeFileSync(join(t, "cache/pre.zsh"), "LIG_PRE_RAN=1\n");
    writeFileSync(join(t, "cache/post.zsh"), "LIG_POST_RAN=1\n");
    writeFileSync(join(t, "cache/bin"), `${from ?? realpathSync(join(bin, "lig"))}\n`);
  };
  // The script goes in on stdin: `zsh -c` and `zsh file` are exactly the shells lig::pre must leave alone.
  const SCRIPT = `source ${MODULE}; lig::pre; lig::post; print -r -- "pre=\${LIG_PRE_RAN:-0} post=\${LIG_POST_RAN:-0}"`;
  const shell = (path = `${bin}:/usr/bin:/bin`, argv = ["zsh", "-f"]) => {
    const p = Bun.spawnSync(argv, {
      env: { PATH: path, HOME: t, DOTS_LIG_CACHE: join(t, "cache") },
      stdin: Buffer.from(SCRIPT),
      stdout: "pipe",
      stderr: "pipe",
    });
    return { out: p.stdout.toString().trim(), err: p.stderr.toString() };
  };

  it("the shell runs no lig process", () => {
    for (const file of [MODULE, join(REPO, "config/zsh/.zshrc")]) {
      const text = readFileSync(file, "utf8");
      expect(text).not.toContain("$(lig");
      expect(text).not.toContain("lig init");
    }
  });

  it("sources both blocks when the cache is fresh", () => {
    fakeLig();
    cache();
    expect(shell()).toEqual({ out: "pre=1 post=1", err: "" });
  });

  it("zsh -c and zsh <file> never enter Lig, so their command still runs", () => {
    fakeLig();
    cache();
    expect(shell(undefined, ["zsh", "-f", "-c", SCRIPT]).out).toBe("pre=0 post=1");
    writeFileSync(join(t, "script.zsh"), SCRIPT);
    expect(shell(undefined, ["zsh", "-f", join(t, "script.zsh")]).out).toBe("pre=0 post=1");
  });

  it("skips a cache made by another lig (an upgrade) with one line", () => {
    fakeLig();
    cache("/opt/homebrew/Cellar/lig/0.0.1/bin/lig");
    const r = shell();
    expect(r.out).toBe("pre=0 post=0");
    expect(r.err.trim().split("\n")).toHaveLength(1);
    expect(r.err).toContain("mise run zsh:lig");
  });

  it("without lig or a cache, stays silent", () => {
    fakeLig();
    expect(shell()).toEqual({ out: "pre=0 post=0", err: "" });
    cache();
    expect(shell("/usr/bin:/bin")).toEqual({ out: "pre=0 post=0", err: "" });
  });

  it("an interactive shell without a terminal never enters Lig", () => {
    const p = Bun.spawnSync(
      ["env", "-i", `HOME=${process.env.HOME}`, `PATH=${process.env.PATH}`, "TERM=xterm-256color", `ZDOTDIR=${process.env.HOME}/.config/zsh`, "zsh", "-ic", "print -r -- lig=${_lig_loaded:-none}"],
      { stdout: "pipe", stderr: "pipe" },
    );
    expect(p.stdout.toString()).toContain("lig=none");
  });
});
