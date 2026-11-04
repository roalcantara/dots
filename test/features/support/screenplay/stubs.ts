import { mkdtempSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

export function makeStubs(stubs: Record<string, string>): string {
  const tmp = mkdtempSync(join(tmpdir(), "dots-bdd-stubs-"));
  for (const [name, body] of Object.entries(stubs)) {
    writeFileSync(join(tmp, name), body, { mode: 0o755 });
  }
  return tmp;
}
