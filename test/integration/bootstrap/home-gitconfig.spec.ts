#!/usr/bin/env bun
// dots owns git's config in ~/.config/git/config. A real ~/.gitconfig is read after it and wins: `gh auth setup-git`
// once wrote a since-removed mise gh's absolute path there, so every https push asked for a password. install gives
// the bootstrap run a gh credential helper through the environment only, and bootstrap and `mise doctor project`
// report a stray ~/.gitconfig (the doctor check is in config/mise/conf.d/tasks.toml).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { stepsOf, tasksToml } from "./parts";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const INSTALL = readFileSync(join(REPO, "install"), "utf8");
const SNIPPET = INSTALL.match(/# gh-git-helper: begin\n[\s\S]*?# gh-git-helper: end\n/)?.[0] ?? "";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "home-gitconfig-"));
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

// The helpers git sees for github.com when install's environment is applied, with no config files at all.
function helpers(history: string) {
  const p = Bun.spawnSync(["bash", "-c", `HISTORY="${history}"\n${SNIPPET}env "\${gh_git_env[@]}" git config --get-all credential.https://github.com.helper`], {
    env: { PATH: "/usr/bin:/bin", HOME: t, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_NOSYSTEM: "1" },
    stdout: "pipe", stderr: "pipe",
  });
  return p.stdout.toString().split("\n").slice(0, -1);
}

describe("install's gh credential helper", () => {
  it("never runs gh auth setup-git, which writes ~/.gitconfig", () => {
    expect(INSTALL).not.toContain("setup-git");
  });

  it("gives the adopt run the gh helper through the environment, clearing other helpers first", () => {
    expect(helpers("https://github.com/o/dots-history.git")).toEqual(["", "!mise exec gh@latest -- gh auth git-credential"]);
  });

  it("sets nothing for a history repo outside github.com", () => {
    expect(helpers("git@example.com:o/h.git")).toEqual([]);
  });

  it("applies it to the mise bootstrap --adopt run", () => {
    expect(INSTALL).toMatch(/env "\$\{gh_git_env\[@\]\}" mise bootstrap --adopt/);
  });
});

describe("bootstrap:git:home-config", () => {
  it("warns when a real ~/.gitconfig exists, and continues", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\n  name = x\n");
    const r = runStep("git/home-config.sh", { HOME: t, PATH: "/usr/bin:/bin" });
    expect(r.code).toBe(0);
    expect(r.err).toContain("~/.gitconfig overrides the dots git config");
  });

  it("is silent without ~/.gitconfig", () => {
    const r = runStep("git/home-config.sh", { HOME: t, PATH: "/usr/bin:/bin" });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
  });

  it("runs in the git part, right after the git filters", () => {
    const order = stepsOf("git");
    expect(order.indexOf("bootstrap:git:home-config")).toBe(order.indexOf("bootstrap:git:filters") + 1);
  });
});

describe("mise doctor project", () => {
  it("has a check that fails while ~/.gitconfig exists", () => {
    const run = tasksToml().doctor.checks["home-gitconfig"]?.run ?? "false-not-defined";
    const sh = (home: string) => Bun.spawnSync(["bash", "-c", run], { env: { HOME: home, PATH: "/usr/bin:/bin" } }).exitCode;
    expect(sh(t)).toBe(0);
    writeFileSync(join(t, ".gitconfig"), "");
    expect(sh(t)).not.toBe(0);
  });
});
