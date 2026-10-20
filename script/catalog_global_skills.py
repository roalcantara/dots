#!/usr/bin/env -S uv run --python 3.13 --script
# Needs Python 3.11+ (tomllib).
from __future__ import annotations

import argparse
import json
import re
import tomllib
from pathlib import Path

SKILLS_ROOT = Path("/Users/roalcantara/.agents/skills")
OUTPUT_PATH = Path("/Users/roalcantara/Work/dots/config/kodexb/sources/skills.yml")
# Reviewed tags per skill (kb's tag conventions); a skill missing here falls back to derive_tags.
TAGS_PATH = OUTPUT_PATH.parent / "docs" / "skills.tags.toml"
# Where each skill was installed from, when the skills CLI recorded it: the source of its skills.sh link.
LOCK_PATH = SKILLS_ROOT.parent / ".skill-lock.json"

NOISE_TOKENS = {
    "a",
    "about",
    "add",
    "agent",
    "agents",
    "analysis",
    "assistant",
    "automation",
    "basics",
    "best",
    "builder",
    "build",
    "code",
    "core",
    "create",
    "creating",
    "creator",
    "data",
    "design",
    "developer",
    "development",
    "docs",
    "documentation",
    "expert",
    "flow",
    "for",
    "from",
    "generator",
    "guide",
    "guides",
    "helper",
    "helpers",
    "implementation",
    "implementing",
    "in",
    "it",
    "local",
    "manager",
    "mcp",
    "patterns",
    "pattern",
    "practices",
    "practice",
    "project",
    "projects",
    "prompt",
    "pro",
    "quality",
    "review",
    "rules",
    "setup",
    "skills",
    "skill",
    "system",
    "template",
    "templates",
    "testing",
    "the",
    "to",
    "tool",
    "tools",
    "usage",
    "using",
    "workflow",
    "workflows",
    "writer",
    "writing",
    "with",
}

DESCRIPTION_OVERRIDES = {
    "agent-governance": "Patterns for safe, policy-based AI agent governance.",
    "agent-supply-chain": "Verify AI agent dependency and tool supply-chain integrity.",
    "agentic-eval": "Evaluate and improve agent behavior with measurable checks.",
    "apollo-client": "GraphQL state management and caching with Apollo Client.",
    "apollo-connectors": "Wrap REST APIs as Apollo GraphQL connectors.",
    "apollo-federation": "Build and compose Apollo Federation subgraphs.",
    "apollo-ios": "Apollo GraphQL client for iOS and Swift apps.",
    "apollo-kotlin": "Apollo GraphQL client for Kotlin and Android apps.",
    "apollo-mcp-server": "Expose GraphQL APIs as MCP tools with Apollo MCP Server.",
    "apollo-router": "Route and secure federated GraphQL traffic with Apollo Router.",
    "apollo-router-plugin-creator": "Create custom Apollo Router Rust plugins.",
    "apollo-server": "Build GraphQL servers with Apollo Server.",
    "caveman": "Ultra-compressed coding communication mode.",
    "caveman-review": "One-line, high-signal code review feedback.",
    "code-reviewer": "Code review for local changes and pull requests.",
    "computer-use": "Control local desktop apps and browsers through accessibility automation.",
    "docs-writer": "Technical documentation writing and review.",
    "ears": "Spec workflow for requirements, design, and tasks in EARS format.",
    "electrobun": "Build desktop apps with Electrobun and Bun.",
    "exam-ready": "Prepare exam study material into concise, test-ready notes.",
    "fallow-review": "Review changed code for architecture and risk.",
    "firebase-basics": "Set up and manage Firebase projects and CLI workflows.",
    "firebase-firestore": "Work with Cloud Firestore data models and queries.",
    "functional-typescript": "Type-safe functional programming patterns for TypeScript.",
    "github-release": "Automate GitHub versioning and release flows.",
    "graphql-operations": "Write and optimize GraphQL queries, mutations, and fragments.",
    "graphql-schema": "Design and evolve GraphQL schemas and types.",
    "inertia-rails-architecture": "Build Rails apps with Inertia and server-driven UI patterns.",
    "job-scraper": "Search and extract structured job listings from hiring sites.",
    "logtape": "Structured logging for JavaScript and TypeScript apps.",
    "neovim-best-practices": "Configure and tune Neovim with practical Lua and plugin patterns.",
    "opensearch-launchpad": "Build OpenSearch search apps with semantic and hybrid retrieval.",
    "opensearch-skills": "Query and manage OpenSearch indexes and logs.",
    "orca-cli": "Control Orca worktrees, terminals, and agent workflows.",
    "orchestration": "Coordinate multi-agent or multi-step work with orchestration patterns.",
    "progress-report": "Display phase-based implementation progress and blockers.",
    "rover": "Manage GraphQL schemas with Apollo Rover.",
    "rust-best-practices": "Idiomatic Rust patterns and safe engineering guidance.",
    "sdd": "Spec-driven development with requirements, design, and tasks.",
    "senior-architect": "Design system architecture and technical strategy.",
    "shell-integration": "Build shell completions, hooks, and terminal integration.",
    "skill-creator": "Create and improve agent skills with proper structure.",
    "tailwindcss-advanced-layouts": "Advanced Tailwind layout patterns and CSS Grid techniques.",
    "test-data-management": "Generate, seed, and manage realistic test data.",
    "todo": "Track project tasks and work in Markdown.",
    "toolchain-setup": "Set up reproducible project tooling and quality gates.",
    "typesafe-ai": "Build AI-driven applications with type-safe logic.",
    "vercel-composition-patterns": "React component composition patterns.",
    "vercel-react-native-skills": "React Native and Expo best practices.",
}

