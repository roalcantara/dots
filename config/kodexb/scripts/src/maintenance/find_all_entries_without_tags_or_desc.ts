// GOAL: Find all entries without tags or desc (which are required fields)
import type { Bookmark, Cheat, Command, Entry, SourceFile } from '../types/index.ts';

import { readdir } from "node:fs/promises";

const checkForRequiredFields = (entry: Bookmark | Command | Cheat) => {
  if (!entry.tags) {
    return false;
  }
  if (!entry.desc) {
    return false;
  }
  return true;
};

export const main = async () => {
  const files = await readdir(`${process.env.HOME}/.config/kodexb/sources`)

  const results = [];

  for (const file of files) {
    if (file.endsWith('.yml')) {
      const file_path = `${process.env.HOME}/.config/kodexb/sources/${file}`
      // const file_content = await Bun.file(file_path).text()
      // const source_file = YAML.parse(file_content) as SourceFile;
      const source_file = (await import(`${file_path}`)).default as SourceFile;
      // console.log({ file_path, source_file });
      const result = Object.entries(source_file).reduce((acc, [key, value]) => {
        if (key === 'bookmarks' || key === 'commands' || key === 'cheats') {
          Object.entries(value).forEach(([k, v]) => {
            if (v === null || v === undefined) {
              return acc
            }
            // console.log({ k, v });

            if (!('tags' in v)) {
              if (!acc.missingTags[key]) {
                acc.missingTags[key] = [];
              }
              acc.missingTags[key].push(`${(v as unknown as Entry).desc} (${file_path})`);
            }
            if (!('desc' in v)) {
              if (!acc.missingDesc[key]) {
                acc.missingDesc[key] = [];
              }
              acc.missingDesc[key].push(JSON.stringify(v as unknown as Entry));
            }
          });
        }
        return acc;
      }, { missingTags: {} as Record<string, string[]>, missingDesc: {} as Record<string, string[]> });
      results.push(result);
    } else {
      console.warn(`${file} is not a YAML file`, { file });
    }
  }

  return results
};

main().catch(console.error).then(console.log)
