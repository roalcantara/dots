#!/usr/bin/env bun
// zim::mise_cache (config/zsh/opt/rc.d/zim.zsh) caches `mise activate zsh`, which bakes in the PATH of the shell that
// wrote it. A shell with a thin PATH (an editor terminal, an agent, cron) must not cache a PATH without the system
// dirs: every later terminal would lose /usr/sbin and /sbin (gopass edit then fails on newfs_hfs).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const ZSH = Bun.which("zsh") ?? "zsh";
// Only the function: sourcing zim.zsh runs the whole ZIM start-up and then unfunctions its steps.
const FN = readFileSync(join(import.meta.dir, "../../../config/zsh/opt/rc.d/zim.zsh"), "utf8")
  .match(/^zim::mise_cache\(\) \{\n[\s\S]*?^\}\n/m)?.[0] ?? "";
let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "zim-mise-cache-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, "zim", "modules", "zim-mise"), { recursive: true });
  // Stub mise: `activate zsh` bakes in the PATH it was run with, or, like the real one, the original PATH an
  // activated parent shell passed down in __MISE_ORIG_PATH.
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\n[ "$1" = activate ] && printf "export PATH='%s'\\n" "\${__MISE_ORIG_PATH:-$PATH}"\nexit 0\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const cachedPath = (path: string, env: Record<string, string> = {}) => {
  const p = Bun.spawnSync([ZSH, "-fc", `${FN}
zim::mise_cache`], {
    env: { HOME: t, ZIM_HOME: join(t, "zim"), ZDOTDIR: t, PATH: path, ...env }, stdout: "pipe", stderr: "pipe",
  });
  expect(p.exitCode).toBe(0);
  const act = join(t, "zim", "modules", "zim-mise", "mise-activate.zsh");
  return /export PATH='([^']*)'/.exec(readFileSync(act, "utf8"))?.[1]?.split(":") ?? [];
};

describe.skipIf(!Bun.which("zsh"))("zim::mise_cache", () => {
  it("adds the missing system dirs when the writing shell's PATH lacks them", () => {
    const p = cachedPath(`${join(t, "bin")}:/usr/bin:/bin`);
    for (const d of ["/usr/bin", "/bin", "/usr/sbin", "/sbin"].filter((d) => existsSync(d))) expect(p).toContain(d);
  });

  it("ignores the original PATH an activated parent shell passed down", () => {
    const p = cachedPath(`${join(t, "bin")}:/usr/bin:/bin:/usr/sbin:/sbin`, { __MISE_ORIG_PATH: "/usr/bin:/bin", __MISE_DIFF: "x" });
    expect(p).toContain(join(t, "bin"));
    for (const d of ["/usr/sbin", "/sbin"].filter((d) => existsSync(d))) expect(p).toContain(d);
  });

  it("keeps the shell's own order first and adds no duplicates", () => {
    const p = cachedPath(`${join(t, "bin")}:/sbin:/usr/bin:/bin`);
    expect(p.slice(0, 4)).toEqual([join(t, "bin"), "/sbin", "/usr/bin", "/bin"]);
    expect(new Set(p).size).toBe(p.length);
  });

  it("leaves the shell's own PATH unchanged", () => {
    const p = Bun.spawnSync([ZSH, "-fc", `${FN}
before=$PATH; zim::mise_cache; [[ $PATH == $before ]] && print same`], {
      env: { HOME: t, ZIM_HOME: join(t, "zim"), ZDOTDIR: t, PATH: `${join(t, "bin")}:/usr/bin:/bin` }, stdout: "pipe",
    });
    expect(p.stdout.toString().trim()).toBe("same");
  });
});