TAG_ALIASES = {
    "authoring": "authoring",
    "write": "authoring",
    "writing": "authoring",
    "writer": "authoring",
    "write-skill": "authoring",
    "docs": "docs",
    "doc": "docs",
    "documentation": "docs",
    "readme": "docs",
    "readmes": "docs",
    "guides": "docs",
    "guide": "docs",
    "spec": "specs",
    "specs": "specs",
    "specification": "specs",
    "plan": "planning",
    "planning": "planning",
    "review": "review",
    "reviewer": "review",
    "ref": "review",
    "qa": "review",
    "evaluation": "review",
    "eval": "review",
    "rules": "rules",
    "rule": "rules",
    "agent": "agents",
    "agents": "agents",
    "agentic": "agents",
    "agentsmd": "agents",
    "research": "research",
    "analysis": "research",
    "prompt": "prompting",
    "prompts": "prompting",
    "prompting": "prompting",
    "automation": "automation",
    "tooling": "tooling",
    "setup": "tooling",
    "cli": "cli",
    "command": "cli",
    "shell": "shell",
    "zsh": "shell",
    "bash": "shell",
    "terminal": "shell",
    "linux": "shell",
    "devcontainer": "containers",
    "docker": "containers",
    "container": "containers",
    "cloud": "cloud",
    "aws": "cloud",
    "azure": "cloud",
    "gcp": "cloud",
    "kubernetes": "cloud",
    "api": "api",
    "graphql": "graphql",
    "apollo": "graphql",
    "react": "react",
    "frontend": "react",
    "bun": "bun",
    "ruby": "ruby",
    "rust": "rust",
    "go": "go",
    "python": "python",
    "javascript": "javascript",
    "typescript": "typescript",
    "ts": "typescript",
    "node": "node",
    "nvim": "nvim",
    "vim": "nvim",
    "lua": "nvim",
    "database": "data",
    "db": "data",
    "sql": "data",
    "postgres": "data",
    "security": "security",
    "auth": "security",
    "authorization": "security",
    "policy": "security",
    "testing": "testing",
    "test": "testing",
    "ci": "ops",
    "cd": "ops",
    "release": "release",
    "jobs": "jobs",
    "career": "career",
    "resume": "career",
    "cv": "career",
    "brand": "branding",
    "branding": "branding",
    "media": "media",
    "image": "media",
    "mcp": "mcp",
    "ai": "ai",
    "llm": "ai",
    "genai": "ai",
    "ops": "ops",
    "devops": "ops",
    "workflow": "ops",
    "orchestration": "ops",
    "github": "github",
    "git": "github",
    "design": "design",
    "diagram": "design",
    "mermaid": "design",
    "graph": "design",
    "product": "product",
    "feature": "product",
    "extension": "product",
    "code": "code",
    "refactor": "code",
    "supply": "security",
    "chain": "security",
    "governance": "security",
    "skills": "skills",
}

