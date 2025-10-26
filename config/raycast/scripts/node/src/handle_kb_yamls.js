#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Handle Knowledge Base YAMLs
// @raycast.mode fullOutput
// @raycast.packageName Raycast Scripts
//
// Optional parameters:
// @raycast.icon 🔄
// @raycast.packageName Knowledge Base
// @raycast.argument1 { "type": "text", "placeholder": "~/.config/kb", optional": true }
//
// Documentation:
// @raycast.description Unify the Knowledge database entries and tags from YAML files into JSON files and optionally remove duplicates
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

// USAGE:
// node handle_kb_yamls.js ~/.config/kb

/**
 * Unify the Knowledge database entries and tags from YAML files into JSON files and optionally remove duplicates
 * @param dirPath The path to the directory where the YAML files are located
 * @description
 * 1. Receives the path to the directory where the YAML files are located. If the path does not exist, it creates it.
 * 2. If .bak directory already exist in the directory, deletes it; Creates a .bak directory in the directory.
 * 3. Create temp files in the directory:
 *    - If _next.json file already exist in the directory, deletes it; Creates a _next.json file in the directory.
 *    - If _next_tags.json file already exist in the directory, deletes it; Creates a _next_tags.json file in the directory.
 * 4. Loads all YAML files in the directory
 * 5. For each loaded YAML file:
 *    5.1 Parses the YAML file into KnowledgeBase Entries
 *      - if the YAML file has a field called bookmarks:
 *        - parses each entry into Bookmarks where the entry key is the Bookmark's url attribute
 *        - loads the entry tags
 *      - if the YAML file has a field called commands:
 *        - parses each entry into Commands where the entry key is the Command's cmd attribute
 *        - loads the entry tags
 *      - if the YAML file has a field called cheats:
 *        - parses each entry into Cheats where the entry key is the Cheat's cheat attribute
 *        - loads the entry tags
 *    5.2 Appends the loaded entires to the _next.json file
 *    5.3 Appends the loaded tags to the _next_tags.json file
 * 6. Backup
 *   - If _all.json file already exist in the directory, moves it to .bak/_all_DDMMYYYYhhmmss.json in the same directory where DDMMYYYYhhmmss is the current date and time
 *   - If _tags.json file already exist in the directory, moves it to .bak/_tags_DDMMYYYYhhmmss.json in the same directory where DDMMYYYYhhmmss is the current date and time
 * 7. New files:
 *  - Renames the _next.json to _all.json
 *  - Renames the _next_tags.json to _tags.json
 * 8. Notifies the user of the success of the refresh
 */

import {
  existsSync,
  mkdirSync,
  renameSync,
  readdirSync,
  unlinkSync,
  writeFileSync,
  promises as fsPromises,
} from "node:fs";
import { join } from "node:path";
import { parse } from "yaml";
import { fileURLToPath } from "node:url";

// If running as a module
const __filename = fileURLToPath(import.meta.url);

const ENTRY_PROPS = {
  bookmarks: { type: "Bookmark", prop: "url" },
  commands: { type: "Command", prop: "cmd" },
  cheats: { type: "Cheat", prop: "cheat" },
};
const ENTRY_TYPES = Object.entries(ENTRY_PROPS).map(([key]) => key);
export const FILE_NAMES = {
  next: "_next.json",
  nextTags: "_next_tags.json",
  current: "_all.json",
  currentTags: "_tags.json",
};

const initializeDirectory = (dirPath) => {
  if (!existsSync(dirPath)) {
    mkdirSync(dirPath, { recursive: true });
    console.info(`Directory '${dirPath}' created ✓`);
  }
  const filePaths = {
    next: join(dirPath, FILE_NAMES.next),
    nextTags: join(dirPath, FILE_NAMES.nextTags),
    current: join(dirPath, FILE_NAMES.current),
    currentTags: join(dirPath, FILE_NAMES.currentTags),
  };
  for (const path of [filePaths.next, filePaths.nextTags]) {
    if (existsSync(path)) {
      unlinkSync(path);
    }
    writeFileSync(path, JSON.stringify([], null, 2));
  }
  console.info(
    `Initialized '${FILE_NAMES.next}' and '${FILE_NAMES.nextTags}' ✓`,
  );
  return filePaths;
};

const backup = (dirPath, filePaths) => {
  const now = new Date();
  const timestamp = now.toISOString().replace(/[:.]/g, "").slice(0, 14);
  const bakDir = join(dirPath, ".bak");
  if (!existsSync(bakDir)) {
    mkdirSync(bakDir, { recursive: true });
  }
  for (const [key, currentPath] of Object.entries({
    current: filePaths.current,
    currentTags: filePaths.currentTags,
  })) {
    if (existsSync(currentPath)) {
      const currentName = FILE_NAMES[key];
      const backupName = `${currentName.replace(".json", "")}_${timestamp}.json`;
      const backupPath = join(bakDir, backupName);
      renameSync(currentPath, backupPath);
      console.info(`[KB] (${currentName}) moved to .bak/'${backupName}' ✓`);
    }
  }
  renameSync(filePaths.next, filePaths.current);
  console.info(
    `[KB] (${FILE_NAMES.next}) renamed to '${FILE_NAMES.current}' ✓`,
  );
  renameSync(filePaths.nextTags, filePaths.currentTags);
  console.info(
    `[KB] (${FILE_NAMES.nextTags}) renamed to '${FILE_NAMES.currentTags}' ✓`,
  );
};

