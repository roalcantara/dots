import { spawnSync } from "node:child_process";
import type { Actor, Action } from "@cucumber/screenplay";

export type CommandResult = {
  readonly exitCode: number | null;
  readonly stdout: string;
  readonly stderr: string;
};

type CommandEnvironment = Record<string, string | undefined>;

export const RunCommand = {
  with(command: readonly string[], env: CommandEnvironment = {}): Action {
    return (actor: Actor) => {
      const result = spawnSync(command[0], command.slice(1), {
        encoding: "utf8",
        env: {
          ...process.env,
          ...env,
        },
      });

      actor.remember("lastCommand", {
        exitCode: result.status,
        stdout: result.stdout,
        stderr: result.stderr,
      } satisfies CommandResult);
    };
  },
};
