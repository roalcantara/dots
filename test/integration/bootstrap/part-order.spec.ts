#!/usr/bin/env bun
// Concatenating the parts' steps (vars.dots_setup_parts) in table order, then the Brewfile reminder, gives the
// exact bootstrap step order from the baseline (with bootstrap:zsh:warm-caches moved after bootstrap:git:hooks).
import { describe, expect, it } from "bun:test";
import { parts } from "./parts";

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

describe("dots setup part order", () => {
  it("concatenating the parts' steps in table order, then the reminder, gives the baseline order", () => {
    expect(parts().map((p) => p.name)).toEqual(PART_ORDER);
    expect([...parts().flatMap((p) => p.steps), "bootstrap:brew:remind"]).toEqual(EXPECTED_STEPS);
  });
});