const report = (duplicates, entries, tagCount) => {
  const totalDuplicates = Object.values(duplicates).length;
  const totalTags = Object.keys(tagCount).length;
  console.info(
    `[KB] (${entries.length}) entries loaded with '${totalTags}' tags and '${totalDuplicates}' duplications!`,
  );
  if (totalDuplicates > 0) {
    console.info(
      "<DUPLICATES> ===========================================================",
    );
    Object.entries(duplicates).forEach(([key, sources]) => {
      console.info(`[${key}] ${sources.length}`);
      sources.forEach((source) => {
        console.info(`  - '${key}' (${source})`);
      });
    });
    console.info(
      "</DUPLICATES> ==========================================================",
    );
  }
};

// Replace Bun.file with Node.js fs.promises
const readFileAsync = async (path) => {
  try {
    return await fsPromises.readFile(path, "utf8");
  } catch (error) {
    console.error(`Error reading file: ${path}`, error);
    return "";
  }
};

const extract_entries_from_yamls = async (dirPath) => {
  const tagCount = {};
  const duplicates = {};
  const yamlfiles = readdirSync(dirPath).filter(
    (file) => file.endsWith(".yml") || file.endsWith(".yaml"),
  );

  let yamlfile = {};

  for (const fileName of yamlfiles) {
    try {
      const filePath = join(dirPath, fileName);
      const content = await readFileAsync(filePath);

      if (content.length > 0) {
        const yaml_file = parse(content);
        Object.entries(yaml_file).forEach(([collection, items]) => {
          const countItems = Object.keys(items ?? {}).length;
          const collectionType = collection;
          console.info(
            `[KB] (${fileName}/${collection}): ${countItems} => ${ENTRY_TYPES.includes(collectionType)}`,
          );

          if (ENTRY_TYPES.includes(collectionType) && countItems > 0) {
            const type = collectionType;
            const entries = items;

            Object.entries(entries).forEach(([key, item]) => {
              console.info(`[KB] (${fileName}) ${collection}: ${key}...`);

              if (!(key in yamlfile)) {
                const { type: typeName, prop } = ENTRY_PROPS[type];
                const entry = {
                  ...item,
                  [prop]: key,
                  type: typeName,
                  source: fileName,
                };
                yamlfile[key] = entry;
                console.info(`[KB] (${fileName}) ${collection}: ${key}... ✓`);

                if (item.tags && Array.isArray(item.tags)) {
                  (item.tags ?? []).forEach((tag) => {
                    tagCount[tag] = (tagCount[tag] || 0) + 1;
                  });
                }
              } else {
                duplicates[key] = duplicates[key] || [];
                duplicates[key].push(fileName);
                console.info(`[KB] (${fileName}) ${collection}: ${key}... ✗`);
              }
            });
          }
        });
      }
    } catch (error) {
      console.error(`Error processing ${fileName}:`, error);
    }
  }

  return { entries: Object.values(yamlfile), tagCount, duplicates };
};

const formatTagCounts = (tagCounts) => {
  return Object.entries(tagCounts)
    .map(([tag, total]) => ({ tag, total }))
    .sort((a, b) => a.tag.localeCompare(b.tag));
};

// Replace Bun.write with Node.js fs.promises.writeFile
const writeFileAsync = async (path, content) => {
  try {
    await fsPromises.writeFile(path, content);
  } catch (error) {
    console.error(`Error writing to file: ${path}`, error);
    throw error;
  }
};

const main = async (dirPath) => {
  const filePaths = initializeDirectory(dirPath);
  const { entries, tagCount, duplicates } =
    await extract_entries_from_yamls(dirPath);
  const formattedTagCounts = formatTagCounts(tagCount);

  await writeFileAsync(filePaths.next, JSON.stringify(entries, null, 2));
  await writeFileAsync(
    filePaths.nextTags,
    JSON.stringify(formattedTagCounts, null, 2),
  );

  backup(dirPath, filePaths);
  report(duplicates, entries, tagCount);
};

// Check if this is being run directly
const isMainModule = process.argv[1] === fileURLToPath(import.meta.url);

if (isMainModule) {
  const args = process.argv.slice(2);
  let dirPath = join(process.env.HOME || "~", ".config/kb");

  // Find path argument
  const pathFlagIndex = args.findIndex(
    (arg) => arg === "--path" || arg === "-p",
  );
  if (pathFlagIndex !== -1 && pathFlagIndex < args.length - 1) {
    dirPath = args[pathFlagIndex + 1];
  } else if (args.length > 0 && !args[0].startsWith("-")) {
    // First non-flag argument is treated as path
    dirPath = args[0];
  }

  // Handle home directory expansion
  if (dirPath.startsWith("~")) {
    dirPath = dirPath.replace("~", process.env.HOME || "~");
  }

  main(dirPath).catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });
}
