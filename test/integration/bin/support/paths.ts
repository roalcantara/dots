import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

export const repoRoot = resolve(here, "../../../..");
export const binRoot = join(repoRoot, "config/bin");
export const fixturesDir = join(here, "..", "fixtures");

export function scriptPath(name: string): string {
  return Bun.env[`XC_${name.toUpperCase().replace(/-/g, "_")}`] ?? join(binRoot, name);
}

const cache = new Map<string, string>();

/**
 * The real `name` binary, never a mise shim (the shim needs `mise` on PATH, which the specs strip):
 * PATH order first, then the package-manager prefixes, then `mise which`. Throws when none exists.
 */
export function findRealBin(name: string): string {
  const hit = cache.get(name);
  if (hit) return hit;
  const isDarwin = process.platform === "darwin";
  const strip = (d: string) => d.replace(/\/+$/, "");
  const miseShims = strip(
    join(process.env.MISE_DATA_DIR ?? join(process.env.XDG_DATA_HOME ?? join(homedir(), ".local/share"), "mise"), "shims"),
  );
  const fromPath = (process.env.PATH ?? "")
    .split(":")
    .map(strip)
    .filter((d) => d && d !== miseShims && !d.endsWith("/mise/shims"))
    .map((d) => join(d, name));
  const prefixes = isDarwin
    ? [`/opt/homebrew/bin/${name}`, `/usr/local/bin/${name}`]
    : [`/home/linuxbrew/.linuxbrew/bin/${name}`, `/usr/local/bin/${name}`, `/usr/bin/${name}`];
  let found = [...fromPath, ...prefixes].find((f) => existsSync(f));
  if (!found) {
    const p = Bun.spawnSync(["mise", "which", name], { stdout: "pipe", stderr: "ignore" });
    const out = p.stdout.toString().trim();
    if (p.exitCode === 0 && out && existsSync(out)) found = out;
  }
  if (!found) throw new Error(`${name} not found (install it with Homebrew or mise)`);
  cache.set(name, found);
  return found;
}

export function realUsageBin(): string {
  return findRealBin("usage");
}

export function realUsageDir(): string {
  return dirname(realUsageBin());
}
