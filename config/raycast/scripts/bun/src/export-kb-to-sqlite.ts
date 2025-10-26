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
const main = async () => {
  const yamlSourcesPath = expandHome(process.argv[2]?.trim() || `~/.config/kb`)
  const dbPath = expandHome(process.argv[3]?.trim() || `~/.config/kb/_database.db`)
  await $`rm -rf ${dbPath} 2> /dev/null`

  puts(`(DB) Connect to ${dbPath}..`)
  const db = new Database(dbPath)
  puts(`(DB) Connect to ${dbPath} ✔︎`)

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

  return `[SQLITE-IMPORT] Files migrated to '${dbPath}' ✔︎✔︎`
}

main().then(console.log).catch(console.error)
