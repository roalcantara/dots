# LazyVim Conformance & Lua Optimization Audit Implementation Plan

<!-- markdownlint-disable-file MD013 -->
<!-- Long lines below are verbatim shell commands and exact source quotes;
     wrapping them would break the copy-paste contract of this plan. -->

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove configuration in `config/nvim` that duplicates or conflicts
with LazyVim, adopt the official extras that replace hand-rolled specs, and
eliminate the eager `require` calls that cost ~38ms of startup.

**Architecture:** Six risk-ordered phases. Phase 0 captures a baseline of
startup time, keymaps, autocmds and health. Phases 1-5 each make a scoped
change and diff against that baseline. One commit per task, each
independently revertible.

**Tech Stack:** Neovim 0.12.4, LazyVim, lazy.nvim, Mason, blink.cmp,
conform.nvim, Lua, busted (Docker), mise.

**Spec:** `docs/superpowers/specs/2026-08-22-lazyvim-conformance-audit-design.md`

---

## Orientation for the implementing engineer

You are editing a personal Neovim configuration that lives in a dotfiles
repo at `config/nvim/` and is symlinked to `~/.config/nvim`. Verify the
symlink before you start — every headless check in this plan runs the real
`nvim`, which reads `~/.config/nvim`, not the repo path.

Three facts that will otherwise confuse you:

1. **LazyVim is a framework, not a plugin.** It ships its own
   `options.lua`, `autocmds.lua`, `keymaps.lua` and ~30 plugin specs. Its
   source is readable at
   `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`. When this plan says
   "LazyVim already does X", you can read the file and confirm it.
2. **Load order matters.** LazyVim loads its own `config/options.lua`
   first, then yours. Same for keymaps and autocmds. So your file can
   override LazyVim's values, and can `vim.keymap.del` LazyVim's keymaps.
3. **`opts` merges, `config` replaces.** For LazyVim's core plugins never
   write `config = function() ... end` — it bypasses LazyVim's setup. Use
   `opts` (a table merges recursively) or `opts = function(_, opts)` (to
   mutate the merged table). List values do *not* merge — they replace.

### Commands you will use repeatedly

```bash
# From the repo root
cd /Users/roalcantara/Work/dots

# Headless startup check — must print nothing
nvim --headless +q

# Startup timing
mise exec -- mise run startuptime --logdir ./.tmp/logs --log

# Commits must go through mise (the pre-commit hook needs `hk` on PATH)
mise exec -- git commit -m "..."
```

If `git commit` fails with `exec: hk: not found`, you forgot the
`mise exec --` prefix.

---

## File Structure

**Create:**

- `config/nvim/tools/baseline.sh` — captures and diffs the verification
  snapshot. Single responsibility: produce comparable text dumps of nvim's
  observable state. No other file calls it; it is a developer tool.
- `config/nvim/specs/core/vi/paths_has_spec.lua` — busted spec for
  `core/vi/paths.has`.

**Modify:**

- `config/nvim/lua/plugins/formater.lua` — Task 2
- `config/nvim/lua/config/options.lua` — Tasks 2, 3, 10, 14
- `config/nvim/lua/config/keymaps.lua` — Tasks 4, 12, 16
- `config/nvim/lua/plugins/ui.lua` — Tasks 4, 5, 6, 11, 12, 13, 14, 15
- `config/nvim/lua/config/autocmds.lua` — Tasks 7, 8, 9, 12
- `config/nvim/lua/config/lazy.lua` — Task 11
- `config/nvim/lazyvim.json` — Task 11
- `config/nvim/lua/plugins/markdown.lua` — Task 13
- `config/nvim/lua/plugins/coding.lua` — Tasks 13, 15
- `config/nvim/lua/config/usercmds.lua` — Task 14
- `config/nvim/lua/plugins/lsp.lua` — Task 17
- `config/nvim/.gitignore` — Task 1

**Deliberately not touched:** everything under `config/nvim/lua/core/`
except moving where it is required from. See the spec's "Out of scope".

---

## Correction to the spec

The spec's Phase 5 proposed a busted spec asserting that loading
`plugins/ui.lua` does not put `core/ui/statusline` into `package.loaded`.
That cannot work: busted runs in Docker (`tools/Dockerfile`) against a
**mocked** `vim` global defined in `specs/tools/spec_helper.lua`, with
`LUA_PATH=lua/?.lua`. It cannot load plugin specs, which call real Neovim
APIs.

That assertion is therefore implemented as a **headless nvim check** in
`tools/baseline.sh` (Task 1) and asserted in Task 14, not as a busted spec.
The busted work in Task 18 covers only pure-Lua helpers, which is what the
harness can actually run.

---

## Phase 0 — Baseline

### Task 1: Build the baseline capture tool

**Files:**

- Create: `config/nvim/tools/baseline.sh`
- Modify: `config/nvim/.gitignore`

- [ ] **Step 1: Confirm the symlink, so headless checks test the repo**

```bash
ls -l ~/.config/nvim
```

Expected: a symlink pointing at `/Users/roalcantara/Work/dots/config/nvim`.
If it is a real directory instead, stop and ask — this plan's verification
is meaningless otherwise.

- [ ] **Step 2: Write the baseline script**

```bash
cat > /Users/roalcantara/Work/dots/config/nvim/tools/baseline.sh <<'EOF'
#!/usr/bin/env bash
# Capture a comparable snapshot of Neovim's observable state.
#
#   tools/baseline.sh capture <label>   # write .tmp/baseline/<label>/
#   tools/baseline.sh diff <a> <b>      # diff two snapshots
#
# Snapshots are plain text and sorted, so `diff` output is meaningful.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${ROOT}/.tmp/baseline"

capture() {
  local label="${1:?usage: baseline.sh capture <label>}"
  local out="${OUT_ROOT}/${label}"
  mkdir -p "$out"

  # 1. Startup errors. Any output here is a failure.
  nvim --headless +q >"${out}/startup-stderr.txt" 2>&1 || true

  # 2. Startup time: median of 3 runs, in ms.
  : >"${out}/startuptime-runs.txt"
  for _ in 1 2 3; do
    local log
    log="$(mktemp)"
    nvim --headless --startuptime "$log" +q >/dev/null 2>&1 || true
    awk 'END { print $1 }' "$log" >>"${out}/startuptime-runs.txt"
    rm -f "$log"
  done
  sort -n "${out}/startuptime-runs.txt" | sed -n '2p' >"${out}/startuptime-median.txt"

  # 3. Keymaps: every mode, sorted "mode<TAB>lhs<TAB>desc".
  nvim --headless -c '
    lua << LUA
      local out = {}
      for _, mode in ipairs({ "n", "i", "v", "x", "o", "s", "t", "c" }) do
        for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
          table.insert(out, table.concat({ mode, m.lhs, m.desc or "" }, "\t"))
        end
      end
      table.sort(out)
      io.write(table.concat(out, "\n"), "\n")
LUA' -c 'qa!' >"${out}/keymaps.tsv" 2>/dev/null || true

  # 4. Autocmds: sorted "group<TAB>event<TAB>pattern".
  nvim --headless -c '
    lua << LUA
      local out = {}
      for _, a in ipairs(vim.api.nvim_get_autocmds({})) do
        table.insert(out, table.concat({ a.group_name or "<none>", a.event, a.pattern or "" }, "\t"))
      end
      table.sort(out)
      io.write(table.concat(out, "\n"), "\n")
LUA' -c 'qa!' >"${out}/autocmds.tsv" 2>/dev/null || true

  # 5. Loaded plugins, sorted.
  nvim --headless -c '
    lua << LUA
      local out = {}
      for _, p in ipairs(require("lazy").plugins()) do
        table.insert(out, p.name)
      end
      table.sort(out)
      io.write(table.concat(out, "\n"), "\n")
LUA' -c 'qa!' >"${out}/plugins.txt" 2>/dev/null || true

  # 6. Eager-load contract: which core/ modules are in package.loaded at
  #    startup. Phase 4 shrinks this list; nothing should ever re-add to it.
  nvim --headless -c '
    lua << LUA
      local out = {}
      for name in pairs(package.loaded) do
        if name:match("^core[/.]") then table.insert(out, name) end
      end
      table.sort(out)
      io.write(table.concat(out, "\n"), "\n")
LUA' -c 'qa!' >"${out}/eager-core-modules.txt" 2>/dev/null || true

  # 7. Health, stripped of timestamps so diffs are stable.
  nvim --headless -c 'checkhealth' -c 'w! '"${out}/checkhealth.txt" -c 'qa!' \
    >/dev/null 2>&1 || true

  echo "captured -> ${out}"
  echo "  startup median: $(cat "${out}/startuptime-median.txt") ms"
  echo "  keymaps:        $(wc -l <"${out}/keymaps.tsv" | tr -d ' ')"
  echo "  autocmds:       $(wc -l <"${out}/autocmds.tsv" | tr -d ' ')"
  echo "  eager core/:    $(wc -l <"${out}/eager-core-modules.txt" | tr -d ' ')"
}

diff_snapshots() {
  local a="${OUT_ROOT}/${1:?usage: baseline.sh diff <a> <b>}"
  local b="${OUT_ROOT}/${2:?usage: baseline.sh diff <a> <b>}"
  local rc=0
  for f in keymaps.tsv autocmds.tsv plugins.txt eager-core-modules.txt; do
    echo "=== $f ==="
    diff -u "${a}/${f}" "${b}/${f}" || rc=1
  done
  echo "=== startuptime median (ms) ==="
  echo "  ${1}: $(cat "${a}/startuptime-median.txt")"
  echo "  ${2}: $(cat "${b}/startuptime-median.txt")"
  return $rc
}

case "${1:-}" in
  capture) shift; capture "$@" ;;
  diff)    shift; diff_snapshots "$@" ;;
  *) echo "usage: baseline.sh {capture <label>|diff <a> <b>}" >&2; exit 2 ;;
esac
EOF
chmod +x /Users/roalcantara/Work/dots/config/nvim/tools/baseline.sh
```

