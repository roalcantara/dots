#!/usr/bin/env bun
// The tiling setup (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md): packages, the fn key
// default, the links bootstrap makes, and the services and rules around yabai.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (p: string) => readFileSync(join(REPO, p), "utf8");
const toml = (p: string) => Bun.TOML.parse(read(p)) as any;

describe("tiling packages and links", () => {
  const brewfile = read("config/homebrew/Brewfile");
  const macos = toml("config/mise/conf.d/macos.toml");
  const dotfiles = toml("config/mise/conf.d/dotfiles.toml");

  it("installs yabai, JankyBorders and Karabiner-Elements on macOS", () => {
    expect(brewfile).toMatch(/^brew "asmvik\/formulae\/yabai", trusted: true if OS\.mac\?/m);
    expect(brewfile).toMatch(/^brew "FelixKratz\/formulae\/borders", trusted: true if OS\.mac\?/m);
    expect(brewfile).toMatch(/^cask "karabiner-elements" if OS\.mac\?/m);
  });

  it("sets the fn (Globe) key to do nothing", () => {
    expect(macos.bootstrap.macos.defaults["com.apple.HIToolbox"].AppleFnUsageType).toBe(0);
  });

  it("links ~/.config/karabiner and ~/.config/borders as whole folders", () => {
    for (const name of ["karabiner", "borders"]) {
      expect(dotfiles.dotfiles[`~/.config/${name}`]).toEqual({ source: `~/.local/share/dots/config/${name}`, relative: true });
    }
  });

  describe("pre-dotfiles hook", () => {
    const HOOK: string = dotfiles.bootstrap.hooks["pre-dotfiles"].run;
    let t: string;
    beforeEach(() => {
      t = mkdtempSync(join(tmpdir(), "yabai-links-"));
    });
    afterEach(() => rmSync(t, { recursive: true, force: true }));

    const run = () => {
      const bin = join(t, "bin");
      mkdirSync(bin, { recursive: true });
      writeFileSync(join(bin, "uname"), "#!/bin/sh\necho Darwin\n");
      chmodSync(join(bin, "uname"), 0o755);
      return Bun.spawnSync(["sh", "-o", "errexit", "-c", HOOK], {
        env: { PATH: `${bin}:/usr/bin:/bin`, HOME: t, DOTS_VSCODE_USER: join(t, "Code", "User") },
        stdout: "pipe",
        stderr: "pipe",
      });
    };
    const config = () => join(t, ".config");

    it("moves a real ~/.config/karabiner aside, keeping its content", () => {
      mkdirSync(join(config(), "karabiner"), { recursive: true });
      writeFileSync(join(config(), "karabiner", "karabiner.json"), "{}\n");
      expect(run().exitCode).toBe(0);
      expect(existsSync(join(config(), "karabiner"))).toBe(false);
      const [moved] = readdirSync(config()).filter((f) => f.startsWith("karabiner.pre-dots-"));
      expect(moved).toMatch(/^karabiner\.pre-dots-\d{14}$/);
      expect(readFileSync(join(config(), moved!, "karabiner.json"), "utf8")).toBe("{}\n");
    });

    it("leaves the dots link alone", () => {
      mkdirSync(config(), { recursive: true });
      symlinkSync(join(REPO, "config/karabiner"), join(config(), "karabiner"));
      expect(run().exitCode).toBe(0);
      expect(lstatSync(join(config(), "karabiner")).isSymbolicLink()).toBe(true);
    });
  });
});

