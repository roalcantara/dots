#!/usr/bin/env bun
// yb: the yabai CLI the Karabiner fn layer calls (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md).
// A stub yabai (DOTS_YABAI) records each call; YB_STUB_FAIL makes calls matching a regex exit 1, and
// YB_STUB_QUERY is what `query` prints.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { findRealBin, realUsageDir, scriptPath } from "./support/paths";

const script = scriptPath("yb");
const STUB = `#!/bin/sh
printf '%s\\n' "$*" >> "$YB_STUB_LOG"
if [ -n "\${YB_STUB_FAIL:-}" ] && printf '%s' "$*" | grep -Eq "$YB_STUB_FAIL"; then exit 1; fi
case "$2" in query) printf '%s\\n' "\${YB_STUB_QUERY:-{\\}}" ;; esac
exit 0
`;
const OPEN = `#!/bin/sh\nprintf 'open %s\\n' "$*" >> "$YB_STUB_LOG"\n`;

let dir = "";
let log = "";
let home = "";
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "yb-stub-"));
  for (const [name, body] of [["yabai", STUB], ["open", OPEN]] as const) {
    writeFileSync(join(dir, name), body);
    chmodSync(join(dir, name), 0o755);
  }
  log = join(dir, "calls");
  home = join(dir, "home");
});
afterAll(() => rmSync(dir, { recursive: true, force: true }));

function yb(args: string[], env: Record<string, string> = {}) {
  writeFileSync(log, "");
  const r = Bun.spawnSync([script, ...args], {
    stdout: "pipe",
    stderr: "pipe",
    env: {
      PATH: `${dir}:${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`,
      HOME: home,
      DOTS_YABAI: join(dir, "yabai"),
      YB_STUB_LOG: log,
      ...env,
    },
  });
  const calls = readFileSync(log, "utf8").trim().split("\n").filter(Boolean);
  return { code: r.exitCode, out: r.stdout.toString() + r.stderr.toString(), calls };
}

