---
description: Open a pull request for the current branch — push it, then write a descriptive title and body from the commits, the diff and the repository's own conventions (never merges)
argument-hint: Optional base=<branch>, draft, then free notes for the body (e.g. "base=main draft owner must check the Lig popups")
---

<task>
Open the pull request for the current branch. Write the title and body from what the branch actually changes and from
the repository's own rules for pull requests and commit messages. Running this command is the operator's request to
push this branch and open the PR, nothing more: never merge, never push another branch, never force-push.
</task>

<context>
Arguments: $ARGUMENTS

- `base=<branch>`: the branch to merge into. Default: the repository's default branch.
- `draft`: open it as a draft.
- Anything else: the operator's notes. Put them in the body as they are written.

Conventions win over this command's defaults. The repository's instruction files (`AGENTS.md`, `CLAUDE.md`,
`CONTRIBUTING.md`, `docs/CONTRIBUTING.md`) and its PR template can set things such as a git wrapper, a title format,
required sections, or "no push". Where they say something, do what they say.
</context>

<workflow>

## 1. Probe (one shell call; read nothing else yet)

```bash
set +e
branch=$(git branch --show-current)
base="<base= argument, if given>"
[ -z "$base" ] && base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
[ -z "$base" ] && base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
echo "## branch $branch → $base"
echo "## existing PR"; gh pr view "$branch" --json number,state,url,title 2>/dev/null || echo none
echo "## uncommitted"; git status --short | head -15
echo "## upstream"; git rev-parse --abbrev-ref '@{u}' 2>/dev/null && git rev-list --left-right --count '@{u}...HEAD'
echo "## commits"; git log --format='%h %s' "origin/$base..HEAD" | head -40
echo "## files"; git diff --stat=100 "origin/$base...HEAD" | tail -30
echo "## template"; for t in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md PULL_REQUEST_TEMPLATE.md; do [ -f "$t" ] && echo "$t"; done; ls .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null
echo "## rules"; for f in AGENTS.md CLAUDE.md CONTRIBUTING.md docs/CONTRIBUTING.md; do [ -f "$f" ] && grep -n -i -E 'pull request|\bPR\b|push|conventional|commit message|wrapper' "$f" | head -8 | sed "s|^|$f:|"; done
echo "## recent merged titles"; gh pr list --state merged --base "$base" --limit 5 --json title -q '.[].title' 2>/dev/null
```

## 2. Stop when there is nothing to open

- **No commits** ahead of the base: say so and stop.
- **A PR is already open** for this branch: print its URL. Offer to rewrite its title and body with `gh pr edit`.
  Never open a second PR.
- **On the base branch itself:** stop and ask for a feature branch.
- **Uncommitted changes:** list them and leave them out. Say they are not in the PR. Never stage or commit them
  unless the operator asks: they may belong to someone else.

## 3. Read just enough to write it

- Read the rule lines the probe found, and read the PR template if there is one.
- Read the commit messages in full (`git log origin/<base>..HEAD`). Open the diff only where a subject leaves unclear
  what changed or why.
- Do not run the test suite to fill the body. Report only checks that were actually run, in this session or as
  recorded in commits or a handoff note.

## 4. Write the title and body

**Title.** Under 72 characters, saying what the branch does as a whole, not what its last commit did. Use the
repository's format: Conventional Commits (`type(scope): Description`, with the capitalisation its rules ask for) when
its commits or merged titles use it, otherwise its merged titles' style.

**Body.** Fill the PR template when there is one. Otherwise use these sections:

```markdown
## Summary
<2–4 sentences: what changes for a user or a developer, and why>

## Changes
- <one line per logical change, grouped by area; name the key files>

## Testing
- <each check that was run, with its result; "not run" where it was not>

## Notes
<the operator's notes; follow-ups, open questions, anything reviewers must decide or check by hand. Omit when empty>
```

- Write for a reviewer who has not seen the session: plain words, no session history, no "as discussed".
- End with the PR attribution line the session gives, if it gives one.

## 5. Push and open

1. **Push the branch** if it has no upstream or is ahead of it. Use `git push -u origin <branch>`, through the
   repository's git wrapper if its rules require one. Never `--force`. If the push is rejected, stop and report.
2. **Open the PR:** `gh pr create --base <base> --head <branch> --title "<title>" --body-file <tmp file>`, adding
   `--draft` when asked. Write the body to a temporary file so it isn't mangled by shell quoting.
3. **Print the PR URL.**

</workflow>

<checklist>
- [ ] One probe call; no duplicate PR; the base branch is never pushed.
- [ ] The title covers the whole branch and follows the repository's format.
- [ ] The body reports only checks that were run; uncommitted files are named as left out.
- [ ] Pushed without force, and only this branch; the PR was opened, not merged.
</checklist>
