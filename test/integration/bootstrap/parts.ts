// The parts of `dots setup`, read from `vars.dots_setup_parts` in config/mise/conf.d/tasks.toml: one line per part,
// in run order, `name|help|step step …`. Every bootstrap spec that asks "which part runs this step" reads it here.
import { readFileSync } from "node:fs";
import { join } from "node:path";

export const TASKS_TOML = join(import.meta.dir, "../../../config/mise/conf.d/tasks.toml");

export type Part = { name: string; help: string; steps: string[] };

export function tasksToml(): {
  vars: { dots_setup_parts: string };
  task_templates: Record<string, { usage: string; env: Record<string, string> }>;
  tasks: Record<string, { run: string; usage?: string; description?: string }>;
  doctor: { checks: Record<string, { run: string; hint?: string }> };
} {
  return Bun.TOML.parse(readFileSync(TASKS_TOML, "utf8")) as ReturnType<typeof tasksToml>;
}

export function parts(): Part[] {
  return tasksToml()
    .vars.dots_setup_parts.trim()
    .split("\n")
    .map((line) => {
      const [name, help, steps] = line.split("|");
      return { name, help, steps: steps.trim().split(/\s+/) };
    });
}

export function stepsOf(name: string): string[] {
  const part = parts().find((p) => p.name === name);
  if (!part) throw new Error(`no part ${name}`);
  return part.steps;
}
