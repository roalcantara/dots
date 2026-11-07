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
        [["stack", "sibling"], ["-m window --stack sibling"]],
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

describe("yb spaces", () => {
  const FAKE = join(import.meta.dir, "support/fake-yabai.ts");
  const BUILTIN = 1;
  const EXTERNAL = 3;
  let state = "";
  let profiler = "";
  let shim = "";
  type Space = { id: number; label: string; display: number; windows: number[] };

  beforeAll(() => {
    state = join(dir, "state.json");
    profiler = join(dir, "displays.json");
    shim = join(dir, "fake-yabai");
    writeFileSync(shim, `#!/bin/sh\nexec "${process.execPath}" "${FAKE}" "$FAKE_STATE" "$@"\n`);
    chmodSync(shim, 0o755);
  });

  // displays: [id, arrangement index]; spaces: [display index, label, windows]
  function setup(displays: Array<[number, number]>, spaces: Array<[number, string, number[]?]>) {
    let id = 100;
    writeFileSync(state, JSON.stringify({
      displays: displays.map(([i, index]) => ({ id: i, index })),
      spaces: spaces.map(([display, label, windows]) => ({ id: id++, label, display, windows: windows ?? [] })),
      nextId: 500,
      calls: [],
    }));
    writeFileSync(profiler, JSON.stringify({
      SPDisplaysDataType: [{ spdisplays_ndrvs: displays.map(([i]) => ({
        _spdisplays_displayID: String(i),
        ...(i === BUILTIN ? { spdisplays_connection_type: "spdisplays_internal" } : {}),
      })) }],
    }));
  }
  const read = () => JSON.parse(readFileSync(state, "utf8")) as { displays: { id: number; index: number }[]; spaces: Space[]; calls: string[] };
  const run = () => {
    const r = Bun.spawnSync([script, "spaces"], {
      stdout: "pipe",
      stderr: "pipe",
      env: {
        PATH: `${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`,
        HOME: home,
        DOTS_YABAI: shim,
        DOTS_DISPLAYS_JSON: profiler,
        FAKE_STATE: state,
      },
    });
    return { code: r.exitCode, err: r.stderr.toString() };
  };
  const labelsOn = (displayId: number) => {
    const s = read();
    const index = s.displays.find((d) => d.id === displayId)!.index;
    return s.spaces.filter((x) => x.display === index).map((x) => x.label);
  };
  const S = (from: number, to: number) => Array.from({ length: to - from + 1 }, (_, i) => `s${from + i}`);

  it("two screens: s1-s5 on the built-in one, s6-s10 on the external one", () => {
    setup([[BUILTIN, 1], [EXTERNAL, 2]], [[1, ""], [2, ""]]);
    expect(run().code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(S(1, 5));
    expect(labelsOn(EXTERNAL)).toEqual(S(6, 10));
  });

  it("puts s6-s10 on the external screen even when yabai lists it first", () => {
    setup([[EXTERNAL, 1], [BUILTIN, 2]], [[1, ""], [2, ""]]);
    expect(run().code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(S(1, 5));
    expect(labelsOn(EXTERNAL)).toEqual(S(6, 10));
  });

  it("one screen: all ten on it", () => {
    setup([[BUILTIN, 1]], [[1, ""], [1, ""], [1, ""]]);
    expect(run().code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(S(1, 10));
  });

  it("plugging the external screen in moves s6-s10 there instead of recreating them", () => {
    setup([[BUILTIN, 1]], S(1, 10).map((l) => [1, l] as [number, string]));
    expect(run().code).toBe(0);
    const before = new Map(read().spaces.map((s) => [s.label, s.id]));
    // macOS gives a newly attached screen one space of its own
    const s = read();
    s.displays.push({ id: EXTERNAL, index: 2 });
    s.spaces.push({ id: 900, label: "", display: 2, windows: [] });
    writeFileSync(state, JSON.stringify(s));
    expect(run().code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(S(1, 5));
    expect([...labelsOn(EXTERNAL)].sort()).toEqual(S(6, 10).sort());
    for (const label of S(6, 10)) expect(read().spaces.find((x) => x.label === label)!.id).toBe(before.get(label)!);
  });

  it("keeps windows: a surplus space's windows move before it goes", () => {
    setup([[BUILTIN, 1]], [...S(1, 10).map((l) => [1, l] as [number, string]), [1, "", [42]]]);
    const r = run();
    expect(r.code).toBe(0);
    const after = read();
    expect(after.spaces.filter((x) => x.display === 1)).toHaveLength(10);
    expect(after.spaces.some((x) => x.windows.includes(42))).toBe(true);
  });

  it("a second run changes nothing", () => {
    setup([[BUILTIN, 1], [EXTERNAL, 2]], [[1, ""], [2, ""]]);
    run();
    const calls = read().calls.length;
    expect(run().code).toBe(0);
    expect(read().calls).toHaveLength(calls);
  });
});