describe("yabai and borders services", () => {
  const yabairc = read("config/yabai/yabairc");
  const sh = (args: string[]) => Bun.spawnSync(args, { stdout: "pipe", stderr: "pipe" });

  it("yabairc and bordersrc are valid sh that shellcheck accepts", () => {
    for (const f of ["config/yabai/yabairc", "config/borders/bordersrc"]) {
      expect(sh(["sh", "-n", join(REPO, f)]).exitCode).toBe(0);
      const r = sh(["shellcheck", "-s", "sh", join(REPO, f)]);
      expect(r.stdout.toString()).toBe("");
    }
  });

  it("loads the scripting addition without ever waiting for a password", () => {
    // the sudoers rule names /opt/homebrew/bin/yabai; sudo matches that path exactly
    expect(yabairc).toContain("sudo -n /opt/homebrew/bin/yabai --load-sa");
    expect(yabairc).not.toMatch(/sudo yabai/);
  });

  it("keeps focus where the keyboard puts it, without animations", () => {
    expect(yabairc).toMatch(/focus_follows_mouse off/);
    expect(yabairc).toMatch(/window_animation_duration 0\.0/);
    expect(yabairc).toMatch(/layout bsp/);
  });

  it("tiles like Hyprland's dwindle: new windows split the newest tile, on its right or bottom half", () => {
    expect(yabairc).toMatch(/window_insertion_point last/);
    expect(yabairc).toMatch(/window_placement second_child/);
    expect(yabairc).toMatch(/split_type auto/);
    // a new window must not undo sizes set with fn + − / =: balance only on fn + b
    expect(yabairc).toMatch(/auto_balance off/);
  });

  it("uses Omarchy's gaps: 10 between windows and at the screen edges", () => {
    for (const key of ["top_padding", "bottom_padding", "left_padding", "right_padding", "window_gap"]) {
      expect(yabairc).toMatch(new RegExp(`${key} 10\\b`));
    }
  });

  it("re-checks the spaces when screens change, and refreshes the SwiftBar strip", () => {
    for (const event of ["display_added", "display_removed", "display_moved"]) {
      expect(yabairc).toMatch(new RegExp(`event=${event} .*action="\\$SPACES"`));
    }
    for (const event of ["space_changed", "display_changed", "window_created", "window_destroyed", "application_front_switched"]) {
      expect(yabairc).toMatch(new RegExp(`event=${event} .*action="\\$BAR"`));
    }
    expect(yabairc).toContain(`BAR="open -g 'swiftbar://refreshplugin?name=spaces'"`);
    expect(yabairc).not.toContain("kb/yabai.screen");
    expect(yabairc).toContain('SPACES="$HOME/.local/bin/yb spaces"');
    expect(yabairc).toMatch(/^\$HOME\/\.local\/bin\/yb spaces/m);
  });

  it("traces its own events next to the keys (yb log)", () => {
    for (const event of ["window_created", "window_destroyed", "space_changed", "display_changed", "application_front_switched"]) {
      expect(yabairc).toContain(`yabai -m signal --add event=${event} label=trace_${event} action="$HOME/.local/bin/yb event ${event}"`);
    }
  });

  it("re-colours the outline on every focus change (amber while zoomed)", () => {
    for (const event of ["window_focused", "application_front_switched"]) {
      expect(yabairc).toContain(`yabai -m signal --add event=${event} label=border_${event} action="$HOME/.local/bin/yb border"`);
    }
  });

  it("leaves settings windows, dialogs and launchers floating", () => {
    for (const app of ["System Settings", "Calculator", "Archive Utility", "Raycast", "Karabiner-Elements"]) {
      expect(yabairc).toContain(`app="^${app}$" manage=off`);
    }
    expect(yabairc).toContain('subrole="^AXDialog$" manage=off');
  });

  it("draws Omarchy's borders: a cyan-to-green gradient when focused, translucent grey otherwise", () => {
    const rc = read("config/borders/bordersrc");
    expect(rc).toContain('active_color="gradient(top_left=0xee33ccff,bottom_right=0xee00ff99)"');
    expect(rc).toContain("inactive_color=0xaa595959");
    // JankyBorders draws one width for every outline: 5.0 thickened the unfocused ones too
    expect(rc).toMatch(/width=2\.0/);
  });

  it("runs yabai and borders as LaunchAgents that restart on exit", () => {
    const agents = toml("config/mise/conf.d/yabai.toml").bootstrap.macos.launchd.agents;
    for (const [name, program] of [["yabai", "/opt/homebrew/bin/yabai"], ["borders", "/opt/homebrew/bin/borders"]]) {
      expect(agents[name!]).toMatchObject({ program, keep_alive: true, run_at_load: true });
      expect(agents[name!].environment.PATH).toStartWith("/opt/homebrew/bin:");
    }
  });
});

