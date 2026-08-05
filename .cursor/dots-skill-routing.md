# Dots skill routing

Load [`.agents/skills/dots-context/SKILL.md`](../.agents/skills/dots-context/SKILL.md)
first. Use this table when a task matches a domain below.

<!-- skills:domain-routing:start -->
| When the task involves… | Read this skill first | Note |
| --- | --- | --- |
| assets/integration, assets/features TypeScript, bun test under assets/ | `bun-development` | project |
| mise.toml, usage field, task arguments, ${usage_*?} | `mise-expert` | global |
| config/bin, install, shell scripts, ShellCheck | `bash-scripting` | global |
| GitHub Actions, workflows, CI, .github/workflows | `github-actions-docs` | global |
| Docker, Dockerfile, distros, CST, Hadolint, container-structure-test | `docker-expert` | global |
| Gherkin, Cucumber, assets/features, .feature files | `bdd-gherkin-specification` | global |
<!-- skills:domain-routing:end -->

## Registry maintenance

After editing [`assets/guides/SKILLS.yml`](../assets/guides/SKILLS.yml):

```bash
mise run -C assets skill validate
mise run -C assets skill sync
```
