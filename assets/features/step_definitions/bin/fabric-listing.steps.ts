import { Given, When } from "@cucumber/cucumber";
import type { Actor } from "@cucumber/screenplay";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import {
  binRoot,
  fixtureFabricPatterns,
  xcFabric,
} from "../../support/paths";
import { RunCommand } from "../../support/screenplay/run-command";
import { makeStubs } from "../../support/screenplay/stubs";

const fabricEcho = `#!/bin/sh
printf 'FABRIC_ARGS:'
for arg do printf '[%s]' "$arg"; done
printf '\\n'
stdin=$(cat)
if [ -n "$stdin" ]; then printf 'FABRIC_STDIN:%s\\n' "$stdin"; fi
`;

Given("fixture Fabric patterns exist", function () {
  assert.equal(existsSync(`${fixtureFabricPatterns}/summarize/system.md`), true);
  assert.equal(
    existsSync(`${fixtureFabricPatterns}/youtube_summary/system.md`),
    true,
  );
});

When("{actor} runs `xc-fabric ls --raw`", async (actor: Actor) => {
  const stubsDir = makeStubs({
    "fabric-ai": fabricEcho,
  });
  actor.remember("stubsDir", stubsDir);
  await actor.attemptsTo(
    RunCommand.with(["zsh", xcFabric, "ls", "--raw"], {
      PATH: `${stubsDir}:${binRoot}:/usr/bin:/bin`,
      FABRIC_PATTERNS_DIR: fixtureFabricPatterns,
    }),
  );
});
