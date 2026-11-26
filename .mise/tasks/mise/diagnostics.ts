#!/usr/bin/env bun
//MISE description="Report mise config diagnostics from mise lsp (deprecated or unknown keys)"
// No CLI reports deprecated-key: only `mise lsp` publishes it. This is a small LSP client over stdio:
// initialize, then didOpen every file, and collect textDocument/publishDiagnostics until each has reported.
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const ROOT = resolve(process.env.DOTS_DIR ?? join(import.meta.dir, "../../.."));
const CODES = new Set(["deprecated-key", "unknown-key"]);
const DEADLINE_MS = 10_000;

// mise lsp serves mise.toml and the other files mise loads; a file with another name is copied to a temp
// mise.toml so it is parsed at all, and its diagnostics are mapped back to the original path.
function served(path: string): boolean {
  const name = basename(path);
  const parent = basename(dirname(path));
  return (
    name === "mise.toml" ||
    name === ".mise.toml" ||
    name === "mise.local.toml" ||
    /^mise\..+\.toml$/.test(name) ||
    ((name === "config.toml" || name === "config.local.toml") && parent === "mise") ||
    parent === "conf.d"
  );
}

function defaultFiles(): string[] {
  const glob = new Bun.Glob("config/mise/**/*.toml");
  const files = ["mise.toml", ...glob.scanSync({ cwd: ROOT, onlyFiles: true }), "config/bin/mise.toml"];
  return [...new Set(files)].filter((f) => existsSync(join(ROOT, f))).sort();
}

const args = process.argv.slice(2);
const files = args.length > 0 ? args.map((a) => resolve(a)) : defaultFiles().map((f) => join(ROOT, f));

const tempDirs: string[] = [];
const docs = files.map((file) => {
  let openPath = file;
  if (!served(file)) {
    const dir = mkdtempSync(join(tmpdir(), "mise-diagnostics-"));
    tempDirs.push(dir);
    openPath = join(dir, "mise.toml");
    writeFileSync(openPath, readFileSync(file));
  }
  const shown = file.startsWith(ROOT + "/") ? relative(ROOT, file) : file;
  return { uri: pathToFileURL(openPath).href, shown };
});

const cleanup = () => {
  for (const dir of tempDirs) rmSync(dir, { recursive: true, force: true });
};

const proc = (() => {
  try {
    return Bun.spawn(["mise", "lsp"], {
      cwd: ROOT,
      env: { ...process.env, MISE_TRUSTED_CONFIG_PATHS: [ROOT, ...tempDirs].join(":") },
      stdin: "pipe",
      stdout: "pipe",
      stderr: "pipe",
    });
  } catch (err) {
    cleanup();
    console.error(`mise:diagnostics: mise lsp did not answer (${(err as Error).message})`);
    process.exit(2);
  }
})();

const encoder = new TextEncoder();
function send(message: unknown) {
  const body = encoder.encode(JSON.stringify(message));
  proc.stdin.write(encoder.encode(`Content-Length: ${body.length}\r\n\r\n`));
  proc.stdin.write(body);
  proc.stdin.flush();
}

send({
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: { processId: process.pid, rootUri: pathToFileURL(ROOT).href, capabilities: {} },
});
send({ jsonrpc: "2.0", method: "initialized", params: {} });
for (const doc of docs) {
  send({
    jsonrpc: "2.0",
    method: "textDocument/didOpen",
    params: {
      textDocument: {
        uri: doc.uri,
        languageId: "toml",
        version: 1,
        text: readFileSync(new URL(doc.uri), "utf8"),
      },
    },
  });
}

type Found = { shown: string; line: number; code: string; message: string };
const byUri = new Map(docs.map((d) => [d.uri, d.shown]));
const reported = new Set<string>();
const found: Found[] = [];

const reader = proc.stdout.getReader();
const decoder = new TextDecoder();
let buffer = new Uint8Array(0);
const deadline = Date.now() + DEADLINE_MS;

function append(chunk: Uint8Array) {
  const next = new Uint8Array(buffer.length + chunk.length);
  next.set(buffer);
  next.set(chunk, buffer.length);
  buffer = next;
}

function takeMessage(): unknown | undefined {
  const sep = [13, 10, 13, 10];
  let at = -1;
  outer: for (let i = 0; i + 3 < buffer.length; i++) {
    for (let j = 0; j < 4; j++) if (buffer[i + j] !== sep[j]) continue outer;
    at = i;
    break;
  }
  if (at < 0) return undefined;
  const header = decoder.decode(buffer.slice(0, at));
  const match = /Content-Length:\s*(\d+)/i.exec(header);
  const length = match ? Number(match[1]) : 0;
  if (buffer.length < at + 4 + length) return undefined;
  const body = decoder.decode(buffer.slice(at + 4, at + 4 + length));
  buffer = buffer.slice(at + 4 + length);
  try {
    return JSON.parse(body);
  } catch {
    return undefined;
  }
}

while (reported.size < docs.length && Date.now() < deadline) {
  const remaining = deadline - Date.now();
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<null>((resolveTimeout) => {
    timer = setTimeout(() => resolveTimeout(null), remaining);
  });
  const result = await Promise.race([reader.read(), timeout]);
  if (timer) clearTimeout(timer);
  if (!result || result.done) break;
  append(result.value);
  for (let message = takeMessage(); message !== undefined; message = takeMessage()) {
    const msg = message as {
      method?: string;
      params?: { uri?: string; diagnostics?: { range: { start: { line: number } }; code?: string; message?: string }[] };
    };
    if (msg.method !== "textDocument/publishDiagnostics" || !msg.params?.uri) continue;
    reported.add(msg.params.uri);
    for (const d of msg.params.diagnostics ?? []) {
      const code = d.code ?? "";
      if (!CODES.has(code)) continue;
      found.push({ shown: byUri.get(msg.params.uri) ?? msg.params.uri, line: d.range.start.line + 1, code, message: d.message ?? "" });
    }
  }
}

proc.kill();
cleanup();

if (reported.size === 0 || reported.size < docs.length) {
  console.error("mise:diagnostics: mise lsp did not answer");
  process.exit(2);
}

found.sort((a, b) => a.shown.localeCompare(b.shown) || a.line - b.line);
for (const d of found) console.log(`${d.shown}:${d.line}\t${d.code}\t${d.message}`);
process.exit(found.length > 0 ? 1 : 0);
