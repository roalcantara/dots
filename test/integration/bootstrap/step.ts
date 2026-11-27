#!/usr/bin/env bun
// Helpers for the bootstrap step specs: read a step's #MISE header, run it in a bare environment, and ask its
// skip_if. Steps are plain bash, so a spec drives the file directly instead of extracting shell from TOML.
import { readFileSync } from "node:fs";
import { join } from "node:path";

export const STEPS = join(import.meta.dir, "../../../.mise/tasks/bootstrap");

// #MISE key=value, each value TOML, exactly as mise parses it.
export function header(rel: string): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const line of readFileSync(join(STEPS, rel), "utf8").split("\n")) {
    const match = /^#MISE\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/.exec(line);
    if (!match) continue;
    const [, key, value] = match;
    const parsed = Bun.TOML.parse(`${key} = ${value}`) as Record<string, unknown>;
    out[key] = parsed[key];
  }
  return out;
}

function defaults(rel: string): Record<string, string> {
  return (header(rel).env as Record<string, string> | undefined) ?? {};
}

export function runStep(
  rel: string,
  env: Record<string, string>,
  opts: { stdin?: "ignore" } = {},
): { code: number; out: string; err: string } {
  const proc = Bun.spawnSync(["bash", join(STEPS, rel)], {
    env: { ...defaults(rel), ...env },
    stdin: opts.stdin ?? "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: proc.exitCode ?? 1, out: proc.stdout.toString(), err: proc.stderr.toString() };
}

// True when the step's skip_if exits 0: the step is up to date and would be skipped. No skip_if means false.
export function skipIf(rel: string, env: Record<string, string>): boolean {
  const check = header(rel).skip_if;
  if (typeof check !== "string" || check === "") return false;
  const proc = Bun.spawnSync(["bash", "-c", check], {
    env: { ...defaults(rel), ...env },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  return proc.exitCode === 0;
}
