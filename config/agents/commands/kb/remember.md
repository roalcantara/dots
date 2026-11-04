---
description: Record the useful commands, bookmarks and cheat sheets of this session in kb's knowledge sources (YAML), so they can be found later in kb
argument-hint: Optional file=<name.yml> (target file), only=commands|bookmarks|cheats, dry (propose only), then free notes on what to record (e.g. "file=macos.yml the eject diagnosis")
---

<task>
Turn what this session used or learned into kb entries: commands worth running again, pages worth reopening, and
how-tos worth following again. Add them to the knowledge sources, matching each file's existing shape, validate
them, and report what changed. Never commit: the operator reviews the diff.
</task>

<context>
**Where.** The sources directory is `sources_path` in `~/.config/kb/config.toml`, else `~/.config/kodexb/sources`
(both may be links into a dotfiles repo; write through the link). Tag aliases live in its `docs/tags.toml`.

**Entry types.** Each source file has top-level sections; an entry is a key under one of them:

| Section | Key | Is | Content |
| --- | --- | --- | --- |
| `commands` | the command, exactly as run (placeholders as `<name>`) | one command | variants and caveats in `notes` |
| `bookmarks` | the URL | a page worth reopening | what it answers |
| `cheats` | a title naming the goal or symptom | a how-to: several commands, a mid-to-long read | goal, steps, symptom → cause → fix, gotchas, what was measured |

Every entry has `desc` (one line) and `tags` (a flow list); `links` (a flow list of URLs) and `notes` are optional.
Notes are a list of blocks, indented as in the files:

```yaml
    notes:
      - md: | #markdown
          Markdown text
      - sh: | #shell
          # comment
          command
```

**Tags.** Rules: lowercase, hyphenated, 2–30 characters, the shortest established form, plural for countable
things (`containers`), as written for names (`macos`). Prefer tags the sources already use; never use an alias
listed in `docs/tags.toml` (use its table name instead). A tag used nowhere else needs a reason.

Arguments: $ARGUMENTS

- `file=<name>`: put every entry in this file (created if missing, after asking).
- `only=<type>`: record only that entry type.
- `dry`: stop after step 3 and print the proposal.
- Anything else: the operator's hint about what to record; it narrows the harvest, it does not replace it.
</context>

<workflow>

1. **Locate and survey (one shell call).**

   ```bash
   src=$(sed -nE 's/^sources_path *= *"?([^"]*)"?.*/\1/p' ~/.config/kb/config.toml 2>/dev/null | head -1)
   src="${src:-$HOME/.config/kodexb/sources}"; src="${src/#\~/$HOME}"; cd "$src" || exit 1
   ls *.yml *.yaml
   grep -hoE 'tags: \[[^]]*\]' *.yml *.yaml | tr -d '[]' | sed 's/tags: //' | tr ',' '\n' | tr -d ' ' \
     | sort | uniq -c | sort -rn > /tmp/kb-tags.txt; head -60 /tmp/kb-tags.txt
   git -C "$src" status --short -- . | head
   ```

   Uncommitted changes in a file you will touch are the operator's: keep them, build on them.

2. **Harvest from the session.** Go through the whole conversation, not only its end, and list candidates:
   - Commands that worked and would be run again: setup, diagnosis, verification, recovery. Not one-off
     exploration (`ls`, `cat`, `grep` of a path), not commands that failed unless the failure is the lesson.
   - Pages that answered a question (documentation, issues, APIs).
   - How-tos: a sequence that reached a goal, a diagnosis with its symptom and cause, a comparison with
     measurements, a set of failures with their fixes, a decision with its trade-offs.

   If part of the session was summarised, recover exact commands and figures from the session transcript when the
   agent keeps one (Claude Code: `~/.claude/projects/<project>/<session-id>.jsonl`; extract the assistant text
   and tool inputs with `jq`). Never invent a detail you cannot recover: leave it out, or ask.

3. **Place and deduplicate.** For each candidate:
   - Pick the file whose subject matches (`macos.yml`, `docker.yml`, `git.yml`, …); prefer the file the operator
     is already filling for this subject. A new file only when none fits: ask first.
   - Search all sources for the key and its subject (`grep -rn -F '<key>' .`). If it exists, **enhance** it
     (add notes, correct what this session proved wrong) instead of adding a duplicate. Correcting an entry the
     operator wrote is allowed only when the session disproved it: say so in the report.
   - Generalise: replace session specifics with placeholders (`<pid>`, `<volume>`, `<branch>`), keep the figures
     that were measured, as measurements.

   Print the proposal, grouped by file and section: key, `desc`, tags, and new / enhanced. With `dry`, stop here.

4. **Write.** Read each target file first (its sections, indentation, comment headers, tags in use). Then:
   - Add entries to the matching existing section, under the matching `# … - QUICK REFERENCE` comment when the
     file groups them so; add a section at the end only if the file lacks it.
   - Never reorder, reformat or drop existing entries.
   - Quote a key with single quotes when it contains `: `, ` #`, or starts with `[`, `{`, `"`, `'`, `!`, `&`,
     `*`, `@`, `%`, `` ` ``, `|`, `>`.
   - Never write secrets: no keys, tokens, passwords, private hostnames or personal data; no scratch or temp
     paths of this session.
   - Write only what the session ran or verified. State what was not tested in the entry itself.

5. **Validate (one shell call).**

   ```bash
   for f in <touched files>; do
     bun -e 'import {YAML} from "bun"; const f=process.argv[1]; const d=YAML.parse(await Bun.file(f).text());
       for (const [s,v] of Object.entries(d)) if (v && typeof v==="object") for (const [k,e] of Object.entries(v))
         if (["commands","bookmarks","cheats"].includes(s) && !e?.desc) console.log("NO DESC", f, s, k);
       console.log(f, "ok")' "$f"
   done
   ```

   Every touched file parses; every new entry has `desc` and `tags`; each new tag is in `/tmp/kb-tags.txt` or
   justified, and is not an alias in `docs/tags.toml`.

6. **Report.** Per file: entries added and enhanced (keys), what was corrected and why, candidates skipped and
   why, anything not tested. End with: "Not committed; review with `git -C <src> diff`. kb picks it up on
   Refresh (⌘R)."

</workflow>

<checklist>
- [ ] The whole session harvested, summarised parts recovered from the transcript or left out.
- [ ] Existing entries enhanced rather than duplicated; operator's uncommitted edits kept.
- [ ] Commands keyed by the command, bookmarks by URL, cheats by a goal title; every entry has `desc` and `tags`.
- [ ] Tags reused where possible; none is an alias.
- [ ] No secrets, no session scratch paths; only what was run or verified.
- [ ] Every touched file parses.
- [ ] Nothing committed.
</checklist>