EXPLICIT_PURPOSES = {
    "academic-cv-builder": "career",
    "application-form-filler": "career",
    "auto": "automation",
    "automate-this": "automation",
    "career-changer-translator": "career",
    "claude-jobs": "jobs",
    "cold-email-writer": "authoring",
    "cover-letter-generator": "authoring",
    "create-agent": "agents",
    "create-command": "cli",
    "create-implementation-plan": "planning",
    "create-rule": "rules",
    "create-specification": "specs",
    "create-steering-documents": "docs",
    "create-tldr-page": "docs",
    "database-schema-designer": "data",
    "flox-environments": "ops",
    "frontend-design": "design",
    "game-changing-features": "product",
    "git-commit": "github",
    "grill-me": "review",
    "image-enhancer": "media",
    "interview-prep-generator": "career",
    "job-description-analyzer": "career",
    "job-scraper": "jobs",
    "land": "career",
    "link-workspace-packages": "workspace",
    "mcp-builder": "mcp",
    "mermaid-diagrams": "graph",
    "operation": "ops",
    "portfolio-case-study-writer": "authoring",
    "product-name": "branding",
    "prompt-engineering": "prompting",
    "prompt-optimizer": "prompting",
    "readme-blueprint-generator": "docs",
    "reference-list-builder": "career",
    "resume-ats-optimizer": "career",
    "resume-bullet-writer": "career",
    "resume-formatter": "career",
    "resume-quantifier": "career",
    "resume-section-builder": "career",
    "resume-tailor": "career",
    "resume-version-manager": "career",
    "setup-codemap-cli": "cli",
    "setup-semantic-release": "release",
    "slack-gif-creator": "media",
    "supply-chain": "security",
    "tailored-resume-generator": "career",
    "tech-resume-optimizer": "career",
    "tldr-prompt": "docs",
    "toolchain-setup": "tooling",
    "vercel-cli-with-tokens": "cli",
    "write-a-skill": "authoring",
    "writing-clearly-and-concisely": "authoring",
    "writing-for-agents": "authoring",
    "writing-plans": "planning",
    "writing-skills": "authoring",
}

