import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { findRealBin, realUsageDir } from "../../integration/bin/support/paths";

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

/** Folder holding the `usage` binary (Homebrew or mise), for subprocess PATHs; xc needs usage and jq. */
export const toolBin = realUsageDir();
export const jqBin = dirname(findRealBin("jq"));
