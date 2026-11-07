#!/usr/bin/env bun
// A stand-in for `yabai -m` that keeps displays, spaces, labels and windows in a JSON file, so specs can
// check what `yb spaces` leaves behind. Usage: bun fake-yabai.ts <state.json> -m <domain> ...
// Selectors: a space is a number (index) or a label; a display is its arrangement index.
// Every mutating call is appended to state.calls. Destroying a space that holds windows fails, like
// losing them would.
import { readFileSync, writeFileSync } from "node:fs";

export interface FakeSpace { id: number; label: string; display: number; windows: number[] }
export interface FakeState { displays: { id: number; index: number }[]; spaces: FakeSpace[]; nextId: number; calls: string[] }

const [statePath, , domain, ...rest] = process.argv.slice(2);
const state: FakeState = JSON.parse(readFileSync(statePath!, "utf8"));

const ordered = () =>
  [...state.displays]
    .sort((a, b) => a.index - b.index)
    .flatMap((d) => state.spaces.filter((s) => s.display === d.index));
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
    console.log(JSON.stringify(ordered().map((s) => ({ id: s.id, index: indexOf(s), label: s.label, display: s.display, windows: s.windows }))));
  } else fail(`unsupported query ${rest.join(" ")}`);
  process.exit(0);
}

if (domain === "space" && rest[0] === "--create") {
  state.spaces.push({ id: state.nextId++, label: "", display: display(rest[1] ?? "1"), windows: [] });
  done();
}
if (domain === "space" && rest[1] === "--destroy") {
  const s = space(rest[0]!);
  if (s.windows.length > 0) fail(`space ${rest[0]} holds windows`);
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
