import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

export const repoRoot = resolve(here, "../../..");
export const binRoot = join(repoRoot, "config/bin");
export const xcLauncher = join(binRoot, "xc");
export const xcFabric = join(binRoot, "xc-fabric");
export const fixtureLauncherBin = join(
  repoRoot,
  "test/integration/bin/fixtures/xc-launcher/bin",
);
export const fixtureFabricPatterns = join(
  repoRoot,
  "test/integration/bin/fixtures/xc-fabric/patterns",
);

function resolveBinDir(name: string, fallback: string): string {
  if (existsSync(`/opt/homebrew/bin/${name}`)) return "/opt/homebrew/bin";
  if (existsSync(`/usr/local/bin/${name}`)) return "/usr/local/bin";
  try {
    const which = typeof Bun !== "undefined" ? Bun.which(name) : execSync(`which ${name}`, { encoding: "utf8" }).trim();
    if (which && !which.includes(".local/share/mise/shims")) return dirname(which);
  } catch {}
  return dirname(fallback);
}

/** Folder holding the `usage` binary (Homebrew or mise), for subprocess PATHs; xc needs usage and jq. */
export const toolBin = resolveBinDir("usage", "/opt/homebrew/bin/usage");
export const jqBin = resolveBinDir("jq", "/opt/homebrew/bin/jq");
