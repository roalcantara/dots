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

function resolveBin(name: string, fallback: string): string {
  if (typeof Bun !== "undefined") {
    return Bun.which(name) ?? fallback;
  }
  try {
    return execSync(`which ${name}`, { encoding: "utf8" }).trim() || fallback;
  } catch {
    return existsSync(fallback) ? fallback : name;
  }
}

/** Folder holding the `usage` binary (Homebrew or mise), for subprocess PATHs; xc needs usage and jq. */
export const toolBin = dirname(resolveBin("usage", "/opt/homebrew/bin/usage"));
export const jqBin = dirname(resolveBin("jq", "/opt/homebrew/bin/jq"));
