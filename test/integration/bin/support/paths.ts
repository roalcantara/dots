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

/** Finds the real system or package-manager binary, skipping mise shims. */
export function findRealBin(name: string): string {
  const isDarwin = process.platform === "darwin";
  const miseShims = join(
    process.env.MISE_DATA_DIR ??
      join(process.env.XDG_DATA_HOME ?? join(homedir(), ".local/share"), "mise"),
    "shims",
  );

  const directCandidates = isDarwin
    ? [`/opt/homebrew/bin/${name}`, `/usr/local/bin/${name}`]
    : [`/home/linuxbrew/.linuxbrew/bin/${name}`, `/usr/local/bin/${name}`, `/usr/bin/${name}`];

  for (const candidate of directCandidates) {
    if (existsSync(candidate)) return candidate;
  }

  for (const dir of (process.env.PATH ?? "").split(":")) {
    if (!dir || dir === miseShims || dir.endsWith("/mise/shims")) continue;
    if (isDarwin && dir.startsWith("/home/linuxbrew")) continue;
    if (!isDarwin && dir.startsWith("/opt/homebrew")) continue;
    const file = join(dir, name);
    if (existsSync(file)) return file;
  }

  return isDarwin ? `/opt/homebrew/bin/${name}` : `/home/linuxbrew/.linuxbrew/bin/${name}`;
}

export function realUsageBin(): string {
  return findRealBin("usage");
}

export function realUsageDir(): string {
  return dirname(realUsageBin());
}
