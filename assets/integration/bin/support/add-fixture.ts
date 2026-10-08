import { appendFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export interface AddFixture {
  work: string;
  cleanup: () => void;
}

export const gitEnv = { ...Bun.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_SYSTEM: "/dev/null" };

function git(cwd: string, ...args: string[]): string {
  const r = Bun.spawnSync(["git", ...args], { cwd, stdout: "pipe", stderr: "pipe", env: gitEnv });
  if (r.exitCode !== 0) {
    throw new Error(`git ${args.join(" ")} failed: ${new TextDecoder().decode(r.stderr)}`);
  }
  return new TextDecoder().decode(r.stdout);
}

function initRepo(prefix: string): string {
  const work = mkdtempSync(join(tmpdir(), prefix));
  git(work, "init", "-q", "-b", "main");
  git(work, "config", "user.email", "test@example.com");
  git(work, "config", "user.name", "Test User");
  return work;
}

function fixture(work: string): AddFixture {
  return { work, cleanup: () => rmSync(work, { recursive: true, force: true }) };
}

/**
 * Working tree after setup (`git status -s`):
 *    D deleted.txt
 *    M modified.txt
 *   RM old-name.txt -> new-name.txt
 *   MM partial.txt
 *   M  staged.txt            <- fully staged, must NOT be a candidate
 *    M "with space.txt"
 *   ?? newdir/               <- expands to newdir/sub/n.txt
 */
export function makeAddFixture(): AddFixture {
  const work = initRepo("gitx-fza-");
  const p = (f: string) => join(work, f);

  for (const f of ["modified.txt", "deleted.txt", "old-name.txt", "partial.txt", "staged.txt", "with space.txt"]) {
    writeFileSync(p(f), "base\n");
  }
  git(work, "add", "-A");
  git(work, "commit", "-qm", "initial");

  appendFileSync(p("modified.txt"), "x\n");
  rmSync(p("deleted.txt"));
  git(work, "mv", "old-name.txt", "new-name.txt");
  appendFileSync(p("new-name.txt"), "x\n");
  appendFileSync(p("partial.txt"), "x\n");
  git(work, "add", "partial.txt");
  appendFileSync(p("partial.txt"), "y\n");
  appendFileSync(p("staged.txt"), "x\n");
  git(work, "add", "staged.txt");
  appendFileSync(p("with space.txt"), "x\n");
  mkdirSync(p("newdir/sub"), { recursive: true });
  writeFileSync(p("newdir/sub/n.txt"), "n\n");

  return fixture(work);
}

/** A repo with one commit and nothing to add. */
export function makeCleanRepo(): AddFixture {
  const work = initRepo("gitx-fza-clean-");
  writeFileSync(join(work, "a.txt"), "a\n");
  git(work, "add", "-A");
  git(work, "commit", "-qm", "initial");
  return fixture(work);
}

/** A plain directory outside any git repository. */
export function makeNonRepo(): AddFixture {
  return fixture(mkdtempSync(join(tmpdir(), "gitx-fza-norepo-")));
}

/** Paths currently in the index that differ from HEAD. */
export function stagedFiles(cwd: string): string[] {
  return git(cwd, "diff", "--cached", "--name-only").split("\n").filter(Boolean).sort();
}
