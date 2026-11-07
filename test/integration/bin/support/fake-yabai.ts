#!/usr/bin/env bun
// A stand-in for `yabai -m` that keeps displays, spaces, labels and windows in a JSON file, so specs can
// check what `yb spaces` leaves behind. Usage: bun fake-yabai.ts <state.json> -m <domain> ...
// Selectors: a space is a number (index) or a label; a display is its arrangement index.
// Every mutating call is appended to state.calls. Destroying a space that holds windows fails, like
// losing them would. FAKE_NO_SA=1 refuses what needs the scripting addition (create, destroy, move a
// space). A space with fullscreen: true is a native-fullscreen app's space; ids in state.sticky are
// sticky windows, which yabai lists on every space of their screen.
import { readFileSync, writeFileSync } from "node:fs";

export interface FakeSpace { id: number; label: string; display: number; windows: number[]; fullscreen?: boolean }
export interface FakeState { displays: { id: number; index: number }[]; spaces: FakeSpace[]; nextId: number; calls: string[]; sticky?: number[] }

const [statePath, , domain, ...rest] = process.argv.slice(2);
const state: FakeState = JSON.parse(readFileSync(statePath!, "utf8"));

// Spaces of a screen yabai no longer reports (it was just unplugged) come last, as they briefly do in yabai.
const ordered = () => {
  const known = new Set(state.displays.map((d) => d.index));
  return [
    ...[...state.displays].sort((a, b) => a.index - b.index).flatMap((d) => state.spaces.filter((s) => s.display === d.index)),
    ...state.spaces.filter((s) => !known.has(s.display)),
  ];
};
const indexOf = (s: FakeSpace) => ordered().indexOf(s) + 1;
const space = (sel: string): FakeSpace => {
  const list = ordered();
  const hit = /^\d+$/.test(sel) ? list[Number(sel) - 1] : list.find((s) => s.label === sel);
  if (!hit) fail(`could not locate space ${sel}`);
  return hit!;
};
const display = (sel: string) => {
  const hit = state.displays.find((d) => String(d.index) === sel);
  if (!hit) fail(`could not locate display ${sel}`);
  return hit!.index;
};
function fail(message: string): never {
  console.error(message);
  process.exit(1);
}
const done = () => {
  state.calls.push([domain, ...rest].join(" "));
  // keep each display's spaces contiguous, in arrangement order
  state.spaces = ordered();
  writeFileSync(statePath!, JSON.stringify(state));
  process.exit(0);
};

if (domain === "query") {
  if (rest[0] === "--displays") {
    console.log(JSON.stringify(state.displays.map((d) => ({ id: d.id, index: d.index, spaces: ordered().filter((s) => s.display === d.index).map(indexOf) }))));
  } else if (rest[0] === "--spaces") {
    console.log(JSON.stringify(ordered().map((s) => ({ id: s.id, index: indexOf(s), label: s.label, display: s.display, windows: s.windows, "is-native-fullscreen": s.fullscreen ?? false }))));
  } else if (rest[0] === "--windows") {
    const ids = [...new Set(state.spaces.flatMap((s) => s.windows))];
    console.log(JSON.stringify(ids.map((id) => ({ id, "is-sticky": (state.sticky ?? []).includes(id) }))));
  } else fail(`unsupported query ${rest.join(" ")}`);
  process.exit(0);
}

const needsSa = (domain === "space" && (rest[0] === "--create" || rest[1] === "--destroy" || rest[1] === "--display"));
if (needsSa && process.env.FAKE_NO_SA === "1") fail("cannot focus space due to an error with the scripting-addition.");
// yabai 7.1.25 on macOS 27: the addition loads but rejects the OS, so these exit 0 and change nothing.
if (needsSa && process.env.FAKE_NOOP_SA === "1") process.exit(0);

if (domain === "space" && rest[0] === "--create") {
  state.spaces.push({ id: state.nextId++, label: "", display: display(rest[1] ?? "1"), windows: [] });
  done();
}
if (domain === "space" && rest[1] === "--destroy") {
  const s = space(rest[0]!);
  if (s.windows.some((w) => !(state.sticky ?? []).includes(w))) fail(`space ${rest[0]} holds windows`);
  if (state.spaces.filter((x) => x.display === s.display).length === 1) fail("cannot destroy the last space");
  state.spaces = state.spaces.filter((x) => x !== s);
  done();
}
if (domain === "space" && rest[1] === "--display") {
  const s = space(rest[0]!);
  if (state.spaces.filter((x) => x.display === s.display).length === 1) fail("cannot move the last space");
  state.spaces = [...state.spaces.filter((x) => x !== s), { ...s, display: display(rest[2]!) }];
  done();
}
if (domain === "space" && rest[1] === "--label") {
  const s = space(rest[0]!);
  for (const x of state.spaces) if (x.label === rest[2]) x.label = "";
  s.label = rest[2]!;
  done();
}
if (domain === "window" && rest[1] === "--space") {
  const id = Number(rest[0]);
  const from = state.spaces.find((s) => s.windows.includes(id));
  if (!from) fail(`could not locate window ${id}`);
  const to = space(rest[2]!);
  from!.windows = from!.windows.filter((w) => w !== id);
  to.windows.push(id);
  done();
}
fail(`unsupported: ${[domain, ...rest].join(" ")}`);
