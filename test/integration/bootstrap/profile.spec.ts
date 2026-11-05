#!/usr/bin/env bun
// config/.profile is read by the graphical login on Linux: it must keep the XDG_RUNTIME_DIR systemd set
// (/run/user/<uid>, home of the user D-Bus), and only fall back when none is set (macOS, containers).
import { describe, expect, it } from "bun:test";
import { join } from "node:path";

const PROFILE = join(import.meta.dir, "../../../config/.profile");
const runtimeDir = (env: Record<string, string>) =>
  Bun.spawnSync(["sh", "-c", `. "${PROFILE}" >/dev/null 2>&1; printf %s "$XDG_RUNTIME_DIR"`], {
    env: { PATH: "/usr/bin:/bin", HOME: "/tmp/profile-home", ...env }, stdout: "pipe",
  }).stdout.toString();

describe("config/.profile XDG_RUNTIME_DIR", () => {
  it("keeps the session's runtime dir", () => expect(runtimeDir({ XDG_RUNTIME_DIR: "/run/user/1000" })).toBe("/run/user/1000"));
  it("falls back when none is set", () => expect(runtimeDir({ UID: "501" })).toMatch(/^\/tmp\/runtime-/));
});