describe("scripting addition hook", () => {
  const hook: string = toml("config/mise/conf.d/yabai.toml").bootstrap.hooks["post-packages"].run;

  it("runs the repo's yb sa after Homebrew, on macOS only, and never fails the bootstrap", () => {
    expect(hook).toContain('[ "$(uname)" = Darwin ] || exit 0');
    expect(hook).toContain('"$HOME/.local/share/dots/config/bin/yb" sa || true');
  });

  it("does nothing off macOS", () => {
    const t = mkdtempSync(join(tmpdir(), "yabai-sa-hook-"));
    try {
      writeFileSync(join(t, "uname"), "#!/bin/sh\necho Linux\n");
      chmodSync(join(t, "uname"), 0o755);
      const r = Bun.spawnSync(["sh", "-o", "errexit", "-c", hook], { env: { PATH: `${t}:/usr/bin:/bin`, HOME: t }, stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      expect(r.stdout.toString() + r.stderr.toString()).toBe("");
    } finally {
      rmSync(t, { recursive: true, force: true });
    }
  });
});

describe("SwiftBar space strip", () => {
  const brewfile = read("config/homebrew/Brewfile");
  const dotfiles = toml("config/mise/conf.d/dotfiles.toml");
  const hook: string = toml("config/mise/conf.d/yabai.toml").bootstrap.hooks["post-defaults"].run;
  const plugin = join(REPO, "config/swiftbar/plugins/spaces.sh");

  it("installs SwiftBar and links ~/.config/swiftbar", () => {
    expect(brewfile).toMatch(/^cask "swiftbar" if OS\.mac\?/m);
    // yb bar draws the strip as a PNG with resvg, so it keeps its colours on the unfocused screen too
    expect(brewfile).toMatch(/^brew "resvg" if OS\.mac\?/m);
    expect(dotfiles.dotfiles["~/.config/swiftbar"]).toEqual({ source: "~/.local/share/dots/config/swiftbar", relative: true });
  });

  it("the plugin is executable and prints yb bar with Homebrew on PATH", () => {
    expect(statSync(plugin).mode & 0o111).not.toBe(0);
    const body = readFileSync(plugin, "utf8");
    expect(body).toContain('exec "$HOME/.local/bin/yb" bar');
    expect(body).toContain("/opt/homebrew/bin");
    expect(body).toContain("<swiftbar.hideAbout>true</swiftbar.hideAbout>");
  });

  function runHook(os: string) {
    const t = mkdtempSync(join(tmpdir(), "swiftbar-hook-"));
    try {
      for (const [name, body] of [["uname", `echo ${os}`], ["defaults", `echo "$@" >> "${t}/defaults.calls"`]]) {
        writeFileSync(join(t, name!), `#!/bin/sh\n${body}\n`);
        chmodSync(join(t, name!), 0o755);
      }
      const r = Bun.spawnSync(["bash", "-c", hook], { env: { PATH: `${t}:/usr/bin:/bin`, HOME: t }, stdout: "pipe", stderr: "pipe" });
      return { code: r.exitCode, calls: existsSync(join(t, "defaults.calls")) ? readFileSync(join(t, "defaults.calls"), "utf8") : "", home: t };
    } finally {
      // read before cleanup
    }
  }

  it("points SwiftBar at the plugin folder so its first launch needs no prompt", () => {
    const r = runHook("Darwin");
    expect(r.code).toBe(0);
    expect(r.calls).toContain(`write com.ameba.SwiftBar PluginDirectory -string ${r.home}/.config/swiftbar/plugins`);
    expect(r.calls).toContain("write com.ameba.SwiftBar SUHasLaunchedBefore -bool true");
    rmSync(r.home, { recursive: true, force: true });
  });

  it("does nothing off macOS", () => {
    const r = runHook("Linux");
    expect(r.code).toBe(0);
    expect(r.calls).toBe("");
    rmSync(r.home, { recursive: true, force: true });
  });
});
