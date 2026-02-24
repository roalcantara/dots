# Helix configuration

Helix config and keymaps aligned with **VS Code**, **Cursor**, **Zed**, and **Neovim** so that the same shortcuts behave similarly across all of them (macOS Cmd-centric).

---

## Premise

The goal is to keep the editing experience **as similar as possible** across:

- **VS Code** — e.g. Cmd+Shift+P → Command Palette
- **Cursor**
- **Zed**
- **Neovim** — custom keymaps in `config/nvim/lua/config/keymaps.lua` (via `core/vi/maps`)
- **Helix** — this config

So that one set of muscle memory (especially Cmd+Shift+P for commands, Cmd+c/v/x/s/z/y, Cmd+p/f/b, and LSP shortcuts) works in every editor.

**Exception:** Multi-cursor behaviour is kept as in Helix/VS Code; the plan is to adapt Neovim to match that style, not the other way around.

---

## Mapping Neovim (and others) to Helix

Helix’s official docs do **not** provide a ready-made Neovim→Helix table, but they **do** help you map existing Neovim mappings to Helix: use the [Keymap](https://docs.helix-editor.com/keymap.html) and [Commands](https://docs.helix-editor.com/commands.html) pages to find the Helix command for each Neovim action, and the [Key remapping](https://docs.helix-editor.com/remapping.html) page for binding syntax (modifiers, literal keys, special key names). The [Command line](https://docs.helix-editor.com/command-line.html) page helps when binding to commands with arguments or expansions (e.g. copy file path).

**This README** is the resulting mapping: the tables below (“Configured shortcuts” and “Keymap alignment (reference)”) are the Neovim/VS Code ↔ Helix mapping we built using those docs.

---

## Configured shortcuts

All of the following are defined in `config.toml` under `[keys.normal]`, and most also in `[keys.select]` and `[keys.insert]` where applicable.

### Command palette & search

| Shortcut       | Action           | Helix command / note        |
|----------------|------------------|-----------------------------|
| **Cmd+Shift+P**| Command palette  | `command_palette`          |
| **Cmd+P**      | File picker      | `file_picker`              |
| **Cmd+F**      | Find in file     | `search`                   |
| **Cmd+Shift+F**| Search in files  | `global_search`            |
| **Cmd+B**      | Buffer picker    | `buffer_picker`            |
| **Cmd+\\**     | File explorer    | `file_explorer`           |

### Editor basics

| Shortcut        | Action        | Helix command / note                    |
|-----------------|---------------|----------------------------------------|
| **Cmd+A**       | Select all    | `select_all`                           |
| **Cmd+C**       | Copy          | `:clipboard-yank` (selection → clipboard) |
| **Cmd+V**       | Paste         | `:clipboard-paste-replace`             |
| **Cmd+X**       | Cut           | delete selection, then `:clipboard-yank` (select something first) |
| **Cmd+S**       | Save          | `:write`                               |
| **Cmd+Shift+S** | Save all      | `:write-all`                           |
| **Cmd+N**       | New file      | `:new`                                 |
| **Cmd+Z**       | Undo          | `undo`                                 |
| **Cmd+Y**       | Redo          | `redo`                                 |
| **Cmd+Q**       | Quit          | `:quit`                                |
| **Cmd+Shift+Q** | Force quit   | `:quit!`                               |
| **Cmd+Alt+Q**   | Quit all      | `:quit-all`                            |
| **Cmd+Shift+Alt+Q** | Force quit all | `:quit-all!`                      |

### Movement

| Shortcut     | Action           | Helix command        |
|--------------|------------------|----------------------|
| **Ctrl+A**   | Start of line     | `goto_line_start`    |
| **Ctrl+E**   | End of line       | `goto_line_end`      |
| **Cmd+Up**   | Start of file     | `goto_file_start`    |
| **Cmd+Down** | End of file       | `goto_line`          |
| **Cmd+Left** | Start of line     | `goto_line_start`    |
| **Cmd+Right**| End of line       | `goto_line_end`      |

### Buffers & windows

| Shortcut              | Action           | Helix command / note     |
|-----------------------|------------------|--------------------------|
| **Cmd+Alt+Left**      | Previous buffer  | `goto_previous_buffer`   |
| **Cmd+Alt+Right**     | Next buffer      | `goto_next_buffer`       |
| **Cmd+W**             | Close buffer     | `:buffer-close`         |
| **Cmd+Alt+W**         | Close all buffers| `:buffer-close-all`     |
| **Cmd+Shift+W**       | Close others     | `:buffer-close-others`  |
| **Cmd+Ctrl+Shift+arrows** | Move window  | `swap_view_left/right/up/down` |

### LSP & symbols

| Shortcut       | Action             | Helix command                 |
|----------------|--------------------|------------------------------|
| **Cmd+.**      | Code actions       | `code_action`                 |
| **Cmd+Alt+K**  | Hover              | `hover`                      |
| **Cmd+Alt+F**  | Format document    | `:format`                    |
| **Cmd+Enter** | Rename symbol      | `rename_symbol`              |
| **Cmd+D**      | Diagnostics (doc)   | `diagnostics_picker`         |
| **Cmd+Shift+D**| Diagnostics (ws)   | `workspace_diagnostics_picker` |
| **Cmd+R**      | Document symbols   | `symbol_picker`              |
| **Cmd+Shift+R**| Workspace symbols  | `workspace_symbol_picker`    |
| **Cmd+I**      | Go to definition   | `goto_definition`            |
| **Cmd+Shift+I**| Type definitions   | `goto_type_definition`       |
| **Cmd+Alt+I**  | Implementation     | `goto_implementation`       |
| **Cmd+Alt+R**  | References         | `goto_reference`            |
| **Cmd+Alt+D**  | Declaration        | `goto_declaration`           |

### Other

| Shortcut   | Action          | Helix command     |
|------------|-----------------|-------------------|
| **Cmd+/**  | Toggle comments | `toggle_comments` |

---

## Keymap alignment (reference)

How Neovim/VS Code-style shortcuts map to Helix and what is supported.

### Command palette — Cmd+Shift+P

| App     | Shortcut     | Action          |
|---------|--------------|-----------------|
| VS Code | Cmd+Shift+P  | Command palette |
| Neovim  | Cmd+Shift+P  | Command palette |
| Helix   | **Configured** | `command_palette` (default was Space+?) |

✅ Fully supported.

### Editor basics

| Neovim shortcut | Action        | Helix equivalent                    | Status |
|-----------------|---------------|-------------------------------------|--------|
| Cmd+a           | Select all    | `select_all`                        | ✅     |
| Cmd+c           | Copy          | `:clipboard-yank`                   | ✅     |
| Cmd+v           | Paste         | `:clipboard-paste-replace`          | ✅     |
| Cmd+x           | Cut           | delete + `:clipboard-yank`          | ⚠️ Partial (select first) |
| Cmd+z / Cmd+y   | Undo / Redo   | `undo` / `redo`                     | ✅     |
| Cmd+s / Cmd+Shift+s | Save / Save all | `:write` / `:write-all`      | ✅     |
| Cmd+n           | New file      | `:new`                              | ✅     |
| Cmd+q … Cmd+Shift+Alt+q | Quit variants | `:quit` … `:quit-all!` | ✅     |

**Copy:** In Helix you select then yank to clipboard; Cmd+c is bound to `:clipboard-yank` for the current selection.  
**Cut:** Cmd+x runs delete selection then clipboard yank; have a selection (e.g. line with `x`, word with `w`) first.

### Moving around

| Neovim shortcut | Action       | Helix equivalent        | Status |
|-----------------|--------------|-------------------------|--------|
| Ctrl+a / Ctrl+e | BoL / EoL    | `goto_line_start` / `goto_line_end` | ✅ |
| Cmd+Up/Down     | BoF / EoF    | `goto_file_start` / `goto_line`      | ✅ |
| Cmd+Left/Right  | BoL / EoL    | `goto_line_start` / `goto_line_end`  | ✅ |
| Alt+Up/Down     | Move line    | No direct command       | ⚠️ Partial |

### Selection (Shift / Cmd+Shift / Alt+Shift + arrows)

Selection and extend commands map cleanly in Helix (e.g. `extend_line_below`, `extend_to_line_start`, `extend_to_file_start`). Bindings can be added in `[keys.normal]` and `[keys.select]` if you want the exact same shortcuts.

### Folding

| Neovim  | Helix |
|---------|--------|
| Cmd+[ / Cmd+] / Fold all / Unfold all | No Vim-style folding; Helix uses selection and tree-sitter. ⚠️ Different model. |

### Search & pickers

Cmd+p → file picker, Cmd+f → search, Cmd+Shift+f → global search, Cmd+b → buffers, Cmd+\ → file explorer: all ✅ and configured.

### What cannot be ported 1:1

- **Folding:** Vim-style za, zc, zo, zM, zR — use selection/tree-sitter in Helix.
- **Terminal:** Cmd+t for integrated terminal — use `:sh` or an external terminal.
- **Neovim-only pickers:** Lua path, runtime path, file types, autocmds, options, keymaps, zen, news, etc. — use command palette and built-in pickers where they exist.
- **Copy file path (Cmd+Alt+c):** No built-in; possible via `:run-shell-command` and expansions (see Command line doc).
- **Source config / eval line or selection:** Neovim-specific; N/A in Helix.

### Verification: what could still be added (Neovim → Helix)

Your Neovim keymaps have been checked against Helix’s Keymap and Commands docs. Summary:

| Neovim shortcut | Action | In Helix config? | Can add? |
|-----------------|--------|------------------|----------|
| Cmd+Shift+P, Cmd+a/c/v/x/s/z/y/q, Cmd+Shift+s, Cmd+n, Cmd+Alt+q, Cmd+Shift+Alt+q | Editor basics | ✅ Yes | — |
| Ctrl+a/e, Cmd+arrows | Movement | ✅ Yes | — |
| Cmd+p, Cmd+f, Cmd+Shift+f, Cmd+b, Cmd+\\ | Search & pickers | ✅ Yes | — |
| Cmd+Alt+Left/Right, Cmd+w, Cmd+Alt+w, Cmd+Shift+w, Cmd+Ctrl+Shift+arrows | Buffers & windows | ✅ Yes | — |
| Cmd+., Cmd+Alt+k/f, Cmd+Enter, Cmd+d/r/i, Cmd+Shift+d/r/i, Cmd+Alt+i/r/d | LSP & symbols | ✅ Yes | — |
| Cmd+/ | Comments | ✅ Yes | — |
| **Cmd+Alt+c** | Copy file path | ✅ Yes | — Bound to `:run-shell-command` + `%{buffer_name}` + pbcopy (macOS). |
| **Shift+arrows, Cmd+Shift+arrows, Alt+Shift+arrows** | Selection (line/word/paragraph extend) | ✅ Yes | — S-down/up, S-left/right, Cmd+S-arrows, A-S-left/right in normal & select. |
| **Cmd+?** | Search word under cursor | ✅ Yes | — `"Cmd-S-/" = "@miw*"` (select inner word then search). |
| **Ctrl+Space** (insert) | LSP completion | ✅ Yes | — `"C-space" = "completion"` in `[keys.insert]`. |
| **Cmd+Alt+Space** | Signature help | ✅ Yes | — `"Cmd-A-space" = "signature_help"` in normal & insert. |
| **Cmd+;** | Help | ✅ Yes | — Bound to `:tutor`. |
| **Cmd+\\** / **Cmd+Shift+\\** | File explorer / Scratch buffer | ✅ Yes | — Cmd+\\ = file_explorer, Cmd+Shift+\\ = `:new`. |
| Alt+Up/Down | Move line up/down | ❌ No | ⚠️ Partial — no single command; use `:pipe` / shell or macro. |
| Cmd+Alt+Ctrl+Right | Last buffer | ❌ No | ⚠️ Partial — use buffer picker (Cmd+b) or no direct “alternate buffer” in Helix. |
| Cmd+t, Cmd+[, ], Cmd+Alt+[, ], Neovim-only pickers, source/eval | Terminal, folding, dev | — | ❌ No — not available or Neovim-specific. |

So: **you don’t have to do the verification yourself.** The table above is the result of mapping your Neovim bindings to Helix. You can add any of the “Can add” rows to `config.toml` if you want the same shortcut in Helix.

---

## Terminal note (macOS)

Helix uses **Cmd** (Super) only if the terminal sends the right key codes. If Cmd keybindings do nothing:

- Enable “report Meta/Cmd” (or equivalent) in your terminal (e.g. Ghostty, iTerm2, WezTerm).
- See [Helix Terminal Support](https://github.com/helix-editor/helix/wiki/Terminal-Support#enhanced-keyboard-protocol).

---

## Cmd+. (period) and fallbacks

If **Cmd+.** (code action) does not work in your environment, use:

- **Cmd+Shift+P** → type “code action”, or  
- **Space+a** in normal mode.

---

## Links to dive into Helix

- [Helix](https://helix-editor.com/) — official site  
- [Documentation](https://docs.helix-editor.com/) — main docs  
- [Configuration](https://docs.helix-editor.com/configuration.html) — `config.toml` and options  
- [Keymap](https://docs.helix-editor.com/keymap.html) — default keys (normal, insert, select, space mode, etc.). Handy subsections: [Movement](https://docs.helix-editor.com/keymap.html#movement), [Changes](https://docs.helix-editor.com/keymap.html#changes), [Shell](https://docs.helix-editor.com/keymap.html#shell) (pipe selections: `|`, Alt-|, `!`, Alt-!, `$`), [Selection manipulation](https://docs.helix-editor.com/keymap.html#selection-manipulation), [Space mode](https://docs.helix-editor.com/keymap.html#space-mode)  
- [Key remapping](https://docs.helix-editor.com/remapping.html) — custom keybindings, modifiers (`Cmd-`, `C-`, `S-`, `A-`), special keys  
- [Commands](https://docs.helix-editor.com/commands.html) — typable commands (`:write`, `:clipboard-yank`, etc.) and static commands  
- [Command line](https://docs.helix-editor.com/command-line.html#quoting) — quoting, expansions (`%{cursor_line}`, `%{buffer_name}`, `%sh{...}`), and flags. Use this to bind keys to commands with arguments (e.g. copy file path, run shell with current line) and get closer to Neovim-style shortcuts  
- [Terminal support](https://github.com/helix-editor/helix/wiki/Terminal-Support#enhanced-keyboard-protocol) — Cmd/Super key in terminals  
- [Language support](https://docs.helix-editor.com/lang-support.html) — run `hx --health`  
- [GitHub](https://github.com/helix-editor/helix) — source and issues  

---

## Files in this directory

| File          | Purpose                                      |
|---------------|----------------------------------------------|
| `config.toml` | Editor options and keybindings (normal, select, insert) |
| `README.md`   | This file: premise, shortcuts, alignment notes, links  |
