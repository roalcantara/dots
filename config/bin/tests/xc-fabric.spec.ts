#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) =>
  selected !== "" && selected !== id;
const script =
  Bun.env.XC_FABRIC ?? join(import.meta.dir, "..", "xc-fabric");

const fixturesDir = join(
  import.meta.dir,
  "fixtures",
  "xc-fabric",
  "patterns",
);

const basePath = "/usr/bin:/bin:/usr/sbin:/sbin";

function makeTmpStubs(stubs: Record<string, string>): string {
  const tmp = mkdtempSync(join(tmpdir(), "xc-fabric-spec-"));
  for (const [name, body] of Object.entries(stubs)) {
    writeFileSync(join(tmp, name), body, { mode: 0o755 });
  }
  return tmp;
}

const fabricEcho = `#!/bin/sh
printf 'FABRIC_ARGS:'
for arg do printf '[%s]' "$arg"; done
printf '\\n'
stdin=$(cat)
if [ -n "$stdin" ]; then printf 'FABRIC_STDIN:%s\\n' "$stdin"; fi
`;

const minimalStubs = {
  "fabric-ai": fabricEcho,
  gum: "#!/bin/sh\nexit 0\n",
};

const noGumStubs = {
  "fabric-ai": fabricEcho,
};

function decode(bytes: Uint8Array): string {
  return new TextDecoder().decode(bytes);
}

function run(
  args: string[],
  options: {
    stubs?: Record<string, string>;
    env?: Record<string, string>;
    input?: string;
    pty?: boolean;
  } = {},
) {
  const tmp = makeTmpStubs(options.stubs ?? minimalStubs);
  const env = {
    ...Bun.env,
    PATH: `${tmp}:${basePath}`,
    FABRIC_PATTERNS_DIR: fixturesDir,
    ...options.env,
  };
  try {
    const cmd = options.pty
      ? ["script", "-q", "/dev/null", "zsh", script, ...args]
      : ["zsh", script, ...args];
    const finalCmd =
      options.input === undefined
        ? cmd
        : [
            "sh",
            "-c",
            'input="$1"; shift; printf "%s" "$input" | "$@"',
            "sh",
            options.input,
            ...cmd,
          ];
    const result = Bun.spawnSync(finalCmd, {
      env,
      stdout: "pipe",
      stderr: "pipe",
    });
    return {
      exitCode: result.exitCode,
      stdout: decode(result.stdout),
      stderr: decode(result.stderr),
      tmp,
      cleanup: () => rmSync(tmp, { recursive: true, force: true }),
    };
  } catch (error) {
    rmSync(tmp, { recursive: true, force: true });
    throw error;
  }
}