- [ ] **Step 3: Ignore the snapshot directory**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
printf '\n# Baseline snapshots from tools/baseline.sh\n.tmp/\n' >> .gitignore
```

- [ ] **Step 4: Capture the baseline**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture phase0
```

Expected: prints `captured -> …/.tmp/baseline/phase0` plus four counts.
The startup median should be near 181ms. Record the four numbers in your
notes — every later task compares against them.

- [ ] **Step 5: Confirm the baseline captured real data**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
wc -l .tmp/baseline/phase0/*.tsv .tmp/baseline/phase0/*.txt
```

Expected: `keymaps.tsv` and `autocmds.tsv` each have hundreds of lines,
`plugins.txt` has dozens, `eager-core-modules.txt` is non-empty. If any is
zero lines the heredoc-in-`-c` quoting broke — fix before proceeding, since
every later gate depends on it.

- [ ] **Step 6: Check whether startup is currently clean**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
cat .tmp/baseline/phase0/startup-stderr.txt
```

Expected: empty. If it is not empty, record the existing errors — they are
pre-existing and you must not be blamed for them, but you also must not
*add* to them.

- [ ] **Step 7: Establish whether the busted suite currently passes**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
mise exec -- mise run tests 2>&1 | tail -20
```

Record the result. The suite may already be failing — the `tests` task
mounts `lua/` at `/app/src` while `LUA_PATH` is `lua/?.lua`, which looks
inconsistent. **Do not fix it here.** Task 18 depends on knowing the
starting state; if it is red now, Task 18's first step is repairing the
harness.

- [ ] **Step 8: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/tools/baseline.sh config/nvim/.gitignore
mise exec -- git commit -m "chore(nvim): add baseline capture tool for conformance audit"
```

---

## Phase 1 — Active conflicts

### Task 2: C1 — stop conform's format_on_save being silently discarded

LazyVim's conform spec (`lazyvim/plugins/formatting.lua`) explicitly
detects `opts.format_on_save`, warns
`Don't set opts.format_on_save for conform.nvim`, and sets it to `nil`.
The current 500ms timeout therefore never applies. LazyVim's own
autoformat is driven by `vim.g.autoformat` and its timeout by
`default_format_opts.timeout_ms`.

**Files:**

- Modify: `config/nvim/lua/plugins/formater.lua:15-21`
- Modify: `config/nvim/lua/config/options.lua` (append to the
  `GLOBAL GENERAL SETTINGS` block)

- [ ] **Step 1: Observe the warning before changing anything**

```bash
nvim --headless -c 'lua vim.defer_fn(function() vim.cmd("qa!") end, 3000)' \
  -c 'Lazy load conform.nvim' 2>&1 | head -5
```

Expected: a message containing `Don't set` and `format_on_save`. This is
the bug reproducing. If you do not see it, still proceed — the warning may
be swallowed by noice; the code in `lazyvim/plugins/formatting.lua:5-12`
is unambiguous.

- [ ] **Step 2: Replace the options block in formater.lua**

Replace lines 15-21 of `config/nvim/lua/plugins/formater.lua`, which
currently read:

```lua
      opts.default_format_opts = {
        lsp_format = 'fallback',
      }

      opts.format_on_save = {
        timeout_ms = 500,
      }
```

with:

```lua
      -- LazyVim owns format-on-save. Setting `opts.format_on_save` here is
      -- detected and nil'd out by lazyvim/plugins/formatting.lua, so the
      -- timeout has to live in default_format_opts instead, and the on/off
      -- switch is `vim.g.autoformat` (set in config/options.lua).
      opts.default_format_opts = {
        lsp_format = 'fallback',
        timeout_ms = 500,
      }
```

- [ ] **Step 3: Enable LazyVim autoformat explicitly**

Append to `config/nvim/lua/config/options.lua`, in the
`GLOBAL GENERAL SETTINGS` block near `vim.g.deprecation_warnings`:

```lua
vim.g.autoformat = true -- LazyVim's format-on-save switch; replaces conform's opts.format_on_save
```

- [ ] **Step 4: Verify the warning is gone and formatting still runs**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
nvim --headless +q 2>&1 | head
nvim --headless -c 'lua print(vim.g.autoformat)' -c 'qa!' 2>&1 | tail -1
```

Expected: first command prints nothing; second prints `true`.

- [ ] **Step 5: Verify a real format still happens**

```bash
cd /tmp && printf 'local  x   =  1\n' > fmt_probe.lua
nvim --headless fmt_probe.lua -c 'lua vim.defer_fn(function() vim.cmd("wq") end, 2500)' >/dev/null 2>&1
cat fmt_probe.lua && rm -f fmt_probe.lua
```

Expected: `local x = 1` — stylua normalised the spacing. If the spacing is
unchanged, stylua is not installed via Mason; run
`nvim --headless -c 'MasonInstall stylua' -c 'qa'` and retry.

- [ ] **Step 6: Snapshot and diff**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task02
./tools/baseline.sh diff phase0 task02
```

Expected: no keymap, autocmd, plugin or eager-module changes. Startup
median within noise of baseline.

- [ ] **Step 7: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/formater.lua config/nvim/lua/config/options.lua
mise exec -- git commit -m "fix(nvim): use vim.g.autoformat instead of discarded conform format_on_save"
```

---

### Task 3: C2 — let LazyVim's guarded fold and indent expressions apply

`lazyvim/plugins/treesitter.lua:118-133` sets `indentexpr` and
`foldexpr` per-FileType via `LazyVim.set_default`, guarded by
`LazyVim.treesitter.have(ft, query)`. `set_default` only assigns when the
option still holds Neovim's default. Because `options.lua` sets these
globally at startup, the guard never fires and the **unguarded**
expressions win — producing fold and indent errors in buffers with no
parser.

**Files:**

- Modify: `config/nvim/lua/config/options.lua:111-112` and `:122-124`

- [ ] **Step 1: Reproduce the unguarded fold expression**

```bash
cd /tmp && printf 'hello\n' > fold_probe.unknownft
nvim --headless fold_probe.unknownft -c 'lua print("foldexpr=" .. vim.o.foldexpr)' -c 'qa!' 2>&1 | tail -2
```

Expected: `foldexpr=v:lua.vim.treesitter.foldexpr()` — the raw one, with no
`LazyVim` guard. After this task it should be empty or LazyVim's.

- [ ] **Step 2: Delete the indentexpr assignment**

Delete these two lines from `config/nvim/lua/config/options.lua` (lines
111-112):

```lua
vim.opt.indentexpr =
"v:lua.require'nvim-treesitter'.indentexpr()"                      -- Use treesitter for indentation (https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file)
```

- [ ] **Step 3: Delete the foldmethod and foldexpr assignments**

Delete these three lines (originally 122-124, now shifted up by two):

```lua
vim.opt.foldmethod = 'expr'                          -- Use expression for folding
vim.opt.foldexpr =
'v:lua.vim.treesitter.foldexpr()'                    -- Use treesitter for folding (https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#folding)
```

Add in their place a comment recording why they are absent:

```lua
-- foldmethod / foldexpr / indentexpr are deliberately NOT set here.
-- LazyVim sets them per-FileType via LazyVim.set_default, guarded by
-- LazyVim.treesitter.have(ft, query), so buffers with no parser fall back
-- cleanly. Setting them globally defeats that guard.
```

- [ ] **Step 4: Keep the remaining fold options**

Confirm these are still present and untouched — they are preferences, not
conflicts:

```lua
vim.opt.foldcolumn = '0'
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldminlines = 1
vim.opt.foldnestmax = 3
```

- [ ] **Step 5: Verify the guard now applies**

```bash
cd /tmp
nvim --headless fold_probe.unknownft -c 'lua print("foldexpr=[" .. vim.o.foldexpr .. "]")' -c 'qa!' 2>&1 | tail -2
nvim --headless /Users/roalcantara/Work/dots/config/nvim/init.lua \
  -c 'lua print("lua foldexpr=[" .. vim.o.foldexpr .. "]")' -c 'qa!' 2>&1 | tail -2
rm -f fold_probe.unknownft
```

Expected: the parser-less buffer prints `foldexpr=[]`; the Lua buffer
prints `foldexpr=[v:lua.LazyVim.treesitter.foldexpr()]`. That difference is
the whole point of this task.

- [ ] **Step 6: Verify folding still works in a real file**

```bash
nvim --headless /Users/roalcantara/Work/dots/config/nvim/lua/plugins/ui.lua \
  -c 'normal! 100G' -c 'lua print("foldlevel=" .. vim.fn.foldlevel(100))' -c 'qa!' 2>&1 | tail -1
```

Expected: a number greater than 0 — treesitter folds are computing.

- [ ] **Step 7: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task03 && ./tools/baseline.sh diff task02 task03
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/options.lua
mise exec -- git commit -m "fix(nvim): drop global foldexpr/indentexpr so LazyVim's guarded defaults apply"
```

---

### Task 4: C3 — retire the invisible bufferline

`showtabline = 0` hides bufferline entirely, but `<D-M-Left>` and
`<D-M-Right>` still drive `BufferLineCyclePrev`/`Next`. Repoint them at
the builtin commands and disable the plugin, rather than loading a UI
nothing renders.

**Files:**

- Modify: `config/nvim/lua/config/keymaps.lua:151-152`
- Modify: `config/nvim/lua/plugins/ui.lua` (append a new spec)

- [ ] **Step 1: Confirm bufferline is currently loaded but invisible**

```bash
nvim --headless -c 'lua print("showtabline=" .. vim.o.showtabline)' \
  -c 'lua print("bufferline loaded=" .. tostring(package.loaded["bufferline"] ~= nil))' \
  -c 'qa!' 2>&1 | tail -2
```

Expected: `showtabline=0` and a loaded bufferline — wasted work.

- [ ] **Step 2: Repoint the two keymaps**

In `config/nvim/lua/config/keymaps.lua`, replace lines 151-152:

```lua
      ['<D-M-Left>'] = { { n = '<CMD>BufferLineCyclePrev<CR>', i = '<C-O><CMD>BufferLineCyclePrev<CR>', v = '<ESC><CMD>BufferLineCyclePrev<CR>' }, 'Go to Previous Buffer (Left)' },
      ['<D-M-Right>'] = { { n = '<CMD>BufferLineCycleNext<CR>', i = '<C-O><CMD>BufferLineCycleNext<CR>', v = '<ESC><CMD>BufferLineCycleNext<CR>' }, 'Go to Next Buffer (Right)' },
```

with:

```lua
      ['<D-M-Left>'] = { { n = '<CMD>bprevious<CR>', i = '<C-O><CMD>bprevious<CR>', v = '<ESC><CMD>bprevious<CR>' }, 'Go to Previous Buffer (Left)' },
      ['<D-M-Right>'] = { { n = '<CMD>bnext<CR>', i = '<C-O><CMD>bnext<CR>', v = '<ESC><CMD>bnext<CR>' }, 'Go to Next Buffer (Right)' },
```

- [ ] **Step 3: Disable the LazyVim bufferline spec**

Add this entry to the returned table in `config/nvim/lua/plugins/ui.lua`,
immediately after the opening `return {` on line 8:

```lua
  -- Bufferline is disabled: options.lua sets showtabline = 0, so it never
  -- renders, and the two buffer-cycle keymaps now use builtin bprevious/bnext.
  { 'akinsho/bufferline.nvim', enabled = false },

```

- [ ] **Step 4: Verify bufferline is gone and cycling still works**

```bash
nvim --headless -c 'lua print("bufferline in lazy=" .. tostring(require("lazy.core.config").plugins["bufferline.nvim"] ~= nil))' -c 'qa!' 2>&1 | tail -1
nvim --headless -c 'e /tmp/a.txt' -c 'e /tmp/b.txt' -c 'bprevious' \
  -c 'lua print("buf=" .. vim.fn.expand("%:t"))' -c 'qa!' 2>&1 | tail -1
```

Expected: first prints `false`; second prints `buf=a.txt`.

- [ ] **Step 5: Snapshot and diff — read this one carefully**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task04 && ./tools/baseline.sh diff task03 task04
```

Expected in the diff: `plugins.txt` loses `bufferline.nvim`;
`keymaps.tsv` shows the two `<D-M-…>` entries unchanged in `lhs`/`desc`
(the rhs is not captured) and loses LazyVim's bufferline-owned keymaps such
as `<leader>bp` and `<leader>bP`. **If a keymap you use disappears and you
did not expect it, stop** — LazyVim attaches several `<leader>b*` bindings
to the bufferline spec.

- [ ] **Step 6: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/keymaps.lua config/nvim/lua/plugins/ui.lua
mise exec -- git commit -m "refactor(nvim): disable unrendered bufferline and use builtin buffer cycling"
```

---

### Task 5: C4 — remove mini.animate, which loses to snacks_animate = false

`options.lua:196` sets `vim.g.snacks_animate = false`, yet
`plugins/ui.lua:766-824` configures `mini.animate` in full. Per the
resolved decision in the spec, animation stays off and the spec goes.

**Files:**

- Modify: `config/nvim/lua/plugins/ui.lua:766-824`

- [ ] **Step 1: Read the block you are about to delete**

```bash
sed -n '766,824p' /Users/roalcantara/Work/dots/config/nvim/lua/plugins/ui.lua
```

Confirm it starts with the `-- Mini Animate |` comment and ends with the
`},` closing that spec, immediately before the `-- Noice |` comment.

- [ ] **Step 2: Delete the mini.animate spec**

Remove lines 766-824 inclusive — the two leading comment lines and the
whole `{ 'nvim-mini/mini.animate', … },` table. Leave the blank line that
separates it from the Noice spec.

- [ ] **Step 3: Verify**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
grep -c "mini.animate" lua/plugins/ui.lua
nvim --headless +q 2>&1 | head
```

Expected: `0`, then no output.

- [ ] **Step 4: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task05 && ./tools/baseline.sh diff task04 task05
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/ui.lua
mise exec -- git commit -m "refactor(nvim): remove mini.animate, contradicted by snacks_animate = false"
```

Expected diff: `plugins.txt` loses `mini.animate`. Nothing else.

---

### Task 6: C5 — correct the stale statuscolumn comment

`plugins/ui.lua:480` reads
`statuscolumn = { enabled = false }, -- we set this in options.lua`, but
`options.lua` never sets `statuscolumn`. LazyVim's
`opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]` is what runs. The
setting is correct; only the comment lies. This is a comment-only change,
so it is deliberately kept out of the behavioural tasks.

**Files:**

- Modify: `config/nvim/lua/plugins/ui.lua:480`

- [ ] **Step 1: Confirm which statuscolumn is active**

```bash
nvim --headless -c 'lua print("statuscolumn=[" .. vim.o.statuscolumn .. "]")' -c 'qa!' 2>&1 | tail -1
grep -n "statuscolumn" /Users/roalcantara/Work/dots/config/nvim/lua/config/options.lua || echo "not set in options.lua — comment is wrong"
```

Expected: prints LazyVim's `%!v:lua.LazyVim.statuscolumn()`, and the grep
finds nothing.

- [ ] **Step 2: Fix the comment**

Replace line 480 of `config/nvim/lua/plugins/ui.lua`:

```lua
        statuscolumn = { enabled = false }, -- we set this in options.lua
```

with:

```lua
        statuscolumn = { enabled = false }, -- LazyVim sets vim.o.statuscolumn to LazyVim.statuscolumn()
```

- [ ] **Step 3: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/ui.lua
mise exec -- git commit -m "docs(nvim): correct stale statuscolumn comment in snacks opts"
```

---

## Phase 2 — Deduplicate `config/`

### Task 7: Delete the eight autocmd groups LazyVim already registers

These eight groups in `config/nvim/lua/config/autocmds.lua` reimplement
`lazyvim/config/autocmds.lua`. They register in *separate* augroups, so
both fire. **Review each pair before deleting** — the risk here is
semantic drift, not structural duplication.

**Files:**

- Modify: `config/nvim/lua/config/autocmds.lua`

- [ ] **Step 1: Prove the double registration**

```bash
nvim --headless -c '
  lua << LUA
    local n = 0
    for _, a in ipairs(vim.api.nvim_get_autocmds({ event = "BufWritePre" })) do
      if (a.group_name or ""):match("auto_create_dir") then n = n + 1 end
    end
    print("auto_create_dir handlers: " .. n)
LUA' -c 'qa!' 2>&1 | tail -1
```

Expected: `2`. After this task: `1`.

- [ ] **Step 2: Diff each pair before deleting**

For each of the eight groups, open both files side by side and confirm the
callback bodies are equivalent:

```bash
sed -n '1,140p' ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/autocmds.lua
sed -n '13,125p' /Users/roalcantara/Work/dots/config/nvim/lua/config/autocmds.lua
```

Two known differences you are accepting:

- `last_loc` uses the buffer flag `vim.b[buf].neovim_last_loc`; LazyVim
  uses `lazyvim_last_loc`. Behaviour is identical; only the flag name
  differs.
- `wrap_spell` additionally fires
  `Neo.debug('wrap and spell enabled for …')`. That notification is lost.
  This is intended — it is startup noise.

If you find a *third* difference not listed here, stop and report it rather
than deleting.

- [ ] **Step 3: Delete the eight group entries**

From the table passed to `require('core/vi/au').setup_autocommands_async({…})`
in `config/nvim/lua/config/autocmds.lua`, delete these keys and their whole
values: `checktime`, `highlight_yank`, `resize_splits`, `last_loc`,
`man_unlisted`, `wrap_spell`, `json_conceal`, `auto_create_dir`.

Keep: `filetypedetect` (Task 8 decides its fate), `close_with_q_or_esc`
(Task 9 rewrites it), `on_open_term`, `on_lsp_attach`, and
`on_vim_enter_or_color_scheme` (Task 12 removes it with url-open).

Add this comment above the remaining table:

```lua
-- Only autocommands LazyVim does NOT already provide live here.
-- checktime / highlight_yank / resize_splits / last_loc / man_unlisted /
-- wrap_spell / json_conceal / auto_create_dir are all registered by
-- lazyvim/config/autocmds.lua — do not re-add them.
```

- [ ] **Step 4: Verify the duplication is gone**

```bash
nvim --headless -c '
  lua << LUA
    for _, ev in ipairs({ "BufWritePre", "TextYankPost", "VimResized", "BufReadPost" }) do
      print(ev .. ": " .. #vim.api.nvim_get_autocmds({ event = ev }))
    end
LUA' -c 'qa!' 2>&1 | tail -4
```

Record these counts. Each should have dropped by exactly one versus
baseline.

- [ ] **Step 5: Verify the behaviour survived**

```bash
cd /tmp && rm -rf nested_probe
nvim --headless -c 'e /tmp/nested_probe/deep/file.txt' -c 'w' -c 'qa!' >/dev/null 2>&1
ls /tmp/nested_probe/deep/file.txt && rm -rf nested_probe
```

Expected: the file exists — LazyVim's `auto_create_dir` did the work that
the deleted group used to duplicate.

- [ ] **Step 6: Snapshot and diff**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task07 && ./tools/baseline.sh diff task05 task07
```

Expected: `autocmds.tsv` loses exactly the eight duplicated group rows and
gains nothing. This is the load-bearing gate for the whole phase — read it
line by line.

- [ ] **Step 7: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/autocmds.lua
mise exec -- git commit -m "refactor(nvim): drop eight autocmd groups duplicated from LazyVim"
```

---

### Task 8: Decide the .yml filetype autocmd on evidence

The `filetypedetect` group forces `filetype=yaml` for `*.yml`. Neovim's
builtin `filetype.lua` very likely already does this, but an earlier probe
was inconclusive, so **measure before deleting**.

**Files:**

- Modify: `config/nvim/lua/config/autocmds.lua`

- [ ] **Step 1: Test builtin detection with the config disabled**

```bash
printf 'key: value\n' > /tmp/probe.yml
nvim --headless -u NORC --noplugin /tmp/probe.yml \
  -c 'lua print("ft=[" .. vim.bo.filetype .. "]")' -c 'qa!' 2>&1 | tail -1
```

`-u NORC --noplugin` bypasses your config but keeps Neovim's runtime
filetype detection.

- [ ] **Step 2: Branch on the result**

**If it printed `ft=[yaml]`** — the autocmd is redundant. Delete the
`filetypedetect` key and its whole value from
`config/nvim/lua/config/autocmds.lua`.

**If it printed `ft=[]`** — the autocmd is load-bearing. Keep it, and add
this comment above it so nobody deletes it later:

```lua
  -- Neovim's builtin filetype detection does not map *.yml to yaml on this
  -- version (verified with `nvim -u NORC --noplugin`), so we map it here.
```

- [ ] **Step 3: Verify the end state either way**

```bash
nvim --headless /tmp/probe.yml -c 'lua print("ft=[" .. vim.bo.filetype .. "]")' -c 'qa!' 2>&1 | tail -1
rm -f /tmp/probe.yml
```

Expected: `ft=[yaml]`. This must hold whichever branch you took.

- [ ] **Step 4: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task08 && ./tools/baseline.sh diff task07 task08
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/autocmds.lua
mise exec -- git commit -m "refactor(nvim): resolve .yml filetype autocmd against builtin detection"
```

Expected diff: if you deleted `filetypedetect`, `autocmds.tsv` loses its
BufRead/BufNewFile rows and nothing else. If you kept it, no diff at all.

If Step 2 took the "keep it" branch the only change is a comment — that is
still worth committing, because it records the evidence.

---

### Task 9: Rewrite close_with_q_or_esc as an extension, not a rival

This is the one genuine behaviour change in an otherwise-cosmetic area, so
it gets its own task and its own commit. Both your group and LazyVim's
`close_with_q` bind `q` on overlapping filetypes with different bodies:
LazyVim wraps the mapping in `vim.schedule` and sets `silent = true`;
yours does not, and additionally binds `<Esc>`.

**Files:**

- Modify: `config/nvim/lua/config/autocmds.lua`

- [ ] **Step 1: Observe the double binding**

```bash
nvim --headless -c 'help help' -c 'verbose nmap q' -c 'qa!' 2>&1 | tail -8
```

Expected: evidence of a mapping set from your `autocmds.lua`, having
overwritten LazyVim's.

- [ ] **Step 2: Replace the group with an Esc-only extension**

In `config/nvim/lua/config/autocmds.lua`, replace the whole
`close_with_q_or_esc` entry with:

```lua
  -- LazyVim's `lazyvim_close_with_q` group already binds `q` (with
  -- vim.schedule + silent) for its own filetype list. We only add the
  -- filetypes it does not cover, and the extra <Esc> binding.
  close_with_esc = {
    {
      event = 'FileType',
      opts = {
        pattern = {
          'aerial',
          'DressingSelect',
          'floaterm',
          'help',
          'Jaq',
          'lazy',
          'lir',
          'lsp-installer',
          'LspsagaCodeAction',
          'LspsagaDiagnostic',
          'LspsagaFinder',
          'LspsagaFloaterm',
          'LspsagaHover',
          'LspsagaRename',
          'LspsagaSignatureHelp',
          'LspSignatureHelp',
          'man',
          'markdown',
          'noice',
          'null-ls-info',
          'snacks_notif_history',
          'snacks_notif_log',
          'snacks_notif',
          'snacks_picker_list',
          'snacks_win',
          'Trouble',
          'trouble',
          'TroubleToggle',
          'unix',
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.schedule(function()
            for _, lhs in ipairs({ 'q', '<Esc>' }) do
              vim.keymap.set('n', lhs, function()
                vim.cmd('close')
                pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
              end, {
                buffer = event.buf,
                silent = true,
                desc = 'Quit buffer',
              })
            end
          end)
        end,
        desc = 'Close extra filetypes with q or <Esc>',
      },
    },
  },
```

The filetypes LazyVim already covers — `checkhealth`, `dbout`,
`gitsigns-blame`, `grug-far`, `lspinfo`, `neotest-*`, `notify`,
`PlenaryTestPopup`, `qf`, `spectre_panel`, `startuptime`, `tsplayground` —
are removed from the pattern list, because LazyVim binds `q` for them
already. They lose the `<Esc>` binding as a result.

- [ ] **Step 3: Decide whether losing `<Esc>` on those filetypes matters**

```bash
nvim --headless -c 'checkhealth lazy' -c 'verbose nmap <Esc>' -c 'qa!' 2>&1 | tail -5
```

If you want `<Esc>` on LazyVim's filetypes too, add them back to the
pattern list above — the callback is idempotent, so both groups binding `q`
with equivalent bodies is harmless. Note the choice in the commit message.

- [ ] **Step 4: Verify both keys still close a help buffer**

```bash
nvim --headless -c 'help help' -c 'lua vim.schedule(function()
  local ok = pcall(vim.api.nvim_buf_get_keymap, 0, "n")
  local maps = vim.api.nvim_buf_get_keymap(0, "n")
  local found = {}
  for _, m in ipairs(maps) do found[m.lhs] = true end
  print("q=" .. tostring(found["q"] ~= nil) .. " esc=" .. tostring(found["<Esc>"] ~= nil))
  vim.cmd("qa!")
end)' 2>&1 | tail -1
```

Expected: `q=true esc=true`.

- [ ] **Step 5: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task09 && ./tools/baseline.sh diff task08 task09
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/autocmds.lua
mise exec -- git commit -m "refactor(nvim): extend LazyVim close_with_q instead of shadowing it"
```

---

### Task 10: Strip redundant options and annotate the deliberate divergences

Roughly 37 lines in `options.lua` restate LazyVim defaults verbatim, and
12 more are Neovim defaults or no-ops. Deleting a line that restates a
default is safe; deleting a line that *differs* is a behaviour change.
The table below is the authority — do not improvise.

**Files:**

- Modify: `config/nvim/lua/config/options.lua`

- [ ] **Step 1: Delete lines identical to LazyVim defaults**

Delete these assignments. Each sets exactly the value
`lazyvim/config/options.lua` already sets:

```text
completeopt is NOT in this list — see step 3
expandtab, fillchars, foldlevel, grepformat, grepprg, ignorecase,
inccommand, jumpoptions, laststatus, linebreak, list, mouse, pumblend,
relativenumber, shiftround, shiftwidth, shortmess, showmode, sidescrolloff,
signcolumn, smartcase, smartindent, spelllang, splitbelow, splitkeep,
splitright, tabstop, termguicolors, undofile, undolevels, virtualedit,
wildmode, winminwidth, wrap
```

- [ ] **Step 2: Delete Neovim defaults and no-ops**

```text
autoread, backspace, encoding, errorbells, incsearch, lazyredraw,
modifiable, modeline, showmatch, ttyfast, wildmenu, winborder
```

`vim.opt.winborder = nil` in particular does nothing at all — assigning
`nil` to a `vim.opt` entry is not a reset.

- [ ] **Step 3: Annotate the divergences you are keeping**

Add a trailing comment to each of these so a future reader can tell intent
from accident:

```lua
vim.g.maplocalleader = ' '                        -- LazyVim default: '\'
vim.opt.autowrite = false                         -- LazyVim default: true
vim.opt.completeopt = 'menuone,noinsert,noselect' -- LazyVim default: 'menu,menuone,noselect'
vim.opt.conceallevel = 0                          -- LazyVim default: 2
vim.opt.cursorline = false                        -- LazyVim default: true
vim.opt.number = false                            -- LazyVim default: true
vim.opt.pumheight = 50                            -- LazyVim default: 10
vim.opt.scrolloff = 10                            -- LazyVim default: 4
vim.opt.timeoutlen = 500                          -- LazyVim default: 300
vim.opt.updatetime = 300                          -- LazyVim default: 200
```

- [ ] **Step 4: Leave everything else alone**

Options LazyVim does not set at all — `autochdir`, `cmdheight`,
`cmdwinheight`, `colorcolumn`, `background`, `backup`, `diffopt`,
`foldcolumn`, `foldenable`, `foldlevelstart`, `foldminlines`,
`foldnestmax`, `guicursor`, `hlsearch`, `iskeyword`, `listchars`,
`matchtime`, `maxmempattern`, `numberwidth`, `path`, `preserveindent`,
`redrawtime`, `selection`, `showcmdloc`, `showtabline`, `smarttab`,
`softtabstop`, `spell`, `swapfile`, `synmaxcol`, `textwidth`, `ttimeoutlen`,
`undodir`, `wildignorecase`, `winblend`, `writebackup`, `autoindent`,
`concealcursor` — plus the whole `vim.schedule` clipboard block and every
`vim.g.*` provider setting. All stay.

- [ ] **Step 5: Verify no observable option changed**

```bash
nvim --headless -c '
  lua << LUA
    for _, o in ipairs({ "completeopt", "conceallevel", "cursorline", "number",
                         "pumheight", "scrolloff", "timeoutlen", "updatetime",
                         "autowrite", "expandtab", "shiftwidth", "tabstop",
                         "laststatus", "signcolumn", "wrap", "showtabline" }) do
      print(o .. "=" .. tostring(vim.o[o]))
    end
LUA' -c 'qa!' 2>&1 | tail -16
```

Compare every value against the same command run before your edit. **Any
difference is a bug in this task**, not an improvement. If one differs, you
deleted a line that was not actually a duplicate — restore it.

- [ ] **Step 6: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task10 && ./tools/baseline.sh diff task09 task10
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/options.lua
mise exec -- git commit -m "refactor(nvim): remove options duplicating LazyVim and Neovim defaults"
```

Expected diff: nothing at all except startup median, which may drop
slightly.

---

## Phase 3 — Extras and spec hygiene

### Task 11: Adopt the aerial and treesitter-context extras

The local aerial `opts` block (`ui.lua:981-1063`) is a near-verbatim copy
of `lazyvim/plugins/extras/editor/aerial.lua`. Import the extra and keep
only what genuinely differs.

**Files:**

- Modify: `config/nvim/lua/config/lazy.lua:17-23`
- Modify: `config/nvim/lazyvim.json`
- Modify: `config/nvim/lua/plugins/ui.lua:981-1063` and `:335-344`

- [ ] **Step 1: Read the extras you are adopting**

```bash
cat ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/aerial.lua
cat ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/ui/treesitter-context.lua
```

Note which settings the extras already provide. Everything they provide
comes out of your local spec.

- [ ] **Step 2: Import the extras, in the right position**

In `config/nvim/lua/config/lazy.lua`, replace the `spec` table:

```lua
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import your plugins/overrides
    { import = "plugins" },
  },
```

with:

```lua
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- LazyVim extras. These MUST sit between the LazyVim import and the
    -- local `plugins` import, so local overrides merge on top of them.
    { import = "lazyvim.plugins.extras.editor.aerial" },
    { import = "lazyvim.plugins.extras.ui.treesitter-context" },
    -- import your plugins/overrides
    { import = "plugins" },
  },
```

- [ ] **Step 3: Record the extras in lazyvim.json**

Replace the `extras` array in `config/nvim/lazyvim.json`:

```json
  "extras": [
    "lazyvim.plugins.extras.editor.aerial",
    "lazyvim.plugins.extras.ui.treesitter-context"
  ],
```

- [ ] **Step 4: Reduce the local aerial spec to genuine overrides**

Replace the whole block at `ui.lua:981-1063` (from the `-- Aerial |`
comment through its closing `},`) with:

```lua
  -- Aerial | overrides on top of lazyvim.plugins.extras.editor.aerial,
  -- which already provides attach_mode, backends, show_guides, layout,
  -- icons, filter_kind and guides.
  {
    'stevearc/aerial.nvim',
    opts = {
      layout = {
        resize_to_content = false,
      },
    },
  },
```

- [ ] **Step 5: Reduce the local treesitter-context spec**

Replace `ui.lua:335-344` with:

```lua
  -- Treesitter context (sticky header) - required for <leader>ut toggle in
  -- keymaps. Base spec comes from
  -- lazyvim.plugins.extras.ui.treesitter-context.
  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      mode = 'cursor',
      max_lines = 3,
    },
  },
```

- [ ] **Step 6: Verify the merge direction — this is the risky bit**

```bash
nvim --headless -c '
  lua << LUA
    local p = require("lazy.core.config").plugins["aerial.nvim"]
    local opts = require("lazy.core.plugin").values(p, "opts", false)
    print("attach_mode=" .. tostring(opts.attach_mode))
    print("resize_to_content=" .. tostring(opts.layout and opts.layout.resize_to_content))
    print("backends=" .. tostring(opts.backends and #opts.backends))
LUA' -c 'qa!' 2>&1 | tail -3
```

Expected: `attach_mode=global` (from the extra), `resize_to_content=false`
(your override), `backends=4` (from the extra). If `attach_mode` is `nil`
the import order in Step 2 is wrong.

- [ ] **Step 7: Verify treesitter-context still toggles**

```bash
nvim --headless -c 'Lazy load nvim-treesitter-context' \
  -c 'lua print("tsc enabled=" .. tostring(require("treesitter-context").enabled()))' \
  -c 'qa!' 2>&1 | tail -1
```

Expected: prints `true` or `false` without erroring. The `<leader>ut`
toggle in `keymaps.lua:56-63` calls this exact API.

- [ ] **Step 8: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task11 && ./tools/baseline.sh diff task10 task11
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/lazy.lua config/nvim/lazyvim.json config/nvim/lua/plugins/ui.lua
mise exec -- git commit -m "refactor(nvim): adopt aerial and treesitter-context LazyVim extras"
```

Expected diff: `keymaps.tsv` *gains* the extras' keymaps (aerial's
`<leader>cs`, treesitter-context's `<leader>ut`). That is the point — you
are inheriting maintained defaults.

---

### Task 12: Remove url-open, its autocmd, and the gitbrowse keymaps

Per the resolved decision in the spec: builtin `gx` becomes the only
URL-opening path.

**Files:**

- Modify: `config/nvim/lua/plugins/ui.lua:1173-1292`
- Modify: `config/nvim/lua/config/autocmds.lua`
- Modify: `config/nvim/lua/config/keymaps.lua`

- [ ] **Step 1: Confirm builtin gx exists before removing its replacement**

```bash
nvim --headless -c 'lua local m = vim.fn.maparg("gx", "n", false, true); print("gx desc=" .. tostring(m.desc))' -c 'qa!' 2>&1 | tail -1
```

Expected: a non-nil description. Neovim 0.10+ ships `gx`. If this prints
`nil`, **stop** — do not remove url-open until you know what replaces it.

- [ ] **Step 2: Delete the url-open spec**

Remove lines 1173-1292 of `config/nvim/lua/plugins/ui.lua` — the two
leading comment lines through the closing `},` of the
`{ 'sontungexpt/url-open', … }` table.

- [ ] **Step 3: Delete the autocmd that only served it**

Remove the entire `on_vim_enter_or_color_scheme` entry from
`config/nvim/lua/config/autocmds.lua`. It exists solely to define the
`UrlOpenHighlight` highlight group, which now has no consumer.

- [ ] **Step 4: Remove LazyVim's gitbrowse keymaps**

LazyVim sets `<leader>gB` and `<leader>gY` in
`lazyvim/config/keymaps.lua:177-179`, which loads *before*
`config/keymaps.lua`. Append to
`config/nvim/lua/config/keymaps.lua`, immediately before the final
`require('config/usercmds')` line:

```lua
-- Remove LazyVim's Snacks.gitbrowse keymaps. Builtin `gx` is the only
-- URL-opening path in this config; see the conformance audit design doc.
for _, lhs in ipairs({ '<leader>gB', '<leader>gY' }) do
  for _, mode in ipairs({ 'n', 'x' }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end
```

- [ ] **Step 5: Verify**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
grep -c "url-open\|UrlOpenHighlight\|on_vim_enter_or_color_scheme" \
  lua/plugins/ui.lua lua/config/autocmds.lua
nvim --headless -c 'lua print("gB=" .. tostring(vim.fn.maparg("<leader>gB", "n") ~= ""))' -c 'qa!' 2>&1 | tail -1
nvim --headless +q 2>&1 | head
```

Expected: all grep counts `0`; `gB=false`; no startup output.

- [ ] **Step 6: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task12 && ./tools/baseline.sh diff task11 task12
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/ui.lua config/nvim/lua/config/autocmds.lua config/nvim/lua/config/keymaps.lua
mise exec -- git commit -m "refactor(nvim): remove url-open and gitbrowse keymaps in favour of builtin gx"
```

Expected diff: `plugins.txt` loses `url-open`; `keymaps.tsv` loses
`<D-LeftMouse>`, `<leader>gB`, `<leader>gY`; `autocmds.tsv` loses the
VimEnter/ColorScheme rows.

---

### Task 13: Remove dead and redundant plugin declarations

**Files:**

- Modify: `config/nvim/lua/plugins/coding.lua:6-11`
- Modify: `config/nvim/lua/plugins/ui.lua` (aerial deps, helpview, lualine)
- Modify: `config/nvim/lua/plugins/markdown.lua`

- [ ] **Step 1: Prove fzf-lua never wins the picker registration**

```bash
nvim --headless -c 'lua print("picker=" .. tostring(LazyVim.pick.picker and LazyVim.pick.picker.name))' -c 'qa!' 2>&1 | tail -1
```

Expected: `picker=snacks`. fzf-lua loads on `VeryLazy` but never registers,
so it is pure cost.

- [ ] **Step 2: Remove fzf-lua**

Delete lines 6-11 of `config/nvim/lua/plugins/coding.lua`:

```lua
  -- Fzf-Lua | Improved fzf.vim written in lua
  -- https://github.com/ibhagwan/fzf-lua | https://lazyvim.org/extras/editor/fzf
  {
    'ibhagwan/fzf-lua',
    event = 'VeryLazy',
    cmd = 'FzfLua',
    dependencies = { 'nvim-mini/mini.icons' },
  },
```

- [ ] **Step 3: Drop the fzf-lua dependency from live-preview**

In `config/nvim/lua/plugins/markdown.lua`, change the `live-preview.nvim`
dependencies from:

```lua
    dependencies = {
      'ibhagwan/fzf-lua',
      'folke/snacks.nvim',
    },
```

to:

```lua
    dependencies = {
      'folke/snacks.nvim',
    },
```

- [ ] **Step 4: Consolidate the duplicate render-markdown declaration**

`render-markdown.nvim` is declared in both `markdown.lua:33-43` and
`ui.lua:1157-1171`. Delete the `ui.lua` copy entirely, and merge its two
settings into the `markdown.lua` one so it reads:

```lua
  {
    -- Improve viewing Markdown files
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    --- @module 'render-markdown'
    --- @type render.md.UserConfig
    opts = {
      render_modes = { 'n', 'c', 't' },
      latex = { enabled = false },
      completions = {
        blink = { enabled = true },
        lsp = { enabled = true },
      },
    },
  },
```

- [ ] **Step 5: Drop the nvim-web-devicons dependency**

The aerial spec you wrote in Task 11 no longer declares dependencies, so
`nvim-tree/nvim-web-devicons` should already be gone. Confirm:

```bash
grep -n "nvim-web-devicons" /Users/roalcantara/Work/dots/config/nvim/lua/plugins/*.lua
```

Expected: no output. If it appears elsewhere, remove it — this config uses
`mini.icons`, and LazyVim provides a devicons compatibility shim.

- [ ] **Step 6: Drop the explicit nui.nvim dependency**

In the noice spec in `config/nvim/lua/plugins/ui.lua`, remove the
`dependencies = { 'MunifTanjim/nui.nvim' }` entry. LazyVim's own noice spec
already declares it.

- [ ] **Step 7: Make helpview lazy**

Change the helpview spec (originally `ui.lua:349-353`) from:

```lua
    'OXY2DEV/helpview.nvim',
    lazy = false,
    opts = {},
```

to:

```lua
    'OXY2DEV/helpview.nvim',
    ft = 'help',
    opts = {},
```

- [ ] **Step 8: Fix the lualine neo-tree extension**

In the lualine spec, change:

```lua
        extensions = { 'neo-tree', 'lazy', 'fzf' },
```

to:

```lua
        extensions = { 'lazy' },
```

`neo-tree` is not installed (this config uses `snacks.explorer`) and
`fzf` was removed in Step 2.

- [ ] **Step 9: Verify**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
grep -c "fzf-lua\|nvim-web-devicons\|neo-tree" lua/plugins/*.lua
grep -c "render-markdown" lua/plugins/ui.lua lua/plugins/markdown.lua
nvim --headless +q 2>&1 | head
nvim --headless -c 'e /tmp/probe.md' -c 'lua print("rm loaded=" .. tostring(package.loaded["render-markdown"] ~= nil))' -c 'qa!' 2>&1 | tail -1
```

Expected: zeros for the removed names; `render-markdown` appears `0` times
in `ui.lua` and once in `markdown.lua`; no startup output; the markdown
probe reports the plugin loading.

- [ ] **Step 10: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task13 && ./tools/baseline.sh diff task12 task13
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/coding.lua config/nvim/lua/plugins/markdown.lua config/nvim/lua/plugins/ui.lua
mise exec -- git commit -m "refactor(nvim): drop dead fzf-lua, devicons and duplicate render-markdown specs"
```

Expected: `plugins.txt` loses `fzf-lua` and `nvim-web-devicons`; startup
median drops.

---

## Phase 4 — Startup

### Task 14: Defer the eager core/ requires

Three spec files call `require('core/…')` at the top level, which runs
during lazy.nvim's spec collection — before any plugin loads. Together
these cost ~38ms. Moving them inside the `opts`/`config`/command callbacks
that use them defers the cost to when the plugin actually loads.

**Files:**

- Modify: `config/nvim/lua/plugins/ui.lua:1-6`
- Modify: `config/nvim/lua/config/options.lua:1-3`
- Modify: `config/nvim/lua/config/usercmds.lua:1-3`

- [ ] **Step 1: Record what is eagerly loaded now**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
cat .tmp/baseline/task13/eager-core-modules.txt
```

Note the count. This is the number Task 14 must reduce.

- [ ] **Step 2: Defer the requires in ui.lua**

Delete lines 1-6 of `config/nvim/lua/plugins/ui.lua`:

```lua
local icons = require('core/ui/icons/icons_list')
local paths = require('core/vi/paths')
local statusline = require('core/ui/statusline')
local snacks_default_exclusions = require('core/ui/snacks/defaults').default_exclusions
local snacks_dashboard = require('core/ui/snacks/dashboard')
```

Then, inside **each** `opts`/`config` function in that file that referenced
one of those locals, add the corresponding `require` as its first line. For
example, the lualine spec's `opts` function begins:

```lua
    opts = function(_, opts)
      local statusline = require('core/ui/statusline')
```

and the snacks spec's `opts` function begins:

```lua
    opts = function(_, opts)
      local paths = require('core/vi/paths')
      local snacks_default_exclusions = require('core/ui/snacks/defaults').default_exclusions
      local snacks_dashboard = require('core/ui/snacks/dashboard')
```

Work through the file mechanically: for each of the five names, find every
use and make sure the enclosing function requires it locally.

- [ ] **Step 3: Find any use you missed**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
nvim --headless -c 'luafile lua/plugins/ui.lua' -c 'qa!' 2>&1 | head
```

Expected: no output. An error naming a nil global — `attempt to index a nil
value (global 'statusline')` — points at exactly the function you missed.

- [ ] **Step 4: Defer the require in options.lua**

`options.lua:1-3` currently reads:

```lua
_G.Neo = require('core/neo')

local paths = require('core/vi/paths')
```

`paths` is used at line 152 (`undodir`) and 184 (`python3_host_prog`), both
of which must run at startup, so that require stays. `_G.Neo` is only used
by autocmd callbacks and plugin code that runs later. Replace the `_G.Neo`
assignment with a lazy proxy:

```lua
-- `Neo` is a convenience global used from autocmd and plugin callbacks.
-- Resolve it on first access rather than at startup: eagerly requiring
-- core/neo here costs ~12ms before any plugin loads.
_G.Neo = setmetatable({}, {
  __index = function(_, key)
    local neo = require('core/neo')
    _G.Neo = neo
    return neo[key]
  end,
})

local paths = require('core/vi/paths')
```

- [ ] **Step 5: Defer the requires in usercmds.lua**

`usercmds.lua:1-3` eagerly loads the snacks pickers (~10ms) purely to build
command callbacks. Replace lines 1-3:

```lua
local noice_helper = require('core/ui/noice')
local git_helpers = require('core/ui/git/commits')
local snacks_pickers = require('core/ui/snacks/pickers')
```

with lazy thunks:

```lua
-- Resolve helpers on first invocation, not at startup. Eagerly requiring
-- core/ui/snacks/pickers here costs ~10ms during spec collection.
local function git_helpers()
  return require('core/ui/git/commits')
end

local function snacks_pickers()
  return require('core/ui/snacks/pickers')
end
```

Then change every `command = …` value from a direct reference to a wrapper.
For example:

```lua
  GenerateGitCommit = {
    command = function(...)
      return git_helpers().generate_conventional_commit(...)
    end,
```

and:

```lua
  History = {
    command = function(...)
      return snacks_pickers().show_history.pick(...)
    end,
```

Apply the same shape to all nine commands. Note that `noice_helper` was
imported but never used — delete it rather than wrapping it.

- [ ] **Step 6: Verify every user command still resolves**

```bash
nvim --headless -c '
  lua << LUA
    vim.defer_fn(function()
      for _, name in ipairs({ "GenerateGitCommit", "History", "TotalHistory",
                              "HistoryCommands", "TotalHistoryCommands",
                              "HistorySearches", "TotalHistorySearch",
                              "HistoryMessages", "TotalHistoryMessages" }) do
        local exists = vim.fn.exists(":" .. name) == 2
        print(name .. "=" .. tostring(exists))
      end
      vim.cmd("qa!")
    end, 1500)
LUA' 2>&1 | tail -9
```

Expected: all nine print `true`.

- [ ] **Step 7: Verify the Neo proxy resolves**

```bash
nvim --headless -c 'lua print("Neo.debug=" .. type(Neo.debug))' -c 'qa!' 2>&1 | tail -1
```

Expected: `Neo.debug=function`.

- [ ] **Step 8: Measure the win**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task14
./tools/baseline.sh diff task13 task14
```

Expected: `eager-core-modules.txt` shrinks substantially — `core/ui/statusline`,
`core/ui/snacks/pickers` and `core/neo` should all be gone. Startup median
should drop by roughly 30-38ms. `keymaps.tsv`, `autocmds.tsv` and
`plugins.txt` must be **unchanged** — this task changes when code loads,
never what it does.

- [ ] **Step 9: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/ui.lua config/nvim/lua/config/options.lua config/nvim/lua/config/usercmds.lua
mise exec -- git commit -m "perf(nvim): defer eager core/ requires out of spec collection"
```

---

### Task 15: Stop showkeys and ghostty loading at startup

**Files:**

- Modify: `config/nvim/lua/plugins/ui.lua` (showkeys spec)
- Modify: `config/nvim/lua/plugins/coding.lua` (ghostty spec)

- [ ] **Step 1: Confirm showkeys loads at startup today**

```bash
nvim --headless -c 'lua print("showkeys loaded=" .. tostring(package.loaded["showkeys"] ~= nil))' -c 'qa!' 2>&1 | tail -1
```

Expected: `true`. The `init` hook calls `ShowkeysToggle`, and lazy.nvim's
command stub for `cmd = 'ShowkeysToggle'` immediately force-loads the
plugin — defeating both `cmd` and `event = 'VeryLazy'`.

- [ ] **Step 2: Remove the auto-toggle and the redundant event**

In the showkeys spec, replace:

```lua
    'nvzone/showkeys',
    cmd = 'ShowkeysToggle',
    event = 'VeryLazy',
    -- Called during startup, plugins' configurations typically is set in an init function
    init = function()
      vim.cmd('ShowkeysToggle')
    end,
```

with:

```lua
    'nvzone/showkeys',
    -- Load only when explicitly toggled. An `init` hook calling
    -- ShowkeysToggle force-loads the plugin at startup via lazy.nvim's
    -- command stub, defeating this `cmd` entirely.
    cmd = 'ShowkeysToggle',
```

- [ ] **Step 3: Make ghostty's cond lazy**

In `config/nvim/lua/plugins/coding.lua`, change:

```lua
    cond = vim.fn.executable('ghostty') == 1,
```

to:

```lua
    cond = function()
      return vim.fn.executable('ghostty') == 1
    end,
```

The table form runs `executable()` during spec collection; the function
form defers it until lazy.nvim evaluates the condition.

- [ ] **Step 4: Verify showkeys no longer loads, but still works**

```bash
nvim --headless -c 'lua print("at startup=" .. tostring(package.loaded["showkeys"] ~= nil))' -c 'qa!' 2>&1 | tail -1
nvim --headless -c 'ShowkeysToggle' -c 'lua print("after toggle=" .. tostring(package.loaded["showkeys"] ~= nil))' -c 'qa!' 2>&1 | tail -1
```

Expected: `at startup=false`, then `after toggle=true`.

**Behaviour change worth noting:** showkeys no longer appears
automatically when you open Neovim. Run `:ShowkeysToggle` when you want it.
If you want it on by default, that costs the 4.5ms back — say so and this
step gets reverted.

- [ ] **Step 5: Snapshot, diff, commit**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task15 && ./tools/baseline.sh diff task14 task15
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/ui.lua config/nvim/lua/plugins/coding.lua
mise exec -- git commit -m "perf(nvim): stop showkeys force-loading at startup and defer ghostty cond"
```

---

## Phase 5 — Lua quality and specs

### Task 16: Clean up keymaps.lua

**Files:**

- Modify: `config/nvim/lua/config/keymaps.lua:1-38` and `:40,214`

- [ ] **Step 1: Delete the commented-out Kickstart leftovers**

Delete lines 1-38 of `config/nvim/lua/config/keymaps.lua` — the entire
block of `-- --` commented Kickstart keymaps, from
`-- -- [[ Basic Keymaps ]]` through the `-- -- vim.keymap.set("n", "<C-S-k>"…`
line. Every one of these is either provided by LazyVim or superseded by the
`<D-*>` map table below them.

- [ ] **Step 2: Replace schedule_wrap with schedule**

`vim.schedule_wrap(fn)` returns a wrapper that schedules `fn` when
*called*; the code then immediately calls it. `vim.schedule(fn)` expresses
the same intent directly. Change line 40 from:

```lua
vim.schedule_wrap(function()
```

to:

```lua
vim.schedule(function()
```

and change the closing line 214 from:

```lua
end)()
```

to:

```lua
end)
```

- [ ] **Step 3: Verify the keymaps are unchanged**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture task16
./tools/baseline.sh diff task15 task16
```

Expected: `keymaps.tsv` **identical**. This is the whole test — if a single
keymap moved, the scheduling change altered timing and must be reverted.

- [ ] **Step 4: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/config/keymaps.lua
mise exec -- git commit -m "refactor(nvim): simplify keymap scheduling and drop Kickstart leftovers"
```

---

### Task 17: Audit the Mason ensure_installed names

`plugins/lsp.lua:8-41` mixes `lspconfig` server names with Mason package
names. Mason's `ensure_installed` wants **package** names. This task is an
audit: if the names are already right, it is a no-op and you say so.

**Files:**

- Modify: `config/nvim/lua/plugins/lsp.lua:8-41` and `:124-139`

- [ ] **Step 1: Get the authoritative package list**

```bash
nvim --headless -c '
  lua << LUA
    local ok, reg = pcall(require, "mason-registry")
    if not ok then print("mason-registry unavailable"); return end
    local want = { "pyrefly", "kotlin_lsp", "postgres_lsp", "nxls",
                   "gradle_ls", "groovyls", "marksman", "ruby_lsp",
                   "rust-analyzer", "gopls", "biome", "elixirls", "eslint",
                   "kcl", "ruff", "gofumpt", "golines", "gomodifytags",
                   "gotests", "black", "isort", "rustfmt" }
    for _, name in ipairs(want) do
      print(name .. " => " .. tostring(reg.has_package(name)))
    end
LUA' -c 'qa!' 2>&1 | tail -25
```

- [ ] **Step 2: Fix only the names that came back false**

For each `false`, find the real package name:

```bash
nvim --headless -c 'lua for _, p in ipairs(require("mason-registry").get_all_package_names()) do if p:match("kotlin") or p:match("postgres") or p:match("gradle") or p:match("groovy") then print(p) end end' -c 'qa!' 2>&1 | tail -10
```

Replace each wrong entry in the `tools` table at `lsp.lua:8-41` with the
name Mason actually knows. If every name came back `true`, change nothing
and record that in the commit message.

- [ ] **Step 3: Check the pkl-lsp server key**

```bash
nvim --headless -c 'lua print("pkl-lsp valid=" .. tostring(pcall(require, "lspconfig.configs.pkl-lsp")))' -c 'qa!' 2>&1 | tail -1
ls ~/.local/share/nvim/lazy/nvim-lspconfig/lsp/ | grep -i pkl || echo "no pkl server in lspconfig"
```

`opts.servers` keys must be valid `lspconfig` server names. If `pkl-lsp` is
not one, either correct it to the real name the `ls` printed, or remove it
from the `other_servers` list at `lsp.lua:124-139`.

- [ ] **Step 4: Verify no LSP errors on startup**

```bash
nvim --headless +q 2>&1 | head
nvim --headless /Users/roalcantara/Work/dots/config/nvim/init.lua -c '
  lua vim.defer_fn(function()
    print("clients=" .. #vim.lsp.get_clients({ bufnr = 0 }))
    vim.cmd("qa!")
  end, 4000)' 2>&1 | tail -2
```

Expected: no output from the first; `clients=1` or more from the second
(lua_ls attached).

- [ ] **Step 5: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/lua/plugins/lsp.lua
mise exec -- git commit -m "fix(nvim): correct Mason package and lspconfig server names"
```

If nothing changed, skip the commit and report "Mason names already
correct — no change needed."

---

### Task 18: Extend the busted suite over the touched helpers

The busted harness runs in Docker against a **mocked** `vim` global
(`specs/tools/spec_helper.lua`). It can only test pure-Lua helpers. Do not
try to test plugin specs here — that is what `tools/baseline.sh` is for.

**Files:**

- Create: `config/nvim/specs/core/vi/paths_has_spec.lua`

- [ ] **Step 1: Repair the harness if Task 1 Step 7 found it red**

If `mise run tests` failed at baseline, fix it before adding tests. The
likely cause is the mount/`LUA_PATH` mismatch: `mise.toml`'s `tests` task
mounts `lua/` at `/app/src`, but `LUA_PATH` is `lua/?.lua`. Change the
mount in `config/nvim/mise.toml` from:

```text
-v $(pwd)/lua:/app/src
```

to:

```text
-v $(pwd)/lua:/app/lua
```

so it matches `LUA_PATH`. Then re-run and confirm green before continuing.

- [ ] **Step 2: Read the function under test**

```bash
grep -n "function M.has" -A 12 /Users/roalcantara/Work/dots/config/nvim/lua/core/vi/paths.lua
```

`paths.has` is called from `plugins/lsp.lua` to gate Mason installs, so it
is load-bearing for Task 17.

- [ ] **Step 3: Write the failing spec**

```bash
cat > /Users/roalcantara/Work/dots/config/nvim/specs/core/vi/paths_has_spec.lua <<'EOF'
--- @diagnostic disable: duplicate-set-field, need-check-nil

local paths = require('core/vi/paths')

describe('#core.vi.paths', function()
  describe('has()', function()
    it('returns a callable for a known executable', function()
      local probe = paths.has('git')
      assert.are.equal('function', type(probe))
    end)

    it('reports true for an executable the mock knows about', function()
      -- spec_helper mocks vim.fn.executable to return 1 only for 'git'
      assert.is_true(paths.has('git')())
    end)

    it('reports false for an unknown executable', function()
      assert.is_false(paths.has('definitely-not-installed')())
    end)
  end)
end)
EOF
```

- [ ] **Step 4: Run it and read the failure**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
mise exec -- mise run tests 2>&1 | tail -30
```

If `has` returns a boolean rather than a function, or takes different
arguments, the assertions above will fail with a clear message. **Rewrite
the spec to match the real signature you read in Step 2** — the spec
describes actual behaviour, it does not dictate it. Do not change
`paths.lua` to satisfy a guess.

- [ ] **Step 5: Get to green**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
mise exec -- mise run tests 2>&1 | tail -10
```

Expected: all specs pass, including the pre-existing ones.

- [ ] **Step 6: Commit**

```bash
cd /Users/roalcantara/Work/dots
git add config/nvim/specs/core/vi/paths_has_spec.lua config/nvim/mise.toml
mise exec -- git commit -m "test(nvim): cover core/vi/paths.has used by Mason gating"
```

---

### Task 19: Final verification against the Phase 0 baseline

**Files:** none modified.

- [ ] **Step 1: Capture the final snapshot**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
./tools/baseline.sh capture final
./tools/baseline.sh diff phase0 final
```

- [ ] **Step 2: Check each expected change is present**

Walk the diff and confirm every difference is one this plan intended:

- `plugins.txt` lost: `bufferline.nvim`, `mini.animate`, `fzf-lua`,
  `url-open`, `nvim-web-devicons`
- `plugins.txt` gained: whatever the two extras pull in
- `keymaps.tsv` lost: `<leader>gB`, `<leader>gY`, `<D-LeftMouse>`,
  LazyVim's bufferline `<leader>b*` bindings
- `keymaps.tsv` gained: the extras' bindings
- `autocmds.tsv` lost: eight duplicated groups, the VimEnter/ColorScheme
  group, and possibly `filetypedetect`
- `eager-core-modules.txt`: substantially shorter
- startup median: materially below 181ms

**Any difference you cannot attribute to a task in this plan is a
regression.** Track it down before declaring done.

- [ ] **Step 3: Confirm a clean startup and health**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
cat .tmp/baseline/final/startup-stderr.txt
diff .tmp/baseline/phase0/checkhealth.txt .tmp/baseline/final/checkhealth.txt | head -40
```

Expected: `startup-stderr.txt` empty (or containing only the pre-existing
errors recorded in Task 1 Step 6). The checkhealth diff should show removed
plugins disappearing and nothing newly broken.

- [ ] **Step 4: Confirm the tests still pass**

```bash
cd /Users/roalcantara/Work/dots/config/nvim
mise exec -- mise run tests 2>&1 | tail -10
```

- [ ] **Step 5: Report honestly**

Write a short summary covering: the startup before and after, which
phases landed, anything you could not do and why, and any behaviour change
the user will notice — at minimum, showkeys no longer auto-starting, the
`<Esc>`-to-close filetypes that changed in Task 11, and the removal of
`<leader>gB`/`<leader>gY`.

State plainly if the <50ms target was not reached. The spec says the phase
succeeds if the eager-require cost is eliminated, not if 50ms is hit — do
not present a 140ms result as if it met the target.

- [ ] **Step 6: Open the branch for review**

```bash
cd /Users/roalcantara/Work/dots
git log --oneline main..HEAD
git status --short config/nvim
```

Expected: eighteen or so commits, a clean working tree.
