import type { Action, Actor } from "@cucumber/screenplay";
import type { CommandResult } from "./run-command";

const lastCommand = (actor: Actor): CommandResult => {
  return actor.recall<CommandResult>("lastCommand");
};

export const LastCommand = {
  exitCode(): Action<number | null> {
    return (actor: Actor) => lastCommand(actor).exitCode;
  },

  stdout(): Action<string> {
    return (actor: Actor) => lastCommand(actor).stdout;
  },

  stderr(): Action<string> {
    return (actor: Actor) => lastCommand(actor).stderr;
  },
};
