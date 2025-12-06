#!/usr/bin/env bun

// Raycast Script Command: BUN
// https://github.com/raycast/script-commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.sh
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Export KB to SQLite
// @raycast.mode fullOutput
// @raycast.packageName Common Scripts
//
// Optional parameters:
// @raycast.icon 🤖
// @raycast.currentDirectoryPath ~
// @raycast.needsConfirmation false
//
// Documentation:
// @raycast.description Export KB to SQLite
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

import { $ } from 'bun'
import { Database } from 'bun:sqlite'
import { readdir } from 'node:fs/promises'

const typeByKey = {
  bookmarks: 'Bookmark',
  commands: 'Command',
  cheats: 'Cheat'
} as const
const typeToColumn = {
  Bookmark: 'url',
  Command: 'cmd',
  Cheat: 'cheat'
} as const
const expandHome = (path: string) => {
  if (path.startsWith('~')) {
    return path.replace('~', process.env.HOME || process.env.USERPROFILE || '')
  }
  return path
}
const puts = (...args: any[]) => {
  console.log('[SQLITE-IMPORT] ', ...args)
}
const createTables = async (db: Database) => {
  db.run(`
  CREATE TABLE IF NOT EXISTS knowledges (
    id INTEGER PRIMARY KEY,
    type TEXT NOT NULL,
    desc TEXT NOT NULL,
    title TEXT NOT NULL,
    tags TEXT NOT NULL,
    source TEXT NOT NULL,
    links TEXT,
    notes TEXT,
    url TEXT,
    cmd TEXT,
    cheat TEXT
  );
`)
  puts('(DB) CREATE TABLE IF NOT EXISTS knowledges ✔︎')
  db.run(`
  CREATE VIRTUAL TABLE IF NOT EXISTS entries USING FTS5(
    type, desc, title, tags, links, source, url, cmd, cheat, notes,
    content='knowledges', content_rowid='id'
  );
`)
  puts('(DB) CREATE VIRTUAL TABLE IF NOT EXISTS entries ✔︎')
}
const insert = async (db: Database, allEntries: any[]) => {
  puts(`(DB) INSERT ${allEntries.length} into knowledges and entries..`)

  const insertKnowledges = db.prepare(`
  INSERT INTO knowledges (type, desc, title, tags, links, source, url, cmd, cheat, notes)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)

  // We'll use this to rebuild the FTS index after inserting all data
  const rebuildFtsIndex = db.prepare(
    `INSERT INTO entries(entries) VALUES('rebuild')`
  )

  db.transaction(() => {
    for (const entry of allEntries) {
      try {
        insertKnowledges.run(
          entry.type,
          entry.desc,
          entry.title,
          entry.tags,
          entry.links,
          entry.source,
          entry.url,
          entry.cmd,
          entry.cheat,
          entry.notes
        )
      } catch (e) {
        console.error(e)
        console.error(entry)
      }
    }

    // Rebuild the FTS index after all content has been inserted
    rebuildFtsIndex.run()
  })()
  puts(`(DB) INSERT ${allEntries.length} knowledges and entries ✔︎`)
}
const parse = async (filePath?: string) => {
  if (!Bun.file(filePath || '').exists()) {
    console.error(`Error: File not found at ${filePath}`);
    process.exit(1);
  }

  puts(`(PARSE) item '${filePath}'..`)
  if (!filePath?.endsWith('.yml') && !filePath?.endsWith('.yaml')) return []

  const doc = Bun.YAML.parse(await Bun.file(filePath).text()) as Record<string, any>
  const allEntries: any[] = []

  for (const [typeKey, entries] of Object.entries(doc)) {
    const type = typeByKey[typeKey as keyof typeof typeByKey]
    if (!type) continue

    for (const [value, entryRaw] of Object.entries(
      entries as Record<string, any>
    )) {
      const entry = entryRaw as any
      allEntries.push({
        ...entry,
        type,
        title: value,
        [typeToColumn[type]]: value,
        source: filePath.split('/').pop(),
        tags: JSON.stringify(entry.tags || []),
        links: JSON.stringify(entry.links || []),
        notes: JSON.stringify(entry.notes || [])
      })
    }
  }
  puts(`(PARSE) file '${filePath}' => ${allEntries.length} entries ✔︎`)
  return allEntries
}
const migrate = async (db: Database, filePath: string) => {
  const allEntries = await parse(filePath)
  await insert(db, allEntries)
}

const extract_kb_paths = () => {
  const yamlSourcesPath = expandHome(process.argv[3]?.trim() || `~/.config/kb`)
  puts(`(KB/PATHS) yamlSourcesPath: '${yamlSourcesPath}' ✔︎`)
  const dbPath = expandHome(process.argv[4]?.trim() || `~/.config/kb/_database.db`)
  puts(`(KB/PATHS) dbPath: '${dbPath}' ✔︎`)
  const assetsPath = expandHome(process.argv[5]?.trim() || `~/.config/kb/_assets`)
  puts(`(KB/PATHS) assetsPath: '${assetsPath}' ✔︎`)

  return {
    yamlSourcesPath,
    dbPath,
    assetsPath
  }
}

/**
 * Each DB item has a tags field that is an array of strings.
 * Each tag of the array the strings has a file at ~/.config/kb/_assets/tag.svg
 * This functions finds all tags that do not have a corresponding file at ~/.config/kb/_assets/tag.svg
 * @param db - The SQLite database
 * @returns A promise that resolves to a string[]
 */
const extract_missing_kb_assets = async () => {
  const { dbPath, assetsPath } = extract_kb_paths()
  const db = new Database(dbPath)
  const tags: any[] = db.query(`SELECT json_each.value as tag FROM entries as e, json_each(e.tags)`).all()
  const missingTags: string[] = Array.from(new Set(tags.map((row: any) => row.tag.toLowerCase()))).sort((a: string, b: string) => a.localeCompare(b))
  const missingTagsAssets: string[] = (await Promise.all(missingTags.map(async (tag: string) => {
    if (!await Bun.file(`${assetsPath}/${tag}.svg`).exists()) {
      return tag
    }
    return null
  })) ?? []).filter((item: string | null) => item !== null)
  puts(`(ASSETS) missingTagsAssets (${missingTagsAssets.length}): ${JSON.stringify(missingTagsAssets, null, 2)} ✔︎`)
  db.close()
  return missingTagsAssets
}

/**
 * Export KB to SQLite
 * @param yamlSourcesPath - The path to the YAML files
 * @param dbPath - The path to the SQLite database
 * @returns A promise that resolves to a string
 */
const extract_kb_db = async () => {
  const { yamlSourcesPath, dbPath } = extract_kb_paths()
  await $`rm -rf ${dbPath} 2> /dev/null`
  const db = new Database(dbPath)
  await createTables(db)

  if ((await Bun.file(yamlSourcesPath).stat()).isDirectory()) {
    puts(`(PARSE) directory '${yamlSourcesPath}'..`)
    const files = await readdir(yamlSourcesPath)
    const total = files.length
    let i = 0
    for (const file of files) {
      puts(`[${i + 1}/${total}] exporting '${file}'..`)
      await migrate(db, `${yamlSourcesPath}/${file}`)
      i++
      puts(`[${i}/${total}] exported '${file}' ✔︎`)
    }
  } else {
    await migrate(db, yamlSourcesPath)
  }
  db.close()
  return `[SQLITE-IMPORT] Files migrated to '${dbPath}' ✔︎✔︎`
}

/**
 * Main function that either creates the KB table or extracts missing assets from the DB item tags depending on the given command line arguments
 * @example `bun src/export-kb-to-sqlite.ts --db` -> Excludes, extracts and creates the KB table
 * @example `bun src/export-kb-to-sqlite.ts --assets` -> Extracts and returns a list of missing assets from the DB item tags
 * @returns A promise that resolves to a string
 */
const main = async () => {
  if (process.argv.includes('--db')) {
    puts('(MAIN) Extracting KB database..')
    return await extract_kb_db()
  } else if (process.argv.includes('--assets')) {
    puts('(MAIN) Extracting missing KB assets..')
    const missingAssets = extract_missing_kb_assets()
    return JSON.stringify(missingAssets, null, 2)
  } else {
    console.error('Invalid command line argument')
    process.exit(1)
  }
}

main().then(console.log).catch(console.error)
