#!/usr/bin/env bun
// .github/needs-bootstrap.sh: exits 0 when any changed path is outside docs/** and not *.md; exits 1 otherwise.
import { describe, expect, it } from "bun:test";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const SCRIPT = join(REPO, ".github/needs-bootstrap.sh");

function run(paths: string[]) {
  const input = paths.length > 0 ? `${paths.join("\n")}\n` : "";
  const p = Bun.spawnSync(["bash", SCRIPT], {
    stdin: new TextEncoder().encode(input),
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode ?? 1, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe(".github/needs-bootstrap.sh", () => {
  it("exits 1 for docs/BOOTSTRAP.md", () => {
    expect(run(["docs/BOOTSTRAP.md"]).code).toBe(1);
  });

  it("exits 1 for README.md", () => {
    expect(run(["README.md"]).code).toBe(1);
  });

  it("exits 1 for config/zsh/README.md", () => {
    expect(run(["config/zsh/README.md"]).code).toBe(1);
  });

  it("exits 1 for docs/blog/posts/x.md", () => {
    expect(run(["docs/blog/posts/x.md"]).code).toBe(1);
  });

  it("exits 1 for empty input", () => {
    expect(run([]).code).toBe(1);
  });

  it("exits 0 for config/zsh/.zshrc", () => {
    expect(run(["config/zsh/.zshrc"]).code).toBe(0);
  });

  it("exits 0 for .gitattributes", () => {
    expect(run([".gitattributes"]).code).toBe(0);
  });

  it("exits 0 for docs/x.md plus mise.toml", () => {
    expect(run(["docs/x.md", "mise.toml"]).code).toBe(0);
  });

  it("exits 0 for distros/debian/Dockerfile", () => {
    expect(run(["distros/debian/Dockerfile"]).code).toBe(0);
  });
});