describe("yb", () => {
  describe("spaces", () => {
    it("focuses a labelled space", () => {
      expect(yb(["space", "1"]).calls).toEqual(["-m space --focus s1"]);
      expect(yb(["space", "10"]).calls).toEqual(["-m space --focus s10"]);
    });

    it("rejects a space outside 1-10", () => {
      for (const n of ["0", "11"]) {
        const r = yb(["space", n]);
        expect(r.code).not.toBe(0);
        expect(r.calls).toEqual([]);
      }
    });

    it("moves the window and follows, or stays with --stay", () => {
      expect(yb(["move", "6"]).calls).toEqual(["-m window --space s6", "-m space --focus s6"]);
      expect(yb(["move", "6", "--stay"]).calls).toEqual(["-m window --space s6"]);
    });

    it("steps to the next, previous and last space, wrapping on this screen", () => {
      expect(yb(["space", "next"]).calls).toEqual(["-m space --focus next"]);
      expect(yb(["space", "recent"]).calls).toEqual(["-m space --focus recent"]);
      expect(yb(["space", "next"], { YB_STUB_FAIL: "focus next$" }).calls).toEqual([
        "-m space --focus next",
        "-m space --focus first",
      ]);
      expect(yb(["space", "prev"], { YB_STUB_FAIL: "focus prev$" }).calls).toEqual([
        "-m space --focus prev",
        "-m space --focus last",
      ]);
    });
  });

  describe("windows", () => {
    it("focuses a neighbour, or the screen that way at the edge", () => {
      expect(yb(["focus", "west"]).calls).toEqual(["-m window --focus west"]);
      expect(yb(["focus", "east"], { YB_STUB_FAIL: "window --focus east" }).calls).toEqual([
        "-m window --focus east",
        "-m display --focus east",
      ]);
    });

    it("rejects an unknown direction", () => {
      expect(yb(["focus", "up"]).code).not.toBe(0);
    });

    it("maps the one-call actions", () => {
      const cases: Array<[string[], string[]]> = [
        [["swap", "north"], ["-m window --swap north"]],
        [["send-display", "east"], ["-m window --display east", "-m display --focus east"]],
        [["display-other"], ["-m display --focus recent"]],
        [["split"], ["-m window --toggle split"]],
        [["float"], ["-m window --toggle float"]],
        [["zoom", "full"], ["-m window --toggle zoom-fullscreen"]],
        [["zoom", "parent"], ["-m window --toggle zoom-parent"]],
        [["scratchpad"], ["-m window --toggle scratch"]],
        [["scratchpad", "--send"], ["-m window --scratchpad scratch"]],
        [["stack", "west"], ["-m window --stack west"]],
        [["stack", "next"], ["-m window --focus stack.next"]],
        [["stack", "prev"], ["-m window --focus stack.prev"]],
        [["balance"], ["-m space --balance"]],
        [["rotate"], ["-m space --rotate 90"]],
        [["close"], ["-m window --close"]],
      ];
      for (const [args, calls] of cases) expect(yb(args).calls).toEqual(calls);
    });

    it("resizes from the far edge, or the near one when that fails", () => {
      expect(yb(["resize", "w+"]).calls).toEqual(["-m window --resize right:40:0"]);
      expect(yb(["resize", "w-"], { YB_STUB_FAIL: "right:" }).calls).toEqual([
        "-m window --resize right:-40:0",
        "-m window --resize left:40:0",
      ]);
      expect(yb(["resize", "h+"], { YB_STUB_FAIL: "bottom:" }).calls).toEqual([
        "-m window --resize bottom:0:40",
        "-m window --resize top:0:-40",
      ]);
      expect(yb(["resize", "h-"]).calls).toEqual(["-m window --resize bottom:0:-40"]);
    });

    it("pins a window floating on top of every space, and unpins it", () => {
      expect(yb(["pin"], { YB_STUB_QUERY: '{"is-sticky":false}' }).calls).toEqual([
        "-m query --windows --window",
        "-m window --toggle float",
        "-m window --toggle sticky",
        "-m window --sub-layer above",
      ]);
      expect(yb(["pin"], { YB_STUB_QUERY: '{"is-sticky":true}' }).calls).toEqual([
        "-m query --windows --window",
        "-m window --toggle sticky",
        "-m window --toggle float",
        "-m window --sub-layer auto",
      ]);
    });
  });

  describe("layout", () => {
    it("cycles bsp → stack → float and back", () => {
      expect(yb(["layout", "next"], { YB_STUB_QUERY: '{"type":"bsp"}' }).calls).toEqual([
        "-m query --spaces --space",
        "-m space --layout stack",
      ]);
      expect(yb(["layout", "next"], { YB_STUB_QUERY: '{"type":"float"}' }).calls.at(-1)).toBe("-m space --layout bsp");
      expect(yb(["layout", "prev"], { YB_STUB_QUERY: '{"type":"bsp"}' }).calls.at(-1)).toBe("-m space --layout float");
    });
  });

  describe("apps and Raycast", () => {
    it("opens apps, Neovim in Ghostty, and the kb commands", () => {
      expect(yb(["app", "Google Chrome"]).calls).toEqual(["open -a Google Chrome"]);
      expect(yb(["nvim"]).calls).toEqual(["open -na Ghostty --args -e nvim"]);
      expect(yb(["system"]).calls).toEqual(["open raycast://extensions/roalcantara/kb/system.screen"]);
      expect(yb(["hotkeys"]).calls).toEqual(["open raycast://extensions/roalcantara/kb/hotkeys.screen"]);
    });
  });

  describe("failures", () => {
    it("exits 1 within a second and logs when yabai is missing", () => {
      const started = performance.now();
      const r = yb(["space", "3"], { DOTS_YABAI: join(dir, "missing-yabai") });
      expect(performance.now() - started).toBeLessThan(1000);
      expect(r.code).toBe(1);
      expect(readFileSync(join(home, ".local/state/dots/yb.log"), "utf8")).toContain("space 3");
    });

    it("logs a yabai call that fails and exits non-zero", () => {
      rmSync(join(home, ".local/state/dots/yb.log"), { force: true });
      const r = yb(["close"], { YB_STUB_FAIL: "close" });
      expect(r.code).not.toBe(0);
      expect(readFileSync(join(home, ".local/state/dots/yb.log"), "utf8")).toContain("window --close");
    });
  });
});