describe("xc-fabric", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when help is requested", () => {
    it("prints usage for -h and --help", () => {
      for (const flag of ["-h", "--help"]) {
        const r = Bun.spawnSync(["zsh", script, flag], {
          stdout: "pipe",
          stderr: "pipe",
        });
        expect(r.exitCode).toBe(0);
        const out = decode(r.stdout);
        expect(out).toContain("xc-fabric");
        expect(out).toContain("Usage:");
        expect(decode(r.stderr)).toBe("");
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("missing_fabric"))("when fabric is missing", () => {
    it("exits fatally", () => {
      const r = run(["ls"], { stubs: { gum: "#!/bin/sh\necho \"$*\" >&2\n" } });
      try {
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toContain("fabric");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("ls_raw"))("when listing raw patterns", () => {
    it("prints TSV without a table", () => {
      const r = run(["ls", "--raw"]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("summarize\tSummarize content into key points.");
        expect(r.stdout).toContain("extract_wisdom\tExtract insights and wisdom from text.");
        expect(r.stdout).not.toContain("gum");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("ls_table"))("when listing interactively", () => {
    it("pipes through gum table", async () => {
      const gumLog = join(tmpdir(), `xc-fabric-gum-${Date.now()}`);
      const r = run(["ls"], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: `#!/bin/sh\nprintf '%s\\n' "$*" >> ${gumLog}\ncat\n`,
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(await Bun.file(gumLog).text()).toContain("table");
      } finally {
        r.cleanup();
        rmSync(gumLog, { force: true });
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_raw"))("when running a pattern raw", () => {
    it("passes stdin to fabric", () => {
      const r = run(["run", "summarize", "--raw"], {
        stubs: noGumStubs,
        input: "hello world",
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("FABRIC_ARGS:[--pattern][summarize]");
        expect(r.stdout).toContain("FABRIC_STDIN:hello world");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_youtube_url"))("when running with a YouTube URL", () => {
    it("uses fabric -y", () => {
      const r = run([
        "run",
        "summarize",
        "https://www.youtube.com/watch?v=abc",
        "--raw",
      ]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[-y][https://www.youtube.com/watch?v=abc]");
        expect(r.stdout).toContain("[--pattern][summarize]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_youtube_pattern"))("when pattern implies YouTube", () => {
    it("prompts for the YouTube URL", () => {
      const r = run(["run", "youtube_summary", "--raw"], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: "#!/bin/sh\nif [ \"$1\" = input ]; then echo https://youtu.be/xyz; fi\n",
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[-y][https://youtu.be/xyz]");
        expect(r.stdout).toContain("[--pattern][youtube_summary]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_copy"))("when copy is requested", () => {
    it("passes --copy to fabric", () => {
      const r = run(["run", "summarize", "--copy", "--raw"], { input: "copy me" });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--copy]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_output"))("when output is requested", () => {
    it("passes --output and skips rendering", () => {
      const r = run(["run", "summarize", "--output", "/tmp/out.md"], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: "#!/bin/sh\nshift; while [ \"$1\" != -- ]; do shift; done; shift; exec \"$@\"\n",
          glow: "#!/bin/sh\necho GLOW_CALLED\ncat\n",
        },
        input: "write me",
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--output][/tmp/out.md]");
        expect(r.stdout).not.toContain("GLOW_CALLED");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("run_variable"))("when variables are supplied", () => {
    it("passes repeated variables verbatim", () => {
      const r = run([
        "run",
        "summarize",
        "-v",
        "audience:engineers",
        "--variable=style:brief",
        "--raw",
      ], { input: "vars" });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[-v][audience:engineers]");
        expect(r.stdout).toContain("[--variable=style:brief]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("yt_flags"))("when YouTube flags are supplied", () => {
    it("maps wrapper flags to fabric flags", () => {
      const r = run([
        "run",
        "summarize",
        "https://youtu.be/abc",
        "--yt-timestamps",
        "--yt-comments",
        "--yt-metadata",
        "--yt-playlist",
        "--raw",
      ]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--transcript-with-timestamps]");
        expect(r.stdout).toContain("[--comments]");
        expect(r.stdout).toContain("[--metadata]");
        expect(r.stdout).toContain("[--playlist]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("render_fallback"))("when glow is absent and bat exists", () => {
    it("renders through bat", () => {
      const r = run(["run", "summarize"], {
        stubs: {
          "fabric-ai": "#!/bin/sh\necho '# rendered'\ncat >/dev/null\n",
          bat: "#!/bin/sh\necho BAT_CALLED\ncat\n",
        },
        input: "render",
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("BAT_CALLED");
        expect(r.stdout).toContain("# rendered");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("clip_macos"))("when stdin is a TTY on macOS", () => {
    it("reads from pbpaste", () => {
      const r = run(["run", "summarize", "--raw"], {
        pty: true,
        stubs: {
          "fabric-ai": fabricEcho,
          gum: "#!/bin/sh\nexit 0\n",
          uname: "#!/bin/sh\necho Darwin\n",
          pbpaste: "#!/bin/sh\necho clipboard-macos\n",
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("FABRIC_STDIN:clipboard-macos");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("clip_linux"))("when stdin is a TTY on Linux", () => {
    it("reads from xclip", () => {
      const r = run(["run", "summarize", "--raw"], {
        pty: true,
        stubs: {
          "fabric-ai": fabricEcho,
          gum: "#!/bin/sh\nexit 0\n",
          uname: "#!/bin/sh\necho Linux\n",
          xclip: "#!/bin/sh\necho clipboard-linux\n",
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("FABRIC_STDIN:clipboard-linux");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("update"))("when updating patterns", () => {
    it("runs fabric -U", () => {
      const r = run(["update", "--raw"]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("FABRIC_ARGS:[-U]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("show"))("when showing a pattern", () => {
    it("runs fabric --readpattern", () => {
      const r = run(["show", "summarize", "--raw"]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--readpattern][summarize]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("strategies"))("when listing strategies", () => {
    it("uses fabric --liststrategies and gum table", async () => {
      const gumLog = join(tmpdir(), `xc-fabric-strategies-${Date.now()}`);
      const r = run(["strategies"], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: `#!/bin/sh\nprintf '%s\\n' "$*" >> ${gumLog}\ncat\n`,
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--liststrategies]");
        expect(await Bun.file(gumLog).text()).toContain("table");
      } finally {
        r.cleanup();
        rmSync(gumLog, { force: true });
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("strategy_passthrough"))("when a strategy is supplied", () => {
    it("passes --strategy to fabric", () => {
      const r = run(["run", "summarize", "--strategy", "cot", "--raw"], {
        input: "think",
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[--strategy][cot]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("scrape_url"))("when scraping a URL", () => {
    it("uses fabric -u", () => {
      const r = run(["scrape", "https://example.com", "summarize", "--raw"]);
      try {
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("[-u][https://example.com]");
        expect(r.stdout).toContain("[--pattern][summarize]");
      } finally {
        r.cleanup();
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("picker_fzf_preferred"))("when fzf is available", () => {
    it("uses fzf with preview controls", async () => {
      const fzfLog = join(tmpdir(), `xc-fabric-fzf-${Date.now()}`);
      const r = run([], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: "#!/bin/sh\nexit 0\n",
          fzf: `#!/bin/sh
{
  echo "===ARGS==="
  printf '%s\\n' "$*"
  echo "===STDIN==="
  cat
} > ${fzfLog}
head -n 1
`,
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        const log = await Bun.file(fzfLog).text();
        expect(log).toContain("===ARGS===");
        expect(log).toContain("--preview-window");
        expect(log).toContain("toggle-preview");
        expect(log).toContain("--ansi");
        expect(log).toContain("--delimiter");
        expect(log).toContain("--with-nth");
        expect(log).toContain("Ctrl-/");
        expect(log).toContain("--layout=default");
        expect(log).toContain("preview-bg:");
        expect(log).toContain("header-bg:");
        // Preview is one `--preview=…` argument; assert tuning inside that snippet, not fzf-native flags.
        expect(log).toContain("FZF_PREVIEW_COLUMNS");
        expect(log).toContain("paging=never");
      } finally {
        r.cleanup();
        rmSync(fzfLog, { force: true });
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("picker_fzf_stdin_lines"))(
    "when fzf receives pattern stdin",
    () => {
      it("sends one physical line per pattern without embedded newlines in a row", async () => {
        const fzfLog = join(tmpdir(), `xc-fabric-fzf-stdin-${Date.now()}`);
        const r = run([], {
          stubs: {
            "fabric-ai": fabricEcho,
            gum: "#!/bin/sh\nexit 0\n",
            fzf: `#!/bin/sh
{
  echo "===ARGS==="
  printf '%s\\n' "$*"
  echo "===STDIN==="
  cat
} > ${fzfLog}
head -n 1
`,
          },
        });
        try {
          expect(r.exitCode).toBe(0);
          const log = await Bun.file(fzfLog).text();
          const stdinPart = log.split("===STDIN===\n")[1] ?? "";
          const lines = stdinPart
            .replace(/\n$/, "")
            .split("\n")
            .filter((l) => l.includes("\t"));
          expect(lines.length).toBe(3);
          for (const line of lines) {
            expect((line.match(/\t/g) ?? []).length).toBe(1);
            expect(line).not.toMatch(/\n/);
          }
        } finally {
          r.cleanup();
          rmSync(fzfLog, { force: true });
        }
      });
    },
  );

  describe.skipIf(skipWhenOtherScenario("picker_gum_fallback"))("when fzf is absent", () => {
    it("falls back to gum filter", async () => {
      const gumLog = join(tmpdir(), `xc-fabric-filter-${Date.now()}`);
      const r = run([], {
        stubs: {
          "fabric-ai": fabricEcho,
          gum: `#!/bin/sh\nprintf '%s\\n' "$*" >> ${gumLog}\nif [ "$1" = filter ]; then head -n 1; fi\n`,
        },
      });
      try {
        expect(r.exitCode).toBe(0);
        expect(await Bun.file(gumLog).text()).toContain("filter");
      } finally {
        r.cleanup();
        rmSync(gumLog, { force: true });
      }
    });
  });
});
