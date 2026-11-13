#!/usr/bin/env bun
//MISE description="Push the current feat/post-<slug> branch (never main), through the SOPS git wrapper"
import { pushBranch } from "./_lib";

console.log(`pushed ${pushBranch()}`);
