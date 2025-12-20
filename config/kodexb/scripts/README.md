# kodexb | Knowledge Base | Source Files

## OVERVIEW

- kodexb stores knowledge in YAML files under:
  - In production: `~/.config/kodexb/sources/`
  - In this project: `assets/sources/`

- Three entry types are supported: **Bookmarks**, **Commands**, and **Cheats**.

### 1. Entries Common Attributes

All entry types share these fields:

| **FIELD** | **TYPE**                                    | **REQUIRED** | **RULES**            |
| --------- | ------------------------------------------- | :----------: | -------------------- |
| `desc`    | String                                      |      ✓       | Minimum 5 characters |
| `tags`    | String[]                                    |      ✓       | 1-4 tags             |
| `links`   | String[] or Map<String, String>[]           |      -       | Optional             |
| `notes`   | String or String[] or Map<String, String>[] |      -       | Optional             |

### 2. Entry Types

#### Bookmarks

- **WHAT:** Collections of links related to a single topic.
- **WHERE:** By default, any entry under the root node `bookmarks` is considered to be a bookmark.
- **EXAMPLE:**

    ```yaml
    bookmarks:
    https://google.com:
        desc: "Google search engine and related services"
        tags: ["search", "engine"]
        links: [https://gemini.google.com, https://gmail.com]
        notes:
        - md: |
            # Additional context
            Optional markdown or other structured notes
        - json: |
            {"title": "Google", "url": "https://google.com"}
    ```

#### Commands

- **WHAT:** Collections of commands related to a single topic.
- **WHERE:** By default, any entry under the root node `commands` is considered to be a command.
- **EXAMPLE:**

    ```yaml
    commands:
    ls:
        desc: "List directory contents with options"
        tags: ["filesystem", "listing"]
        notes:
        - md: |
            List with details: `ls -la`
    ```

#### Cheats

- **WHAT:** Collections of knowledge snippets or quick reference material.
- **WHERE:** By default, any entry under the root node `cheats` is considered to be a cheat.
- **EXAMPLE:**

    ```yaml
    cheats:
    Cynefin Framework:
        desc: "Framework for decision-making based on domain complexity"
        tags: ["decision-making", "complexity"]
        links:
        - Wikipedia: https://en.wikipedia.org/wiki/Cynefin_framework
        - Video: https://youtube.com/watch?v=N7oz366X0-8
        notes:
        - md: |
            # Domains
            - **Simple**: Clear problems, best practices apply
            - **Complicated**: Expert analysis required
            - **Complex**: Adaptive solutions needed
            - **Chaotic**: Immediate action required
    ```

### 3. Entries Notes Format

**Notes** are rendered as unified markdown:
  - `md:` - Rendered as inline markdown
  - Other keys (e.g., `json`, `yaml`, `sql`) - Rendered as code blocks

## DEVELOPMENT

```bash
bun install
```

To run:

```bash
bun run index.ts
```

This project was created using `bun init` in bun v1.3.4. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.
