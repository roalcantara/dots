#!/usr/bin/env bun
// distros/bootstrap.sh: shared strict container bootstrap script called by both the Dockerfile and PR CI.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const SCRIPT = join(REPO, "distros/bootstrap.sh");
const DOCKERFILE = join(REPO, "distros/debian/Dockerfile");

let t: string;
let binDir: string;
let logFile: string;
let curlLog: string;

function writeStub(dir: string, name: string, body: string) {
  const path = join(dir, name);
  writeFileSync(path, `#!/usr/bin/env bash\n${body}\n`);
  chmodSync(path, 0o755);
  return path;
}

beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "distro-bootstrap-"));
  binDir = join(t, "stubs");
  logFile = join(t, "mise.log");
  curlLog = join(t, "curl.log");
  mkdirSync(binDir, { recursive: true });
  mkdirSync(join(t, ".local/share/dots/config/mise"), { recursive: true });
  mkdirSync(join(t, ".local/bin"), { recursive: true });

  // Stub curl: record argv and emit a shell script that creates ~/.local/bin/mise if missing
  writeStub(
    binDir,
    "curl",
    `printf '%s\\n' "$*" >> "${curlLog}"
cat <<'EOF'
#!/usr/bin/env bash
mkdir -p "$HOME/.local/bin"
cat <<'MISE' > "$HOME/.local/bin/mise"
#!/usr/bin/env bash
printf 'DOTS_STRICT=%s ARGS=%s\\n' "\${DOTS_STRICT:-}" "$*" >> "${logFile}"
exit \${STUB_MISE_EXIT:-0}
MISE
chmod +x "$HOME/.local/bin/mise"
EOF`,
  );
});

afterEach(() => rmSync(t, { recursive: true, force: true }));

function run(env: Record<string, string> = {}) {
  const p = Bun.spawnSync(["bash", SCRIPT], {
    cwd: t,
    env: {
      PATH: `${binDir}:${process.env.PATH ?? "/usr/bin:/bin"}`,
      HOME: t,
      ...env,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe("distros/bootstrap.sh", () => {
  it("runs mise bootstrap strictly for the container profile and saves it", () => {
    const r = run();
    expect(r.code).toBe(0);
    const lines = readFileSync(logFile, "utf8").trim().split("\n");
    expect(lines).toContain(
      "DOTS_STRICT=1 ARGS=bootstrap -E container --save-env --force-dotfiles --skip user --yes",
    );
  });

  it("links ~/.config/mise to the checkout's config/mise", () => {
    const r = run();
    expect(r.code).toBe(0);
    expect(readlinkSync(join(t, ".config/mise"))).toBe("../.local/share/dots/config/mise");
  });

  it("skips the installer when the pinned mise is present", () => {
    writeStub(
      join(t, ".local/bin"),
      "mise",
      `if [ "\${1:-}" = "--version" ]; then
  echo "2026.11.14 linux-x64 (2026-11-14)"
  exit 0
fi
printf 'DOTS_STRICT=%s ARGS=%s\\n' "\${DOTS_STRICT:-}" "$*" >> "${logFile}"
exit \${STUB_MISE_EXIT:-0}`,
    );
    const r = run();
    expect(r.code).toBe(0);
    expect(Bun.file(curlLog).size).toBe(0);
  });

  it("a failing bootstrap fails the script", () => {
    const r = run({ STUB_MISE_EXIT: "3" });
    expect(r.code).toBe(3);
  });

  it("the Dockerfile's local and remote stages call distros/bootstrap.sh and carry no MISE_VERSION", () => {
    const src = readFileSync(DOCKERFILE, "utf8");
    expect(src).not.toContain("MISE_VERSION");
    const localStage = src.split(/^FROM base AS local$/m)[1]?.split(/^FROM /m)[0] ?? "";
    const remoteStage = src.split(/^FROM base AS remote$/m)[1]?.split(/^FROM /m)[0] ?? "";
    expect(localStage).toContain("distros/bootstrap.sh");
    expect(remoteStage).toContain("distros/bootstrap.sh");
  });
});
