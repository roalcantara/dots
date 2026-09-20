import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export interface GitFixture {
  root: string;
  work: string;
  remote: string;
  cleanup: () => void;
}

function run(cwd: string, ...args: string[]): void {
  const r = Bun.spawnSync(args, {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
    env: { ...Bun.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_SYSTEM: "/dev/null" },
  });
  if (r.exitCode !== 0) {
    throw new Error(`git ${args.join(" ")} failed: ${new TextDecoder().decode(r.stderr)}`);
  }
}

/**
 * Builds a throwaway repo containing, by design:
 *   main            - default branch, protected
 *   merged-branch   - merged into main
 *   unmerged-branch - not merged, `git branch -d` must refuse it
 *   gone-branch     - upstream was deleted on the remote
 *   origin/remote-only - exists only on the remote
 */
export function makeGitFixture(): GitFixture {
  const root = mkdtempSync(join(tmpdir(), "xcg-fixture-"));
  const remote = join(root, "remote");
  const work = join(root, "work");

  run(root, "git", "init", "-q", "--bare", remote);
  run(root, "git", "init", "-q", "-b", "main", work);
  run(work, "git", "config", "user.email", "test@example.com");
  run(work, "git", "config", "user.name", "Test User");

  Bun.write(join(work, "a.txt"), "a\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "initial");
  run(work, "git", "remote", "add", "origin", remote);
  run(work, "git", "push", "-q", "-u", "origin", "main");

  run(work, "git", "checkout", "-qb", "merged-branch");
  Bun.write(join(work, "b.txt"), "b\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "merged work");
  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "merge", "-q", "merged-branch");

  run(work, "git", "checkout", "-qb", "unmerged-branch");
  Bun.write(join(work, "c.txt"), "c\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "unmerged work");

  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "checkout", "-qb", "gone-branch");
  Bun.write(join(work, "d.txt"), "d\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "gone work");
  run(work, "git", "push", "-q", "-u", "origin", "gone-branch");
  run(work, "git", "push", "-q", "origin", "--delete", "gone-branch");

  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "checkout", "-qb", "remote-only");
  Bun.write(join(work, "e.txt"), "e\n");
  run(work, "git", "add", "-A");
  run(work, "git", "commit", "-qm", "remote only");
  run(work, "git", "push", "-q", "-u", "origin", "remote-only");
  run(work, "git", "checkout", "-q", "main");
  run(work, "git", "branch", "-qD", "remote-only");

  run(work, "git", "fetch", "-q", "--prune");

  return { root, work, remote, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}
