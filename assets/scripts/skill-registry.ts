#!/usr/bin/env bun
/**
 * Dots skill registry: validate, sync, install, report.
 * Reads assets/guides/SKILLS.yml and skills-lock.json at repo root.
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { pathToFileURL } from "node:url"

const ACTION = process.env.usage_cmd || ""
const JSON_OUT = process.env.usage_json === "true"
const DRY_RUN = process.env.usage_dry_run === "true"
const VALID_ACTIONS = ["validate", "sync", "install", "all", "report"]

if (!VALID_ACTIONS.includes(ACTION)) {
  console.error(
    "skill: action is required: validate, sync, install, all, or report",
  )
  process.exit(1)
}

function gitRoot(): string {
  const r = Bun.spawnSync(["git", "rev-parse", "--show-toplevel"])
  if (r.exitCode !== 0) {
    console.error("skill: run from inside the Dots git checkout")
    process.exit(1)
  }
  return new TextDecoder().decode(r.stdout).trim()
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return v !== null && typeof v === "object" && !Array.isArray(v)
}

async function loadRegistry() {
  const root = gitRoot()
  const url = pathToFileURL(join(root, "assets/guides/SKILLS.yml")).href
  return import(url, { with: { type: "yaml" } }).then((m) => m.default)
}

function loadSkillLock(root: string): Set<string> {
  const fp = join(root, "skills-lock.json")
  if (!existsSync(fp)) return new Set()
  const lock = JSON.parse(readFileSync(fp, "utf8")) as {
    skills?: Record<string, unknown>
  }
  return new Set(Object.keys(lock.skills ?? {}))
}

function loadActualProjectSkills(root: string): Set<string> | null {
  const child = Bun.spawnSync(["skills", "list", "--json"], { cwd: root })
  if (child.exitCode !== 0) {
    return null
  }
  try {
    const list = JSON.parse(new TextDecoder().decode(child.stdout)) as Array<{
      scope?: string
      path?: string
    }>
    return new Set(
      list
        .filter(
          (s) =>
            s.scope === "project" &&
            (s.path || "").includes(".agents/skills/"),
        )
        .map((s) => (s.path || "").split("/").pop() || "")
        .filter(Boolean),
    )
  } catch {
    return null
  }
}

function diffSets(actual: Set<string>, expected: Set<string>) {
  const missing = [...expected].filter((s) => !actual.has(s))
  const extra = [...actual].filter((s) => !expected.has(s))
  return { missing, extra }
}

let validateOk = false
let drift: {
  actual_skills: string[]
  expected_skills: string[]
  missing: string[]
  extra: string[]
} | null = null

const ALLOWED_LOCATIONS = new Set(["owned", "project", "global"])
const ALLOWED_TYPES = new Set([
  "required",
  "optional",
  "reference",
  "blocked",
])
const FORBIDDEN_SKILL_FIELDS = ["source", "install", "link", "decision", "load"]
const REDUNDANT_NOTES = new Set(["owned", "project", "global only"])

let ok = true
function check(cond: boolean, msg: string) {
  if (!cond) {
    console.error(`skill validate: ${msg}`)
    ok = false
  }
}

async function validate(options: { skipDrift?: boolean } = {}) {
  ok = true
  drift = null
  const root = gitRoot()
  const registry = await loadRegistry()
  const lockedSkills = loadSkillLock(root)
  const registryProjectSkills = new Set<string>()

  check(registry?.schema_version === 3, "schema_version must be 3")
  check(isRecord(registry?.skills), "skills must be a mapping")
  check(
    !Object.hasOwn(registry ?? {}, "electrobun_routing"),
    "top-level electrobun_routing must not exist",
  )

  const skills = (registry.skills ?? {}) as Record<string, Record<string, unknown>>
  for (const [name, skill] of Object.entries(skills)) {
    check(isRecord(skill), `${name} must be a mapping`)
    if (!isRecord(skill)) continue

    check(
      ALLOWED_LOCATIONS.has(String(skill.location)),
      `${name}.location invalid: ${skill.location}`,
    )
    check(
      typeof skill.rationale === "string" && skill.rationale.trim() !== "",
      `${name}.rationale required`,
    )
    check(isRecord(skill.policy), `${name}.policy must be a mapping`)
    if (!isRecord(skill.policy)) continue

    const policyType = String(skill.policy.type)
    check(
      ALLOWED_TYPES.has(policyType),
      `${name}.policy.type invalid: ${policyType} (routed is not used in Dots)`,
    )

    if (skill.location === "project") {
      registryProjectSkills.add(name)
      check(
        lockedSkills.has(name),
        `${name}: location project requires an entry in skills-lock.json`,
      )
    } else {
      check(
        !lockedSkills.has(name),
        `${name}: only location project entries may appear in skills-lock.json`,
      )
    }

    for (const f of FORBIDDEN_SKILL_FIELDS) {
      check(!Object.hasOwn(skill, f), `${name} must not have forbidden field: ${f}`)
    }

    const t = policyType
    const hasUsage = isRecord(skill.policy.usage)
    const hasRouting = isRecord(skill.policy.routing)
    const hasSurfaces = isRecord(skill.policy.surfaces)
    const hasReason =
      typeof skill.policy.reason === "string" &&
      skill.policy.reason.trim() !== ""
    const hasRedirect = Array.isArray(skill.policy.redirect_to)

    if (t === "required") {
      check(hasUsage, `${name}: required must have usage`)
      check(!hasRouting, `${name}: required must not have routing`)
      check(!hasSurfaces, `${name}: required must not have surfaces`)
      check(!hasReason, `${name}: required must not have reason`)
      check(!hasRedirect, `${name}: required must not have redirect_to`)
    } else if (t === "optional") {
      check(hasUsage, `${name}: optional must have usage`)
      check(!hasReason, `${name}: optional must not have reason`)
      check(!hasRedirect, `${name}: optional must not have redirect_to`)
    } else if (t === "reference") {
      check(hasUsage, `${name}: reference must have usage`)
      check(!hasRouting, `${name}: reference must not have routing`)
      check(!hasSurfaces, `${name}: reference must not have surfaces`)
      check(!hasReason, `${name}: reference must not have reason`)
      check(!hasRedirect, `${name}: reference must not have redirect_to`)
    } else if (t === "blocked") {
      check(hasReason, `${name}: blocked must have reason`)
      check(!hasUsage, `${name}: blocked must not have usage`)
      check(!hasRouting, `${name}: blocked must not have routing`)
      check(!hasSurfaces, `${name}: blocked must not have surfaces`)
      check(skill.location === "global", `${name}: blocked requires location: global`)
    }

    if (hasUsage) {
      const usage = skill.policy.usage as Record<string, unknown>
      check(
        typeof usage.summary === "string" && usage.summary.trim() !== "",
        `${name}.usage.summary required`,
      )
      const when = usage.when as Record<string, unknown> | undefined
      const load = when?.load
      check(
        Array.isArray(load) && load.length > 0,
        `${name}.usage.when.load must be a non-empty list`,
      )
      if (Array.isArray(load)) {
        for (const item of load) {
          check(
            typeof item === "string" && item.trim() !== "",
            `${name}.usage.when.load entries must be non-empty strings`,
          )
        }
      }
      const avoid = when?.avoid
      check(Array.isArray(avoid), `${name}.usage.when.avoid must be a list`)
    }

    if (hasRouting) {
      for (const [surface, routes] of Object.entries(
        skill.policy.routing as Record<string, unknown>,
      )) {
        check(
          Array.isArray(routes),
          `${name}.routing.${surface} must be a list`,
        )
        if (!Array.isArray(routes)) continue
        for (const route of routes) {
          check(
            isRecord(route),
            `${name}.routing.${surface} entries must be mappings`,
          )
          if (!isRecord(route)) continue
          check(
            typeof route.order === "number",
            `${name}.routing.${surface}.order must be numeric`,
          )
          check(
            Array.isArray(route.triggers) && route.triggers.length > 0,
            `${name}.routing.${surface}.triggers must be non-empty list`,
          )
          if (Array.isArray(route.triggers)) {
            for (const trig of route.triggers) {
              check(
                typeof trig === "string" && trig.trim() !== "",
                `${name}.routing.${surface}.triggers entries must be non-empty strings`,
              )
            }
          }
          if (Object.hasOwn(route, "note")) {
            check(
              typeof route.note === "string" && route.note.trim() !== "",
              `${name}.routing.${surface}.note must be non-empty when present`,
            )
            check(
              !REDUNDANT_NOTES.has(String(route.note).trim()),
              `${name}.routing.${surface}.note must not be redundant: ${route.note}`,
            )
          }
        }
      }
    }

    if (skill.location === "owned") {
      const skillPath = join(root, ".agents/skills", name, "SKILL.md")
      check(
        existsSync(skillPath),
        `${name}: owned skill missing at .agents/skills/${name}/SKILL.md`,
      )
    }
  }

  for (const lockedName of lockedSkills) {
    check(
      registryProjectSkills.has(lockedName),
      `${lockedName}: skills-lock.json entry requires matching location: project in SKILLS.yml`,
    )
  }

  const actualSkills = loadActualProjectSkills(root)
  const expectedSkills = new Set<string>()
  for (const [name, skill] of Object.entries(skills)) {
    if (skill.location === "owned" || skill.location === "project") {
      expectedSkills.add(name)
    }
  }

  if (options.skipDrift) {
    validateOk = ok
    return
  }

  if (actualSkills === null) {
    console.warn(
      "skill validate: skills CLI unavailable — skipping project install drift check",
    )
    for (const name of expectedSkills) {
      if (skills[name]?.location === "project") {
        const skillPath = join(root, ".agents/skills", name, "SKILL.md")
        check(
          existsSync(skillPath),
          `${name}: project skill not installed at .agents/skills/${name}/SKILL.md — run mise run -C assets skill install`,
        )
      }
    }
  } else {
    const { missing, extra } = diffSets(actualSkills, expectedSkills)
    for (const m of missing) {
      check(
        false,
        `${m}: expected project skill not installed — run mise run -C assets skill install`,
      )
    }
    for (const e of extra) {
      check(
        false,
        `${e}: installed project skill not in registry as owned or project`,
      )
    }
    drift = {
      actual_skills: [...actualSkills].sort(),
      expected_skills: [...expectedSkills].sort(),
      missing,
      extra,
    }
  }

  validateOk = ok
}

function replaceManaged(
  root: string,
  relativePath: string,
  marker: string,
  content: string,
) {
  const fp = join(root, relativePath)
  if (!existsSync(fp)) {
    console.error(`skill sync: missing file ${relativePath}`)
    process.exit(1)
  }
  const start = `<!-- skills:${marker}:start -->`
  const end = `<!-- skills:${marker}:end -->`
  const orig = readFileSync(fp, "utf8")
  const si = orig.indexOf(start)
  const ei = orig.indexOf(end)
  if (si === -1 || ei === -1 || ei < si) {
    console.error(
      `skill sync: missing markers for ${marker} in ${relativePath}`,
    )
    process.exit(1)
  }
  const next =
    orig.slice(0, si + start.length) +
    `\n${content.trimEnd()}\n` +
    orig.slice(ei)
  if (DRY_RUN) {
    const status = next === orig ? "up to date" : "would update"
    console.log(`skill sync: dry-run ${status} ${relativePath}:${marker}`)
    return
  }
  writeFileSync(fp, next)
}

function statusNote(location: string) {
  if (location === "project") return "project"
  if (location === "owned") return "owned"
  return "global"
}

async function sync() {
  await validate()
  if (!validateOk) process.exit(1)

  const registry = await loadRegistry()
  const root = gitRoot()
  const skills = (registry.skills ?? {}) as Record<
    string,
    Record<string, unknown>
  >

  const optionals = Object.entries(skills)
    .filter(
      ([, s]) =>
        s.policy?.type === "optional" && isRecord(s.policy?.surfaces),
    )
    .map(([name, s]) => ({ name, ...s }))

  const claudeList = optionals
    .map((s) => {
      const surfaces = s.policy.surfaces as Record<string, string>
      return `- \`${s.name}\` — ${surfaces.claude_optional ?? s.policy.usage?.summary}`
    })
    .join("\n")
  replaceManaged(root, "AGENTS.md", "optional-companions", claudeList)

  const ctxTable = [
    "| Skill | When |",
    "| --- | --- |",
    ...optionals.map((s) => {
      const surfaces = s.policy.surfaces as Record<string, string>
      return `| **${s.name}** | ${surfaces.dots_context_optional ?? surfaces.claude_optional ?? ""} |`
    }),
  ].join("\n")
  replaceManaged(
    root,
    ".agents/skills/dots-context/SKILL.md",
    "optional-companions",
    ctxTable,
  )

  const domainRoutes: Array<{
    name: string
    order: number
    triggers: string[]
    note?: string
    location: string
  }> = []
  for (const [name, skill] of Object.entries(skills)) {
    const domain = isRecord(skill.policy?.routing)
      ? (skill.policy.routing as Record<string, unknown>).domain
      : undefined
    if (!Array.isArray(domain)) continue
    for (const route of domain) {
      if (!isRecord(route)) continue
      domainRoutes.push({
        name,
        order: Number(route.order),
        triggers: (route.triggers as string[]) ?? [],
        note: route.note as string | undefined,
        location: String(skill.location),
      })
    }
  }
  domainRoutes.sort((a, b) => a.order - b.order)

  const domainTable = [
    "| When the task involves… | Read this skill first | Note |",
    "| --- | --- | --- |",
    ...domainRoutes.map((r) => {
      let note = statusNote(r.location)
      if (r.note) note += ` — ${r.note}`
      return `| ${r.triggers.join(", ")} | \`${r.name}\` | ${note} |`
    }),
  ].join("\n")
  replaceManaged(
    root,
    ".cursor/dots-skill-routing.md",
    "domain-routing",
    domainTable,
  )

  if (!DRY_RUN) console.log("skill sync: updated managed blocks")
}

async function install() {
  await validate({ skipDrift: true })
  if (!validateOk) process.exit(1)
  if (DRY_RUN) {
    console.log("skill install: dry-run would run skills experimental_install")
    return
  }
  const child = Bun.spawnSync(["skills", "experimental_install"], {
    cwd: gitRoot(),
    stdout: "inherit",
    stderr: "inherit",
  })
  if (child.exitCode !== 0) process.exit(child.exitCode ?? 1)
}

async function report() {
  await validate()
  const registry = await loadRegistry()
  const skills = (registry.skills ?? {}) as Record<
    string,
    Record<string, unknown>
  >
  const byLoc: Record<string, number> = {}
  const byType: Record<string, number> = {}
  let domainTotal = 0
  for (const [, s] of Object.entries(skills)) {
    const loc = String(s.location || "?")
    const t = String((s.policy as Record<string, unknown>)?.type || "?")
    byLoc[loc] = (byLoc[loc] || 0) + 1
    byType[t] = (byType[t] || 0) + 1
    const domain = isRecord(s.policy?.routing)
      ? (s.policy.routing as Record<string, unknown>).domain
      : undefined
    if (Array.isArray(domain)) domainTotal += domain.length
  }
  const data = {
    schema_version: registry.schema_version,
    total_skills: Object.keys(skills).length,
    by_location: byLoc,
    by_policy_type: byType,
    domain_routes: domainTotal,
    valid: validateOk,
    drift: drift ?? {},
  }
  if (JSON_OUT) {
    console.log(JSON.stringify(data, null, 2))
  } else {
    console.log("schema_version:", data.schema_version)
    console.log("total_skills:", data.total_skills)
    console.log("by_location:", JSON.stringify(data.by_location))
    console.log("by_policy_type:", JSON.stringify(data.by_policy_type))
    console.log("domain_routes:", data.domain_routes)
    console.log("valid:", data.valid)
    if (drift) {
      if (drift.missing.length) console.log("missing:", JSON.stringify(drift.missing))
      else if (drift.extra.length) console.log("extra:", JSON.stringify(drift.extra))
      else console.log("drift: none")
    }
  }
}

if (ACTION === "validate") {
  await validate()
  if (!validateOk) process.exit(1)
} else if (ACTION === "sync") {
  await sync()
} else if (ACTION === "install") {
  await install()
} else if (ACTION === "all") {
  await sync()
  await install()
} else if (ACTION === "report") {
  await report()
  if (!validateOk) process.exit(1)
}

if (!ok) process.exit(1)
