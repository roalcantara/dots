#!/usr/bin/env bun
// The post-dotfiles soft steps: bat's theme cache is rebuilt when the package is there, and a failure only warns.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

let t: string;
let bin: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "dotfiles-steps-"));
  bin = join(t, "bin");
  mkdirSync(bin);
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  writeFileSync(join(bin, "brew"), "#!/bin/sh\nexit 0\n");
  chmodSync(join(bin, "brew"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const stub = (name: string, body = "") => {
  writeFileSync(join(bin, name), `#!/bin/sh\nprintf '%s\\n' "$*" >> "${t}/${name}.log"\n${body}`);
  chmodSync(join(bin, name), 0o755);
};
const log = (name: string) => (existsSync(join(t, `${name}.log`)) ? readFileSync(join(t, `${name}.log`), "utf8") : "");

const run = () => runStep("bat/cache.sh", { PATH: `${bin}:/usr/bin:/bin`, HOME: t, DOTS_DIR: t });

describe("bat/cache.sh", () => {
  it("rebuilds the cache when bat is installed", () => {
    stub("bat");
    const r = run();
    expect(r.code).toBe(0);
    expect(log("bat").trim()).toBe("cache --build");
  });

  it("does nothing and says nothing without bat", () => {
    const r = run();
    expect(r.code).toBe(0);
    expect(r.out + r.err).toBe("");
  });

  it("a failed build only warns", () => {
    stub("bat", "exit 1\n");
    const r = run();
    expect(r.code).toBe(0);
    expect(r.err).toContain("bat cache --build failed, continuing");
  });
});
