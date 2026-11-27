#!/usr/bin/env bun
// Concatenating the dots:setup:<part> tasks in flag order (followed by dots:setup:remind) produces the
// exact bootstrap step order from the baseline (with bootstrap:zsh:warm-caches moved after bootstrap:git:hooks).
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const PARTS_TOML = join(REPO, ".mise/tasks/bootstrap/parts.toml");

const PART_ORDER = [
  "brew",
  "yabai",
  "app-files",
  "vscode",
  "bat",
  "lig",
  "macos",
  "swiftbar",
  "git",
  "shell",
  "dev",
  "secrets",
  "tiling",
  "ai",
  "skills",
  "nvim",
  "remind",
];

// The baseline order captured from bootstrap:hook:{post-packages,pre-dotfiles,post-dotfiles,post-defaults,final},
// with bootstrap:zsh:warm-caches moved right after bootstrap:git:hooks per the approved design.
const EXPECTED_STEPS = [
  "bootstrap:brew:install",
  "bootstrap:brew:config-link",
  "bootstrap:brew:bundle",
  "bootstrap:yabai:scripting-addition",
  "bootstrap:dotfiles:move-aside",
  "bootstrap:vscode:settings-sync",
  "bootstrap:bat:cache",
  "bootstrap:lig:zsh",
  "bootstrap:macos:activate",
  "bootstrap:macos:swiftbar",
  "bootstrap:git:filters",
  "bootstrap:git:home-config",
  "bootstrap:git:hooks",
  "bootstrap:zsh:warm-caches",
  "bootstrap:dev:python-tools",
  "bootstrap:gopass:store",
  "bootstrap:gopass:keyring",
  "bootstrap:gopass:pass-link",
  "bootstrap:ssh:keychain",
  "bootstrap:tiling:checks",
  "bootstrap:borders:build",
  "bootstrap:omlx:models",
  "bootstrap:skills:restore",
  "bootstrap:nvim:providers",
  "bootstrap:nvim:plugins",
  "bootstrap:brew:remind",
];

describe("dots:setup part order", () => {
  it("concatenating the parts in flag order gives the baseline order", () => {
    const parts = Bun.TOML.parse(readFileSync(PARTS_TOML, "utf8")) as Record<
      string,
      { hide?: boolean; description?: string; run?: { task: string }[] }
    >;
    const actual: string[] = [];
    for (const part of PART_ORDER) {
      const task = parts[`dots:setup:${part}`];
      expect(task, `dots:setup:${part} exists`).toBeDefined();
      for (const step of task.run ?? []) {
        actual.push(step.task);
      }
    }
    expect(actual).toEqual(EXPECTED_STEPS);
  });
});
