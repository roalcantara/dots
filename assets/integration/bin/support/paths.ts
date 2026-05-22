import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

export const repoRoot = resolve(here, "../../../..");
export const binRoot = join(repoRoot, "config/bin");
export const zshFunctionsDir = join(repoRoot, "config/zsh/etc/functions");
export const fixturesDir = join(here, "..", "fixtures");

export function scriptPath(name: string): string {
  return Bun.env[`XC_${name.toUpperCase().replace(/-/g, "_")}`] ?? join(binRoot, name);
}
