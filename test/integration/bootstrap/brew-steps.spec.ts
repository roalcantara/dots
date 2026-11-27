#!/usr/bin/env bun
// The post-packages steps on their own: up-to-date checks and the profile passed to brew. The hand-over that runs
// them, with no brew and no Bun yet, is in handover.spec.ts.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep, skipIf } from "./step";

const INSTALL = "brew/install.sh";
const BUNDLE = "brew/bundle.sh";
const CONFIG = "brew/config-link.sh";

const STUB = `#!/bin/sh
case "$1" in
  shellenv|cleanup) exit 0 ;;
  bundle) echo "$HOMEBREW_DOTS_PROFILE" >> "$STUB_LOG"; exit 0 ;;
esac
exit 0
`;

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "brew-steps-"));
  mkdirSync(join(t, "bin"));
  writeFileSync(join(t, "bin", "brew"), STUB);
  chmodSync(join(t, "bin", "brew"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const base = (extra: Record<string, string> = {}) => ({
  PATH: `${join(t, "bin")}:/usr/bin:/bin`,
  HOME: t,
  XDG_STATE_HOME: join(t, "state"),
  HOMEBREW_BUNDLE_FILE: join(t, "Brewfile"),
  STUB_LOG: join(t, "calls"),
  ...extra,
});

describe("brew:config-link", () => {
  const link = () => join(t, ".config", "homebrew");

  it("is idempotent: a second run leaves the link alone and says nothing", () => {
    mkdirSync(join(t, ".local", "share", "dots", "config", "homebrew"), { recursive: true });
    expect(runStep(CONFIG, base()).code).toBe(0);
    const target = readlinkSync(link());
    const second = runStep(CONFIG, base());
    expect(second.code).toBe(0);
    expect(second.err).toBe("");
    expect(readlinkSync(link())).toBe(target);
  });

  it("skip_if is true once the link exists, false before", () => {
    mkdirSync(join(t, ".local", "share", "dots", "config", "homebrew"), { recursive: true });
    expect(skipIf(CONFIG, base())).toBe(false);
    runStep(CONFIG, base());
    expect(skipIf(CONFIG, base())).toBe(true);
  });
});

describe("brew:install", () => {
  it("without a terminal and without a sudo ticket, stops with what to run", () => {
    writeFileSync(join(t, "bin", "id"), "#!/bin/sh\necho 501\n");
    writeFileSync(join(t, "bin", "sudo"), "#!/bin/sh\nexit 1\n");
    for (const n of ["id", "sudo"]) chmodSync(join(t, "bin", n), 0o755);
    const r = runStep(INSTALL, base(), { stdin: "ignore" });
    expect(r.code).toBe(1);
    expect(r.err).toContain("run 'sudo -v', then mise bootstrap");
  });

  it("skip_if is true when brew is on PATH", () => {
    expect(skipIf(INSTALL, base())).toBe(true);
  });
});

describe("brew:bundle", () => {
  it("uses usage_profile, never the parent process", () => {
    const r = runStep(BUNDLE, base({ usage_profile: "desktop,dev" }));
    expect(r.code).toBe(0);
    expect(readFileSync(join(t, "calls"), "utf8").trim().split("\n")).toEqual(["container", "desktop,dev"]);
  });
});
