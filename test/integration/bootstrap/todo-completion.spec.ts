#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

const ROOT = join(import.meta.dir, "../../..");
const FIXTURE = join(ROOT, "test/integration/blog/fixtures/TODO.yaml");
const COMPLETIONS = join(ROOT, "config/zsh/opt/completions");
const HOME = process.env.HOME as string;

const TODO_BIN = Bun.which("todo", {
  PATH: (process.env.PATH ?? "") + ":" + (process.env.CARGO_HOME ?? join(HOME, ".local/share/cargo")) + "/bin",
});

const fixtureDir = () => {
  const dir = mkdtempSync(join(tmpdir(), "todo-fixture-"));
  copyFileSync(FIXTURE, join(dir, "TODO.yaml"));
  mkdirSync(join(dir, ".todo"));
  writeFileSync(join(dir, ".todo/config"), "yaml\n");
  return dir;
};

const run = (dir: string, script: string) => {
  const todoDir = TODO_BIN ? dirname(TODO_BIN) : "";
  const completions = join(ROOT, "config/zsh/opt/completions");
  const prelude =
    `fpath=(${completions} $fpath); autoload -Uz _todo_task_ids _todo_tags; ` +
    `_describe() { print -rl -- "\${(@P)argv[-1]}" }; _values() { print -rl -- "\${@[4,-1]}" };`;
  const res = Bun.spawnSync(["zsh", "-fc", `${prelude} ${script}`], {
    cwd: dir,
    env: {
      HOME,
      PATH: `${todoDir}:${process.env.PATH}`,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return {
    stdout: res.stdout.toString(),
    stderr: res.stderr.toString(),
    exitCode: res.exitCode,
  };
};

const fakeTodoDir = (() => {
  const dir = mkdtempSync(join(tmpdir(), "fake-todo-"));
  const fakeTodo = join(dir, "todo");
  writeFileSync(fakeTodo, `#!/bin/sh\nif [ "$1" = "completion" ]; then printf '#compdef todo\\n'; fi\n`, { mode: 0o755 });
  return dir;
})();

const gen = (out: string, prependDir?: string) => {
  const todoDir = TODO_BIN ? dirname(TODO_BIN) : "";
  const pathParts = [prependDir, todoDir, process.env.PATH].filter(Boolean);
  const res = Bun.spawnSync([join(ROOT, "script/todo-completion.sh"), out], {
    cwd: ROOT,
    env: {
      HOME,
      PATH: pathParts.join(":"),
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return {
    stdout: res.stdout.toString(),
    stderr: res.stderr.toString(),
    exitCode: res.exitCode,
  };
};

describe.skipIf(!TODO_BIN)("todo completion helpers", () => {
  it("_todo_task_ids lists every task as id:description", () => {
    const out = run(fixtureDir(), "_todo_task_ids").stdout.split("\n").filter(Boolean);
    const tasks = (Bun.YAML.parse(readFileSync(FIXTURE, "utf8")) as { tasks: unknown[] }).tasks;
    expect(out).toHaveLength(tasks.length);
    expect(out).toContain("P1:Omarchy-ish macOS");
    expect(out).toContain("S1:Series: account-wide numbers and decisions");
  });

  it("_todo_tags lists the tags in use", () => {
    expect(run(fixtureDir(), "_todo_tags").stdout.split("\n").filter(Boolean)).toEqual(
      expect.arrayContaining(["post", "series", "topic-1"]),
    );
  });

  it("both stay silent without a TODO file", () => {
    const r = run(mkdtempSync(join(tmpdir(), "todo-none-")), "_todo_task_ids; a=$?; _todo_tags; print $a $?");
    expect(r.stdout.trim()).toBe("1 1");
    expect(r.stderr).toBe("");
  });
});

describe.skipIf(!Bun.which("zsh"))("todo zsh completion", () => {
  it("compinit binds todo to _todo, not zsh's _devtodo", () => {
    const r = Bun.spawnSync(["zsh", "-fc",
      `fpath=(${COMPLETIONS} $fpath); autoload -Uz compinit; compinit -D -u; print $_comps[todo]`]);
    expect(r.stdout.toString().trim()).toBe("_todo");
  });

  describe.skipIf(!TODO_BIN)("generator", () => {
    it("the committed _todo is what the generator writes", () => {
      const out = join(mkdtempSync(join(tmpdir(), "todo-gen-")), "_todo");
      expect(gen(out).exitCode).toBe(0);
      expect(readFileSync(out, "utf8")).toBe(readFileSync(join(COMPLETIONS, "_todo"), "utf8"));
    });

    it("the generator fails, naming the placeholder, when todo's output changes", () => {
      const out = join(mkdtempSync(join(tmpdir(), "todo-gen-")), "_todo");
      const r = gen(out, fakeTodoDir);
      expect(r.exitCode).toBe(1);
      expect(r.stderr.toString()).toContain("placeholder not found: :id -- ID of the item:_default");
      expect(existsSync(out)).toBe(false);
    });
  });
});
