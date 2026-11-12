#!/usr/bin/env bun
// yb: the yabai CLI the Karabiner fn layer calls (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md).
// A stub yabai (DOTS_YABAI) records each call; YB_STUB_FAIL makes calls matching a regex exit 1, and
// YB_STUB_QUERY is what `query` prints.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { findRealBin, realUsageDir, scriptPath } from "./support/paths";

const script = scriptPath("yb");
const STUB = `#!/bin/sh
printf '%s\\n' "$*" >> "$YB_STUB_LOG"
if [ -n "\${YB_STUB_FAIL:-}" ] && printf '%s' "$*" | grep -Eq "$YB_STUB_FAIL"; then exit 1; fi
case "$2 $3 $4" in
  "query --displays --display") printf '%s\\n' "\${YB_STUB_DISPLAY:-{\\"index\\":1\\}}" ;;
  "query --windows ") n=$(cat "$YB_STUB_LOG.n" 2>/dev/null || echo 0); echo $((n + 1)) > "$YB_STUB_LOG.n"
    if [ "$n" -eq 0 ]; then printf '%s\\n' "\${YB_STUB_WINDOWS_1:-[]}"; else printf '%s\\n' "\${YB_STUB_WINDOWS_2:-[]}"; fi ;;
  "query --spaces --space") printf '%s\\n' "\${YB_STUB_SPACE:-\${YB_STUB_QUERY:-{\\}}}" ;;
  query*) printf '%s\\n' "\${YB_STUB_QUERY:-{\\}}" ;;
esac
exit 0
`;
const OPEN = `#!/bin/sh\nprintf 'open %s\\n' "$*" >> "$YB_STUB_LOG"\n`;
// osascript stand-in: answers "is running" from GHOSTTY_RUNNING and records new-window requests.
const OSASCRIPT = `#!/bin/sh
case "$*" in
  *"is running"*) echo "\${GHOSTTY_RUNNING:-true}" ;;
  *"tui:"*) printf 'osascript tui %s\\n' "$*" >> "$YB_STUB_LOG" ;;
  *nvim*"new window"*) echo "osascript Ghostty new window nvim" >> "$YB_STUB_LOG" ;;
  *"make new tab"*) echo "osascript new tab" >> "$YB_STUB_LOG" ;;
  *"make new document"*) echo "osascript Safari new document" >> "$YB_STUB_LOG" ;;
  *"new window"*) echo "osascript Ghostty new window" >> "$YB_STUB_LOG" ;;
esac
`;

let dir = "";
let log = "";
let home = "";
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "yb-stub-"));
  for (const [name, body] of [["yabai", STUB], ["open", OPEN], ["osascript", OSASCRIPT]] as const) {
    writeFileSync(join(dir, name), body);
    chmodSync(join(dir, name), 0o755);
  }
  log = join(dir, "calls");
  home = join(dir, "home");
});
afterAll(() => rmSync(dir, { recursive: true, force: true }));

