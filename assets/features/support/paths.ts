import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

export const repoRoot = resolve(here, "../../..");
export const binRoot = join(repoRoot, "config/bin");
export const xcLauncher = join(binRoot, "xc");
export const xcFabric = join(binRoot, "xc-fabric");
export const fixtureLauncherBin = join(
  repoRoot,
  "assets/integration/bin/fixtures/xc-launcher/bin",
);
export const fixtureFabricPatterns = join(
  repoRoot,
  "assets/integration/bin/fixtures/xc-fabric/patterns",
);