def clean_token(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def is_placeholder_description(value: str | None) -> bool:
    if value is None:
        return True
    cleaned = value.strip()
    if not cleaned:
        return True
    if cleaned in {"|", ">", ">-", "|-", "| ", "> ", ">- "}:
        return True
    if cleaned.startswith("Skill:"):
        return True
    if cleaned.startswith("|") or cleaned.startswith(">"):
        return True
    return False


def parse_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    block = text[4:end]
    lines = block.splitlines()
    data: dict[str, str] = {}
    index = 0
    while index < len(lines):
        raw_line = lines[index]
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            index += 1
            continue
        if ":" not in raw_line:
            index += 1
            continue
        key, value = raw_line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value in {"|", ">", ">-", "|-"}:
            block_lines: list[str] = []
            index += 1
            while index < len(lines):
                next_line = lines[index]
                if next_line.startswith("  ") or next_line.startswith("\t"):
                    block_lines.append(next_line.strip())
                    index += 1
                    continue
                break
            data[key] = " ".join(block_lines).strip()
            continue
        data[key] = value.strip('"\'')
        index += 1
    return data


def normalize_name(name: str) -> str:
    return name.strip().lower().replace("/", "-")


def infer_description(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if text.startswith("---"):
        end = text.find("\n---\n", 4)
        if end != -1:
            text = text[end + 5 :]

    lines = text.splitlines()
    content_lines: list[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        if stripped.startswith("```"):
            continue
        if stripped.startswith("---"):
            continue
        if stripped.startswith(">") or stripped.startswith("|"):
            continue
        if stripped.startswith("- ") or stripped.startswith("* "):
            continue
        content_lines.append(stripped)

    if not content_lines:
        return "Skill overview."

    paragraph = " ".join(content_lines[:3])
    paragraph = re.sub(r"\s+", " ", paragraph).strip()
    paragraph = paragraph.strip("_*")
    if len(paragraph) > 180:
        paragraph = paragraph[:177].rstrip() + "..."
    if paragraph.endswith("."):
        return paragraph
    return paragraph + "."


def normalize_tag(tag: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "-", tag.lower().strip())
    cleaned = re.sub(r"-+", "-", cleaned).strip("-")
    return TAG_ALIASES.get(cleaned, cleaned)


def derive_tags(skill_name: str, description: str) -> list[str]:
    normalized = normalize_name(skill_name)
    tokens = [clean_token(tok) for tok in re.split(r"[-_/\s]+", normalized) if tok.strip()]
    tokens = [tok for tok in tokens if tok and tok not in NOISE_TOKENS]

    explicit_primary = EXPLICIT_PURPOSES.get(normalized)
    if explicit_primary:
        primary = normalize_tag(explicit_primary)
    else:
        primary = None
        for token in tokens:
            tag = normalize_tag(token)
            if tag in {"career", "ai", "react", "security", "design", "data", "api", "cloud", "research", "authoring", "prompting", "planning", "review", "ops", "release", "jobs", "tooling", "mcp", "media", "branding", "specs", "rules", "docs", "github", "bun", "nvim", "shell", "testing", "containers", "graphql", "agents", "cli", "product", "code"}:
                primary = tag
                break
        if primary is None:
            for token in reversed(tokens):
                mapped = normalize_tag(token)
                if mapped not in {"skills", ""}:
                    primary = mapped
                    break
            if primary is None:
                primary = "docs"

    secondary_candidates: list[str] = []
    for token in tokens:
        mapped = normalize_tag(token)
        if mapped and mapped not in {"skills", primary} and mapped in {"career", "ai", "react", "security", "design", "data", "api", "cloud", "research", "authoring", "prompting", "planning", "review", "ops", "release", "jobs", "tooling", "mcp", "media", "branding", "specs", "rules", "docs", "github", "bun", "nvim", "shell", "testing", "containers", "graphql", "agents", "cli", "product", "code"}:
            secondary_candidates.append(mapped)

    if not secondary_candidates:
        lowercase_desc = description.lower()
        for word in ["ai", "react", "graphql", "security", "data", "design", "research", "authoring", "prompting", "planning", "review", "ops", "release", "jobs", "docs", "github", "bun", "nvim", "shell", "testing", "containers", "agents", "cli", "product", "code"]:
            if word in lowercase_desc:
                secondary_candidates.append(word)
                break

    tags = ["skills", primary]
    for tag in secondary_candidates:
        if tag and tag not in tags:
            tags.append(tag)
            break
    return tags[:3]


def load_tags() -> dict[str, list[str]]:
    if not TAGS_PATH.exists():
        return {}
    return tomllib.loads(TAGS_PATH.read_text(encoding="utf-8"))


def load_sources() -> dict[str, str]:
    if not LOCK_PATH.exists():
        return {}
    skills = json.loads(LOCK_PATH.read_text(encoding="utf-8")).get("skills", {})
    return {name: meta["source"] for name, meta in skills.items() if meta.get("source")}


def load_csv_sources() -> dict[str, dict[str, str]]:
    csv_path = Path("/Users/roalcantara/Work/dots/script/skills.csv")
    if not csv_path.exists():
        return {}

    rows: dict[str, dict[str, str]] = {}
    for line in csv_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parts = [part.strip() for part in line.split(",", 2)]
        if len(parts) < 3:
            continue
        folder_name, repo_ref, link = parts
        if not folder_name or not repo_ref or not link:
            continue
        repo = repo_ref.split("@", 1)[0].strip()
        if not repo:
            continue
        rows[folder_name] = {
            "repo": repo,
            "link": link,
            "command": f"skills add -yg https://github.com/{repo} --skill {folder_name}",
        }
    return rows


def skill_link(skill_name: str, sources: dict[str, str], csv_sources: dict[str, dict[str, str]]) -> str | None:
    """The skill's skills.sh page, preferring the canonical CSV winner link when it exists."""
    if skill_name in csv_sources:
        return csv_sources[skill_name]["link"]
    source = sources.get(skill_name)
    return f"https://skills.sh/{source}/{skill_name}" if source else None


def build_entry_key(skill_name: str) -> str:
    return f"/{skill_name}"


def build_skill_command(skill_name: str, sources: dict[str, str], csv_sources: dict[str, dict[str, str]]) -> str | None:
    if skill_name in csv_sources:
        return csv_sources[skill_name]["command"]
    source = sources.get(skill_name)
    if not source:
        return None
    return f"skills add -yg https://github.com/{source} --skill {skill_name}"


def render_yaml(entries: list[dict]) -> str:
    # Cheats, not commands: these entries are found by search, not run. The `skills` tag tells them apart from other
    # cheats, so a filter on it lists every skill.
    lines: list[str] = ["cheats:"]
    for entry in entries:
        lines.append(f"  {entry['entry_key']}:")
        lines.append(f"    desc: {json.dumps(entry['description'], ensure_ascii=False)}")
        if entry["tags"]:
            lines.append(f"    tags: [{', '.join(entry['tags'])}]")
        if entry["link"]:
            lines.append(f"    links: [{entry['link']}]")
        lines.append("    notes:")
        lines.append(f"      - md: {entry['note']}")
        if entry["command"]:
            lines.append(f"      - sh: {entry['command']}")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Catalog ~/.agents/skills as kb's skills.yml")
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH, help="where to write (default: the sources folder)")
    output = parser.parse_args().output
    reviewed = load_tags()
    sources = load_sources()
    csv_sources = load_csv_sources()
    entries: list[dict] = []
    for skill_dir in sorted(SKILLS_ROOT.iterdir(), key=lambda p: p.name.lower()):
        if not skill_dir.is_dir():
            continue
        skill_file = skill_dir / "SKILL.md"
        if not skill_file.exists():
            continue
        frontmatter = parse_frontmatter(skill_file)
        skill_name = frontmatter.get("name") or skill_dir.name
        inferred = DESCRIPTION_OVERRIDES.get(skill_name) or infer_description(skill_file)
        description = frontmatter.get("description") or inferred
        if is_placeholder_description(description):
            description = inferred
        derived = [tag for tag in derive_tags(skill_name, description) if tag != "skills"]
        topics = reviewed.get(skill_dir.name, derived)
        entries.append(
            {
                "entry_key": build_entry_key(skill_name),
                "description": description,
                "tags": ["skills", *(tag for tag in topics if tag != "skills")],
                "link": skill_link(skill_dir.name, sources, csv_sources),
                "command": build_skill_command(skill_dir.name, sources, csv_sources),
                # kb reads a file:// note's content (~ is the home folder): the SKILL.md becomes the entry's notes.
                "note": f"file://~/{skill_file.relative_to(Path.home()).as_posix()}",
            }
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_yaml(entries), encoding="utf-8")
    tagged = sum(1 for entry in entries if entry["entry_key"].lstrip("/") in reviewed)
    print(f"Cataloged {len(entries)} skills in {output} ({tagged} with reviewed tags)")


if __name__ == "__main__":
    main()
