import { Given, Then, When } from "@cucumber/cucumber";
import type { Actor } from "@cucumber/screenplay";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import {
  binRoot,
  fixtureLauncherBin,
  xcLauncher,
} from "../../support/paths";
import { LastCommand } from "../../support/screenplay/last-command";
import { RunCommand } from "../../support/screenplay/run-command";

Given("the fixture bin directory contains executable xc tools", function () {
  assert.equal(existsSync(`${fixtureLauncherBin}/xc-sample`), true);
});

Given("the xc launcher is available", function () {
  assert.equal(existsSync(xcLauncher), true);
});

When("{actor} runs `xc list`", async (actor: Actor) =>
  actor.attemptsTo(
    RunCommand.with(["zsh", xcLauncher, "list"], {
      PATH: `${binRoot}:/usr/bin:/bin`,
      XC_BIN_DIR: fixtureLauncherBin,
    }),
  ));

When("{actor} runs `xc -h`", async (actor: Actor) =>
  actor.attemptsTo(
    RunCommand.with(["zsh", xcLauncher, "-h"], {
      PATH: `${binRoot}:/usr/bin:/bin`,
      XC_BIN_DIR: binRoot,
    }),
  ));

Then("{actor} sees the command succeed", (actor: Actor) => {
  assert.equal(actor.ask(LastCommand.exitCode()), 0);
});

Then("{actor} sees {string} in the output", (actor: Actor, text: string) => {
  assert.ok(actor.ask(LastCommand.stdout()).includes(text));
});
