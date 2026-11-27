#!/usr/bin/env bun
// One failed soft step must not stop the phase (Review Focus 3): a phase of two stub steps, run by mise itself.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const maybe = Bun.which("mise") ? describe : describe.skip;

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "phase-run-"));
  const tasks = join(t, ".mise", "tasks");
  mkdirSync(join(tasks, "bootstrap"), { recursive: true });
  mkdirSync(join(tasks, "test"), { recursive: true });
  copyFileSync(join(REPO, ".mise", "tasks", "bootstrap", "_lib.sh"), join(tasks, "bootstrap", "_lib.sh"));
  writeFileSync(join(t, "mise.toml"), '[task_config]\nincludes = [".mise/tasks", ".mise/tasks/phases.toml"]\n');
  writeFileSync(join(tasks, "phases.toml"), '["test:phase"]\nrun = [{ task = "test:soft" }, { task = "test:touch" }]\n');
  writeFileSync(
    join(tasks, "test", "soft.sh"),
    '#!/usr/bin/env bash\n. "${BASH_SOURCE%/*}/../bootstrap/_lib.sh"\nset -euo pipefail\nwarn "stub"\n',
  );
  writeFileSync(join(tasks, "test", "touch.sh"), `#!/usr/bin/env bash\ntouch "${join(t, "touched")}"\n`);
  for (const f of ["test/soft.sh", "test/touch.sh"]) chmodSync(join(tasks, f), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function run(extra: Record<string, string> = {}) {
  const env = { ...process.env } as Record<string, string | undefined>;
  delete env.CI;
  delete env.DOTS_STRICT;
  Object.assign(env, { MISE_TRUSTED_CONFIG_PATHS: t }, extra);
  const p = Bun.spawnSync(["mise", "run", "-C", t, "test:phase"], {
    env: env as Record<string, string>,
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode, err: p.stderr.toString(), touched: existsSync(join(t, "touched")) };
}

maybe("a phase continues past a failing soft step", () => {
  it("warn() continues, so the next step runs and the phase exits 0", () => {
    const r = run();
    expect(r.code).toBe(0);
    expect(r.touched).toBe(true);
    expect(r.err).toContain("bootstrap: stub failed, continuing");
  });

  it("under CI=1 the soft failure is fatal, so the next step does not run", () => {
    const r = run({ CI: "1" });
    expect(r.code).not.toBe(0);
    expect(r.touched).toBe(false);
  });
});