function yb(args: string[], env: Record<string, string> = {}) {
  writeFileSync(log, "");
  rmSync(`${log}.n`, { force: true });
  const r = Bun.spawnSync([script, ...args], {
    stdout: "pipe",
    stderr: "pipe",
    env: {
      PATH: `${dir}:${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`,
      HOME: home,
      DOTS_YABAI: join(dir, "yabai"),
      YB_STUB_LOG: log,
      YB_TRACE_WHERE: "0",
      YB_WAIT_STEPS: "2",
      DOTS_BORDERS: join(dir, "no-borders"),
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
        [["screen", "west"], ["-m display --focus west"]],
        [["screen", "east"], ["-m display --focus east"]],
        [["split"], ["-m window --toggle split"]],
        [["float"], ["-m window --toggle float"]],
        [["zoom", "full"], ["-m window --toggle zoom-fullscreen"]],
        [["zoom", "parent"], ["-m window --toggle zoom-parent"]],
        [["scratchpad"], ["-m window --toggle scratch"]],
        [["scratchpad", "--send"], ["-m window --scratchpad scratch"]],
        [["balance"], ["-m space --balance"]],
        // yabai's --rotate 90 turns the layout counter-clockwise on screen (measured: right half -> top)
        [["rotate"], ["-m space --rotate 270"]],
        [["rotate", "cw"], ["-m space --rotate 270"]],
        [["rotate", "ccw"], ["-m space --rotate 90"]],
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

  describe("no stacks", () => {
    it("has no stack command: stacked windows hide without a trace", () => {
      expect(yb(["stack", "west"]).code).not.toBe(0);
    });
  });

  describe("split", () => {
    const q = (split: string) => ({ YB_STUB_QUERY: `{"split-type":"${split}"}` });
    const Q = "-m query --windows --window";

    it("fn + | sets the pair side by side, fn + \\ one above the other, only when they are not already", () => {
      expect(yb(["split", "vertical"], q("horizontal")).calls).toEqual([Q, "-m window --toggle split"]);
      expect(yb(["split", "vertical"], q("vertical")).calls).toEqual([Q]);
      expect(yb(["split", "horizontal"], q("vertical")).calls).toEqual([Q, "-m window --toggle split"]);
      expect(yb(["split", "horizontal"], q("horizontal")).calls).toEqual([Q]);
    });

    it("leaves a window alone on its space", () => {
      expect(yb(["split", "vertical"], q("none")).calls).toEqual([Q]);
    });
  });

  describe("arrange", () => {
    const q = (split: string, child: string) => ({ YB_STUB_QUERY: `{"split-type":"${split}","split-child":"${child}"}` });
    const Q = "-m query --windows --window";

    it("puts the focused window and its neighbour side by side, focused on the left or right", () => {
      expect(yb(["arrange", "left"], q("horizontal", "first_child")).calls).toEqual([Q, "-m window --toggle split"]);
      expect(yb(["arrange", "right"], q("horizontal", "first_child")).calls).toEqual([Q, "-m window --toggle split", "-m window --swap sibling"]);
      expect(yb(["arrange", "left"], q("vertical", "second_child")).calls).toEqual([Q, "-m window --swap sibling"]);
      expect(yb(["arrange", "right"], q("vertical", "second_child")).calls).toEqual([Q]);
    });

    it("stacks them, focused on top or at the bottom", () => {
      expect(yb(["arrange", "up"], q("vertical", "first_child")).calls).toEqual([Q, "-m window --toggle split"]);
      expect(yb(["arrange", "down"], q("horizontal", "first_child")).calls).toEqual([Q, "-m window --swap sibling"]);
    });

    it("swaps toward the arrow when the neighbour is a group of windows", () => {
      const r = yb(["arrange", "left"], { ...q("vertical", "second_child"), YB_STUB_FAIL: "swap sibling" });
      expect(r.calls).toEqual([Q, "-m window --swap sibling", "-m window --swap west"]);
      expect(r.code).toBe(0);
    });

    it("does nothing for a window alone on its space", () => {
      expect(yb(["arrange", "left"], q("none", "second_child")).calls).toEqual([Q]);
    });

    it("rejects other directions", () => {
      expect(yb(["arrange", "west"]).code).not.toBe(0);
    });
  });

  describe("layout", () => {
    it("fn + l toggles tiled and floating, and brings a stacked space back to tiling", () => {
      expect(yb(["layout"], { YB_STUB_QUERY: '{"type":"bsp"}' }).calls).toEqual(["-m query --spaces --space", "-m space --layout float"]);
      expect(yb(["layout"], { YB_STUB_QUERY: '{"type":"float"}' }).calls.at(-1)).toBe("-m space --layout bsp");
      expect(yb(["layout"], { YB_STUB_QUERY: '{"type":"stack"}' }).calls.at(-1)).toBe("-m space --layout bsp");
    });
  });


  describe("apps and Raycast", () => {
    it("opens apps, Neovim in Ghostty, and the kb commands", () => {
      expect(yb(["app", "Google Chrome"]).calls).toEqual(["open -a Google Chrome"]);
      // term and nvim also ask yabai where the keyboard is (see "yb term on the focused screen")
      const opened = (args: string[], env: Record<string, string> = {}) => yb(args, env).calls.filter((c) => !c.startsWith("-m query"));
      expect(opened(["term"])).toEqual(["osascript Ghostty new window"]);
      expect(opened(["nvim"])).toEqual(["osascript Ghostty new window nvim"]);
      expect(opened(["term"], { GHOSTTY_RUNNING: "false" })).toEqual(["open -a Ghostty"]);
      expect(yb(["system"]).calls).toEqual(["open raycast://extensions/roalcantara/kb/system.screen"]);
      expect(yb(["hotkeys"]).calls).toEqual(["open raycast://extensions/roalcantara/kb/hotkeys.screen"]);
      expect(yb(["notes"]).calls).toEqual(["open raycast://extensions/raycast/raycast-notes/raycast-notes"]);
    });
  });

  describe("tui", () => {
    const DISPLAY = '{"index":1,"frame":{"x":0,"y":25,"w":1512,"h":957}}';
    const win = (extra: Record<string, unknown> = {}) =>
      JSON.stringify([{ id: 42, app: "Ghostty", title: "tui:psc", display: 1, "is-floating": false, ...extra }]);
    const tui = (args: string[], env: Record<string, string> = {}) =>
      yb(["tui", "psc", ...args], { YB_STUB_DISPLAY: DISPLAY, YB_STUB_WINDOWS_2: win(), ...env });
    const osa = (calls: string[]) => calls.find((c) => c.startsWith("osascript tui")) ?? "";
    const moves = (calls: string[]) => calls.filter((c) => c.startsWith("-m window"));

    it("opens the tool in a floating, centred window", () => {
      const r = tui(["--command", "psc"]);
      expect(r.code).toBe(0);
      const o = osa(r.calls);
      for (const part of ["command", "-lic 'psc'", "wait after command", "tui:psc"]) expect(o).toContain(part);
      expect(moves(r.calls)).toEqual([
        "-m window 42 --toggle float",
        "-m window 42 --resize abs:875:600",
        "-m window 42 --move abs:318:203",
        "-m window --focus 42",
      ]);
    });

    it("uses the given size", () => {
      const r = tui(["--command", "psc", "--width", "1000", "--height", "700"]);
      expect(r.calls).toContain("-m window 42 --resize abs:1000:700");
      expect(r.calls).toContain("-m window 42 --move abs:256:153");
    });

    it("refuses a size that is not a number", () => {
      const r = tui(["--command", "psc", "--width", "wide"]);
      expect(r.code).toBe(1);
      expect(r.out).toContain("--width");
      expect(osa(r.calls)).toBe("");
    });

    it("does not re-tile a window that is already floating", () => {
      const r = tui(["--command", "psc"], { YB_STUB_WINDOWS_2: win({ "is-floating": true }) });
      expect(r.calls).not.toContain("-m window 42 --toggle float");
      expect(r.calls).toContain("-m window 42 --resize abs:875:600");
    });

    it("brings the window to the focused screen", () => {
      const m = moves(tui(["--command", "psc"], { YB_STUB_WINDOWS_2: win({ display: 2 }) }).calls);
      expect(m.indexOf("-m window 42 --display 1")).toBeGreaterThanOrEqual(0);
      expect(m.indexOf("-m window 42 --display 1")).toBeLessThan(m.indexOf("-m window 42 --toggle float"));
    });

    it("focuses the open window instead of opening another", () => {
      const r = tui(["--command", "psc"], { YB_STUB_WINDOWS_1: '[{"id":7,"app":"Ghostty","title":"tui:psc"}]' });
      expect(r.calls).toContain("-m window --focus 7");
      expect(osa(r.calls)).toBe("");
    });

    it("keeps quotes in the command", () => {
      const o = osa(tui(["--command", "bash -c 'dust; read -n 1 -s'"]).calls);
      expect(o).toContain(String.raw`-lic 'bash -c '\''dust; read -n 1 -s'\'''`);
    });

    it("pauses before closing when asked", () => {
      expect(osa(tui(["--command", "brew outdated", "--pause"]).calls)).toContain("-lic 'brew outdated; read -k1 -s'");
    });

    it("launches Ghostty first when it is not running", () => {
      const r = tui(["--command", "psc"], { GHOSTTY_RUNNING: "false", YB_TUI_LAUNCH_WAIT: "0" });
      const open = r.calls.indexOf("open -a Ghostty");
      expect(open).toBeGreaterThanOrEqual(0);
      expect(open).toBeLessThan(r.calls.findIndex((c) => c.startsWith("osascript tui")));
    });

    it("floats the TUI window, not another new Ghostty window", () => {
      const both = JSON.stringify([
        { id: 41, app: "Ghostty", title: "~", display: 1, "is-floating": false },
        { id: 42, app: "Ghostty", title: "tui:psc", display: 1, "is-floating": false },
      ]);
      const r = tui(["--command", "psc"], { GHOSTTY_RUNNING: "false", YB_TUI_LAUNCH_WAIT: "0", YB_STUB_WINDOWS_2: both });
      expect(r.calls.filter((c) => c.includes("41"))).toEqual([]);
      expect(r.calls).toContain("-m window 42 --toggle float");
    });

    it("opens without yabai", () => {
      const r = tui(["--command", "psc"], { DOTS_YABAI: join(dir, "no-yabai") });
      expect(r.code).toBe(0);
      expect(osa(r.calls)).not.toBe("");
      expect(r.calls.filter((c) => c.startsWith("-m"))).toEqual([]);
    });

    it("needs a command", () => {
      const r = yb(["tui", "psc"]);
      expect(r.code).not.toBe(0);
      expect(r.out).toContain("--command");
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
  const run = (env: Record<string, string> = {}) => {
    const r = Bun.spawnSync([script, "spaces"], {
      stdout: "pipe",
      stderr: "pipe",
      env: {
        PATH: `${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`,
        HOME: home,
        DOTS_YABAI: shim,
        DOTS_DISPLAYS_JSON: profiler,
        FAKE_STATE: state,
        ...env,
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

  // Labels stay with their spaces (fn + 7 always reaches the same one), so a space that drifted out of
  // place moves back instead of being relabelled.
  it("puts each screen's spaces back in label order, keeping every label on its space", () => {
    const shuffled: Array<[number, string]> = [[1, "s1"], [1, "s3"], [1, "s2"], [1, "s5"], [1, "s4"], [2, "s6"], [2, "s8"], [2, "s7"], [2, "s10"], [2, "s9"]];
    setup([[BUILTIN, 1], [EXTERNAL, 2]], shuffled);
    const ids = new Map(read().spaces.map((s) => [s.label, s.id]));
    expect(run().code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(S(1, 5));
    expect(labelsOn(EXTERNAL)).toEqual(S(6, 10));
    for (const s of read().spaces) expect(s.id).toBe(ids.get(s.label)!);
    expect(read().calls.every((c) => / --move prev$/.test(c))).toBe(true);
  });

  it("without the scripting addition, leaves the order alone and still succeeds", () => {
    setup([[BUILTIN, 1], [EXTERNAL, 2]], [[1, "s1"], [1, "s3"], [1, "s2"], [1, "s4"], [1, "s5"], ...S(6, 10).map((l) => [2, l] as [number, string])]);
    expect(run({ FAKE_NO_SA: "1" }).code).toBe(0);
    expect(labelsOn(BUILTIN)).toEqual(["s1", "s3", "s2", "s4", "s5"]);
  });
});

describe("yb sa", () => {
  // sudo stub: records the call; `install … <src> <dst>` copies the file (owner flags ignored).
  const SUDO = `#!/bin/sh
printf 'sudo %s\\n' "$*" >> "$YB_STUB_LOG"
if [ "$1" = install ]; then eval "src=\\\${$(($# - 1))}"; eval "dst=\\\${$#}"; cp "$src" "$dst"; fi
exit 0
`;
  let sa = "";
  let target = "";
  let yabaiBin = "";
  const stub = (name: string, body: string) => {
    writeFileSync(join(sa, name), body);
    chmodSync(join(sa, name), 0o755);
    return join(sa, name);
  };

  beforeAll(() => {
    sa = mkdtempSync(join(tmpdir(), "yb-sa-"));
    stub("sudo", SUDO);
    stub("visudo", `#!/bin/sh\nexit "\${VISUDO_EXIT:-0}"\n`);
    stub("csrutil", `#!/bin/sh\nprintf '%s\\n' "\${CSRUTIL_STATUS:-System Integrity Protection status: unknown (Custom Configuration).}"\n`);
    stub("nvram", `#!/bin/sh\nprintf 'boot-args\\t%s\\n' "\${NVRAM_ARGS:-}"\n`);
    yabaiBin = stub("yabai-bin", "#!/bin/sh\n# v1\n");
    target = join(sa, "sudoers-yabai");
  });
  afterAll(() => rmSync(sa, { recursive: true, force: true }));

  function runSa(env: Record<string, string> = {}, args = ["sa"]) {
    writeFileSync(log, "");
    const r = Bun.spawnSync([script, ...args], {
      stdout: "pipe",
      stderr: "pipe",
      env: {
        PATH: `${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`,
        HOME: home,
        USER: "tester",
        YB_STUB_LOG: log,
        DOTS_YABAI: yabaiBin,
        DOTS_SUDO: join(sa, "sudo"),
        DOTS_VISUDO: join(sa, "visudo"),
        DOTS_CSRUTIL: join(sa, "csrutil"),
        DOTS_NVRAM: join(sa, "nvram"),
        DOTS_SUDOERS: target,
        ...env,
      },
    });
    const calls = readFileSync(log, "utf8").trim().split("\n").filter(Boolean);
    return { code: r.exitCode, out: r.stdout.toString() + r.stderr.toString(), calls };
  }
  const hash = () => new Bun.CryptoHasher("sha256").update(readFileSync(yabaiBin)).digest("hex");

  it("writes the sudoers rule for the current yabai hash", () => {
    rmSync(join(home, ".local/state/dots"), { recursive: true, force: true });
    const r = runSa({ NVRAM_ARGS: "-arm64e_preview_abi" });
    expect(r.code).toBe(0);
    expect(readFileSync(target, "utf8")).toBe(`tester ALL=(root) NOPASSWD: sha256:${hash()} ${yabaiBin} --load-sa\n`);
    expect(r.calls.some((c) => c.startsWith("sudo install -m 0440 -o root -g wheel "))).toBe(true);
  });

  it("does nothing, and never asks for sudo, when the hash is unchanged", () => {
    const r = runSa({ NVRAM_ARGS: "-arm64e_preview_abi" });
    expect(r.code).toBe(0);
    expect(r.calls).toEqual([]);
  });

  it("rewrites the rule after yabai changes (brew upgrade)", () => {
    writeFileSync(yabaiBin, "#!/bin/sh\n# v2\n");
    const r = runSa({ NVRAM_ARGS: "-arm64e_preview_abi" });
    expect(r.calls.some((c) => c.startsWith("sudo install"))).toBe(true);
    expect(readFileSync(target, "utf8")).toContain(`sha256:${hash()}`);
  });

  it("installs nothing when visudo rejects the rule, and still exits 0", () => {
    writeFileSync(yabaiBin, "#!/bin/sh\n# v3\n");
    const r = runSa({ NVRAM_ARGS: "-arm64e_preview_abi", VISUDO_EXIT: "1" });
    expect(r.code).toBe(0);
    expect(r.calls.some((c) => c.startsWith("sudo install"))).toBe(false);
    expect(r.out).toContain("visudo");
  });

  it("with SIP fully on, prints the Recovery command and leaves NVRAM alone", () => {
    const r = runSa({ CSRUTIL_STATUS: "System Integrity Protection status: enabled." });
    expect(r.code).toBe(0);
    expect(r.out).toContain("csrutil enable --without fs --without debug --without nvram");
    expect(r.calls.some((c) => c.includes("nvram"))).toBe(false);
  });

  it("adds the arm64e boot argument once, keeping the others", () => {
    const add = runSa({ NVRAM_ARGS: "-v" });
    expect(add.calls).toContain("sudo nvram boot-args=-v -arm64e_preview_abi");
    expect(add.out).toContain("reboot");
    const again = runSa({ NVRAM_ARGS: "-v -arm64e_preview_abi" });
    expect(again.calls.some((c) => c.includes("nvram"))).toBe(false);
  });

  describe("use: another yabai build", () => {
    // No DOTS_YABAI: yb reads the choice `yb use` records.
    const chosen = { DOTS_YABAI: "", NVRAM_ARGS: "-arm64e_preview_abi" };
    const binfile = () => join(home, ".local/state/dots/yabai-bin");
    let fork = "";
    beforeAll(() => {
      fork = stub("yabai-fork", "#!/bin/sh\necho \"fork $*\"\n");
    });

    it("records the build and writes the sudoers rule for it", () => {
      const r = runSa(chosen, ["use", fork]);
      expect(r.code).toBe(0);
      expect(readFileSync(binfile(), "utf8").trim()).toBe(fork);
      const forkHash = new Bun.CryptoHasher("sha256").update(readFileSync(fork)).digest("hex");
      expect(readFileSync(target, "utf8")).toBe(`tester ALL=(root) NOPASSWD: sha256:${forkHash} ${fork} --load-sa\n`);
      expect(r.out).toContain("launchctl kickstart -k");
    });

    it("rewrites the rule on every switch between builds", () => {
      const r = runSa({ ...chosen, DOTS_YABAI: yabaiBin }, ["sa"]);
      expect(r.calls.some((c) => c.startsWith("sudo install"))).toBe(true);
      expect(readFileSync(target, "utf8")).toContain(` ${yabaiBin} --load-sa`);
      runSa(chosen, ["sa"]);
      expect(readFileSync(target, "utf8")).toContain(` ${fork} --load-sa`);
    });

    it("load-sa and run follow the choice", () => {
      expect(runSa(chosen, ["load-sa"]).calls).toEqual([`sudo -n ${fork} --load-sa`]);
      expect(runSa(chosen, ["run"]).out).toContain("fork");
    });

    it("refuses a path that is not an executable file, keeping the choice", () => {
      const r = runSa(chosen, ["use", join(sa, "nope")]);
      expect(r.code).not.toBe(0);
      expect(readFileSync(binfile(), "utf8").trim()).toBe(fork);
    });

    it("brew goes back to Homebrew's yabai", () => {
      const r = runSa(chosen, ["use", "brew"]);
      expect(r.code).toBe(0);
      expect(existsSync(binfile())).toBe(false);
      expect(r.out).toContain("yabai is now /opt/homebrew/bin/yabai");
    });
  });
});

describe("yb spaces in the real world", () => {
  const FAKE = join(import.meta.dir, "support/fake-yabai.ts");
  let state = "";
  let profiler = "";
  let shim = "";
  beforeAll(() => {
    state = join(dir, "state2.json");
    profiler = join(dir, "displays2.json");
    shim = join(dir, "fake-yabai2");
    writeFileSync(shim, `#!/bin/sh\nexec "${process.execPath}" "${FAKE}" "$FAKE_STATE" "$@"\n`);
    chmodSync(shim, 0o755);
  });
  type Space = { id: number; label: string; display: number; windows: number[]; fullscreen?: boolean };
  function setup(displays: number[], spaces: Space[], extra: Record<string, unknown> = {}) {
    writeFileSync(state, JSON.stringify({ displays: displays.map((id, i) => ({ id, index: i + 1 })), spaces, nextId: 500, calls: [], ...extra }));
    writeFileSync(profiler, JSON.stringify({ SPDisplaysDataType: [{ spdisplays_ndrvs: displays.map((id) => ({ _spdisplays_displayID: String(id), ...(id === 1 ? { spdisplays_connection_type: "spdisplays_internal" } : {}) })) }] }));
  }
  const read = () => JSON.parse(readFileSync(state, "utf8")) as { spaces: Space[]; calls: string[] };
  const run = (env: Record<string, string> = {}) => {
    const r = Bun.spawnSync([script, "spaces"], {
      stdout: "pipe", stderr: "pipe",
      env: { PATH: `${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`, HOME: home, DOTS_YABAI: shim, DOTS_DISPLAYS_JSON: profiler, FAKE_STATE: state, DOTS_SPACES_WAIT: "0", ...env },
    });
    return { code: r.exitCode, err: r.stderr.toString() };
  };
  const sp = (id: number, display: number, label = "", windows: number[] = [], fullscreen = false): Space => ({ id, label, display, windows, fullscreen });

  it("without the scripting addition, still labels the spaces that exist", () => {
    setup([1, 3], [sp(100, 1), sp(101, 1), sp(102, 2)]);
    run({ FAKE_NO_SA: "1" });
    expect(read().spaces.map((s) => s.label)).toEqual(["s1", "s2", "s6"]);
  });

  it("treats a step that exits 0 but changes nothing as failed, and still labels", () => {
    setup([1, 3], [sp(100, 1), sp(101, 1), sp(102, 2)]);
    expect(run({ FAKE_NOOP_SA: "1" }).code).toBe(0);
    expect(read().spaces.map((s) => s.label)).toEqual(["s1", "s2", "s6"]);
  });

  it("leaves native-fullscreen spaces out of the count and the labels", () => {
    setup([1], [...Array.from({ length: 10 }, (_, i) => sp(100 + i, 1, `s${i + 1}`)), sp(200, 1, "", [7], true)]);
    expect(run().code).toBe(0);
    const after = read();
    expect(after.calls).toEqual([]);
    expect(after.spaces.find((s) => s.id === 200)?.label).toBe("");
  });

  it("removes a surplus space whose only window is pinned on every space", () => {
    const labelled = Array.from({ length: 10 }, (_, i) => sp(100 + i, 1, `s${i + 1}`, [42]));
    setup([1], [...labelled, sp(300, 1, "", [42])], { sticky: [42] });
    expect(run().code).toBe(0);
    expect(read().spaces).toHaveLength(10);
  });

  it("does not plan while a space still points at a screen yabai no longer reports", () => {
    setup([1], [sp(100, 1, "s1"), sp(101, 2, "s6")]);
    const r = run();
    expect(r.code).not.toBe(0);
    expect(read().calls).toEqual([]);
  });

  it("waits for a run already in progress", () => {
    setup([1], Array.from({ length: 10 }, (_, i) => sp(100 + i, 1, `s${i + 1}`)));
    const lock = join(home, ".local/state/dots/yb-spaces.lock");
    Bun.spawnSync(["mkdir", "-p", dirname(lock)]);
    const holder = Bun.spawn(["zsh", "-c", `zmodload zsh/system; : >> ${lock}; zsystem flock ${lock}; print ready; sleep 1.5`], { stdout: "pipe" });
    Bun.sleepSync(400);
    const started = performance.now();
    expect(run().code).toBe(0);
    expect(performance.now() - started).toBeGreaterThan(800);
    holder.kill();
  });
});

describe("yb bar", () => {
  const FAKE = join(import.meta.dir, "support/fake-yabai.ts");
  let state = "";
  let profiler = "";
  let shim = "";
  beforeAll(() => {
    state = join(dir, "bar-state.json");
    profiler = join(dir, "bar-displays.json");
    shim = join(dir, "bar-yabai");
    writeFileSync(shim, `#!/bin/sh\nexec "${process.execPath}" "${FAKE}" "$FAKE_STATE" "$@"\n`);
    chmodSync(shim, 0o755);
  });
  type Sp = { id: number; label: string; display: number; windows: number[]; focus?: boolean; visible?: boolean };
  const sp = (id: number, display: number, label: string, extra: Partial<Sp> = {}): Sp => ({ id, label, display, windows: [], ...extra });
  function setup(displays: number[], spaces: Sp[], apps: Record<string, string> = {}) {
    writeFileSync(state, JSON.stringify({ displays: displays.map((id, i) => ({ id, index: i + 1 })), spaces, nextId: 900, calls: [], apps }));
    writeFileSync(profiler, JSON.stringify({ SPDisplaysDataType: [{ spdisplays_ndrvs: displays.map((id) => ({ _spdisplays_displayID: String(id), ...(id === 1 ? { spdisplays_connection_type: "spdisplays_internal" } : {}) })) }] }));
  }
  // Without resvg (DOTS_RESVG missing) yb bar falls back to SF Symbols; the image path has its own tests.
  const bar = (env: Record<string, string> = {}, args: string[] = []) => {
    const r = Bun.spawnSync([script, "bar", ...args], {
      stdout: "pipe", stderr: "pipe",
      env: { PATH: `${realUsageDir()}:${dirname(findRealBin("jq"))}:/usr/bin:/bin`, HOME: home, DOTS_YABAI: shim, DOTS_DISPLAYS_JSON: profiler, FAKE_STATE: state, DOTS_RESVG: join(dir, "no-resvg"), ...env },
    });
    return { code: r.exitCode, lines: r.stdout.toString().trimEnd().split("\n") };
  };
  const CFG = Buffer.from('{"renderingMode":"Palette","scale":"large","weight":"bold"}').toString("base64");
  const ON = "#000000,#FFFFFF";
  const DIM = "#8A8A8E,#A9B0C2";

  it("draws one square per space: filled focused, outlined on screen, dimmed elsewhere, a dot between screens", () => {
    setup([1, 3], [
      sp(100, 1, "s1", { visible: true }), sp(101, 1, "s2"),
      sp(102, 2, "s6"), sp(103, 2, "s7", { focus: true }), sp(104, 2, "s8", { windows: [42] }), sp(105, 2, "s9"),
    ], { "42": "Code" });
    const { code, lines } = bar();
    expect(code).toBe(0);
    expect(lines[0]).toBe(
      ":1.square: :2.square.fill: · :6.square.fill: :7.square.fill: :8.square.fill: :9.square.fill: | " +
      `symbolize=true sfsize=17 sfconfig=${CFG} sfcolor=${ON} sfcolor2=${DIM} sfcolor3=${DIM} sfcolor4=${ON} sfcolor5=${DIM} sfcolor6=${DIM}`,
    );
    expect(lines[1]).toBe("---");
    expect(lines).toContain(`Space 8 — Code | bash=${home}/.local/bin/yb param1=space param2=8 terminal=false refresh=true sfimage=8.square.fill`);
    expect(lines).toContain(`Space 1 | bash=${home}/.local/bin/yb param1=space param2=1 terminal=false refresh=true sfimage=1.square`);
  });

  it("puts the built-in screen first even when yabai lists the external one first", () => {
    setup([3, 1], [sp(100, 1, "s6", { focus: true }), sp(101, 2, "s1", { visible: true })]);
    expect(bar().lines[0]).toStartWith(":1.square: · :6.square.fill: |");
  });

  it("has no dot with one screen, and numbers unlabelled spaces by index", () => {
    setup([1], [sp(100, 1, "", { focus: true }), sp(101, 1, "")]);
    expect(bar().lines[0]).toStartWith(":1.square.fill: :2.square.fill: |");
  });

  it("joins many apps on one line", () => {
    setup([1], [sp(100, 1, "s1", { focus: true, windows: [1, 2, 3] })], { "1": "Code", "2": "Arc", "3": "Code" });
    expect(bar().lines[2]).toStartWith("Space 1 — Arc, Code |");
  });

  describe("as an image, so it keeps its colours on every screen", () => {
    const twoScreens = () =>
      setup([1, 3], [
        sp(100, 1, "s1", { visible: true }), sp(101, 1, "s2"),
        sp(102, 2, "s6"), sp(103, 2, "s7", { focus: true }), sp(104, 2, "s10"),
      ]);

    it("draws focused solid, on-screen outlined, the rest translucent, a dot between screens", () => {
      twoScreens();
      const svg = bar({}, ["--svg", "#ffffff"]).lines.join("\n");
      expect(svg).toStartWith('<svg xmlns="http://www.w3.org/2000/svg"');
      expect(svg.match(/<circle /g)).toHaveLength(1);
      expect(svg.match(/fill-opacity="1"/g)).toHaveLength(1); // s7, focused
      expect(svg.match(/fill-opacity="0.42"/g)).toHaveLength(3); // s2, s6, s10
      expect(svg).toContain('fill="none" stroke="#ffffff"'); // s1, on screen
      for (const n of ["1", "2", "6", "7", "10"]) expect(svg).toContain(`>${n}</text>`);
    });

    it("sizes the image to the squares: 34 per digit square, 46 for two digits, 8 apart, 14 for the dot", () => {
      twoScreens();
      const width = 34 + 8 + 34 + 8 + 14 + 34 + 8 + 34 + 8 + 46;
      expect(bar({}, ["--svg", "#000000"]).lines[0]).toContain(`width="${width}" height="36"`);
    });

    it("hands SwiftBar a light and a dark PNG", () => {
      twoScreens();
      const resvg = join(dir, "stub-resvg");
      writeFileSync(resvg, '#!/bin/sh\ncp "$1" "$2"\n');
      chmodSync(resvg, 0o755);
      const { lines } = bar({ DOTS_RESVG: resvg });
      const [light, dark] = lines[0]!.replace(/^\| image=/, "").split(",");
      expect(Buffer.from(light!, "base64").toString()).toContain('fill="#000000"');
      expect(Buffer.from(dark!, "base64").toString()).toContain('fill="#ffffff"');
      expect(lines[1]).toBe("---");
    });
  });

  it("shows a dot and says so when yabai is not answering", () => {
    const { code, lines } = bar({ DOTS_YABAI: join(dir, "missing-yabai") });
    expect(code).toBe(0);
    expect(lines[0]).toStartWith("·");
    expect(lines).toContain("yabai is not answering");
  });
});

describe("yb tracing", () => {
  const trace = () => readFileSync(join(home, ".local/state/dots/tiling.log"), "utf8").trim().split("\n");
  const clear = () => rmSync(join(home, ".local/state/dots/tiling.log"), { force: true });

  it("logs each key with the yb call and the result", () => {
    clear();
    yb(["space", "1"], { YB_KEY: "fn 1" });
    expect(trace().at(-1)).toMatch(/^\[\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\] \[fn 1\] \[yb space 1\] ok$/);
  });

  it("marks calls from a terminal as cli, and failures with their exit code", () => {
    clear();
    yb(["close"], { YB_STUB_FAIL: "close" });
    expect(trace().at(-1)).toMatch(/\[cli\] \[yb close\] exit 1$/);
  });

  it("adds where the keyboard ends up when asked", () => {
    clear();
    yb(["space", "7"], { YB_KEY: "fn 7", YB_TRACE_WHERE: "1", YB_STUB_QUERY: '{"index":4,"label":"s7","display":2}' });
    expect(trace().at(-1)).toEndWith("[fn 7] [yb space 7] ok · now s7 on display 2");
  });

  it("logs yabai's own events with the window's app and place", () => {
    clear();
    yb(["event", "window_created"], { YABAI_WINDOW_ID: "42", YB_STUB_QUERY: '{"id":42,"app":"Ghostty","space":3,"display":1}' });
    expect(trace().at(-1)).toMatch(/\[yabai\] \[window_created\] Ghostty #42 on space 3, display 1$/);
  });

  it("shows the last lines with yb log", () => {
    clear();
    yb(["space", "2"], { YB_KEY: "fn 2" });
    expect(yb(["log"]).out).toContain("[fn 2] [yb space 2] ok");
  });
});

describe("yb term on the focused screen", () => {
  it("moves a new Ghostty window that macOS opened on another screen to the focused one", () => {
    const r = yb(["term"], {
      YB_STUB_DISPLAY: '{"index":2}',
      YB_STUB_WINDOWS_1: '[{"id":7,"app":"Ghostty","display":2}]',
      YB_STUB_WINDOWS_2: '[{"id":7,"app":"Ghostty","display":2},{"id":42,"app":"Ghostty","display":1}]',
    });
    expect(r.calls).toContain("-m window 42 --display 2");
    expect(r.calls).toContain("-m window --focus 42");
  });

  it("leaves it alone when it opened on the focused screen", () => {
    const r = yb(["term"], {
      YB_STUB_DISPLAY: '{"index":1}',
      YB_STUB_WINDOWS_2: '[{"id":42,"app":"Ghostty","display":1}]',
    });
    expect(r.calls.some((c) => c.includes("--display 1") && c.includes("window 42"))).toBe(false);
  });
});

describe("yb browser", () => {
  const opened = (args: string[], env: Record<string, string>) => yb(args, env).calls.filter((c) => !c.startsWith("-m "));

  it("fn + ⇧ + Return opens a new tab in the browser's front window (Chromium and Safari: AppleScript)", () => {
    expect(opened(["browser"], { DOTS_BROWSER_ID: "com.google.chrome" })).toEqual(["osascript new tab"]);
    expect(opened(["browser"], { DOTS_BROWSER_ID: "com.apple.safari" })).toEqual(["osascript new tab"]);
  });

  it("Firefox gets its new tab with --new-tab", () => {
    expect(opened(["browser"], { DOTS_BROWSER_ID: "org.mozilla.firefox" })).toEqual(["open -b org.mozilla.firefox --args --new-tab about:newtab"]);
  });

  it("fn + ⌥⇧ + Return opens a new window: Chromium browsers take --new-window", () => {
    expect(opened(["browser", "--window"], { DOTS_BROWSER_ID: "com.google.chrome" }))
      .toEqual(["open -nb com.google.chrome --args --new-window"]);
  });

  it("Safari gets its new window through AppleScript", () => {
    expect(opened(["browser", "--window"], { DOTS_BROWSER_ID: "com.apple.safari" })).toEqual(["osascript Safari new document"]);
  });

  it("moves the new window to the focused screen", () => {
    const r = yb(["browser", "--window"], {
      DOTS_BROWSER_ID: "com.google.chrome",
      YB_STUB_DISPLAY: '{"index":2}',
      YB_STUB_WINDOWS_2: '[{"id":9,"app":"Google Chrome","display":1}]',
    });
    expect(r.calls).toContain("-m window 9 --display 2");
    expect(r.calls).toContain("-m window --focus 9");
  });
});

describe("yb border", () => {
  const NORMAL = 'active_color=gradient(top_left=0xee33ccff,bottom_right=0xee00ff99)';
  const AMBER = "active_color=0xffffb000";
  let borders = "";
  let pgrep = "";
  beforeAll(() => {
    borders = join(dir, "borders");
    writeFileSync(borders, '#!/bin/sh\nprintf \'borders %s\\n\' "$*" >> "$YB_STUB_LOG"\n');
    chmodSync(borders, 0o755);
    pgrep = join(dir, "pgrep");
    writeFileSync(pgrep, '#!/bin/sh\necho "${BORDERS_PID:-100}"\n');
    chmodSync(pgrep, 0o755);
  });
  const state = () => join(home, ".local/state/dots/border");
  const drawn = (args: string[], query: string, pid = "100") =>
    yb(args, { DOTS_BORDERS: borders, YB_STUB_QUERY: query, BORDERS_PID: pid }).calls.filter((c) => c.startsWith("borders "));
  const ZOOMED = '{"has-fullscreen-zoom":true,"has-parent-zoom":false}';
  const PLAIN = '{"has-fullscreen-zoom":false,"has-parent-zoom":false}';

  it("turns the outline amber while the focused window is zoomed, the gradient otherwise", () => {
    rmSync(state(), { force: true });
    expect(drawn(["border"], ZOOMED)).toEqual([`borders ${AMBER}`]);
    expect(drawn(["border"], '{"has-parent-zoom":true}')).toEqual([]);
    expect(drawn(["border"], PLAIN)).toEqual([`borders ${NORMAL}`]);
  });

  it("stays silent while the colour is already right (Mission Control floods focus events)", () => {
    rmSync(state(), { force: true });
    drawn(["border"], PLAIN);
    expect(drawn(["border"], PLAIN)).toEqual([]);
    expect(drawn(["border"], PLAIN)).toEqual([]);
  });

  it("sends the colour again after borders restarts", () => {
    rmSync(state(), { force: true });
    drawn(["border"], PLAIN, "100");
    expect(drawn(["border"], PLAIN, "200")).toEqual([`borders ${NORMAL}`]);
  });

  it("re-checks right after fn + f and fn + ⌥f", () => {
    for (const kind of ["full", "parent"]) {
      rmSync(state(), { force: true });
      expect(drawn(["zoom", kind], ZOOMED)).toEqual([`borders ${AMBER}`]);
    }
  });

  it("uses the same normal colour as config/borders/bordersrc", () => {
    const rc = readFileSync(join(import.meta.dir, "../../../config/borders/bordersrc"), "utf8");
    expect(rc).toContain('active_color="gradient(top_left=0xee33ccff,bottom_right=0xee00ff99)"');
  });
});
