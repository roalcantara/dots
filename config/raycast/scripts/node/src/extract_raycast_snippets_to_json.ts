#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands/blob/master/commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Extract Raycast Snippets
// @raycast.mode fullOutput
// @raycast.packageName Raycast
//
// Optional parameters:
// @raycast.icon 🤖
// @raycast.argument1 { "type": "text", "placeholder": "path", "optional": true }
//
// Documentation:
// @raycast.description Extract Raycast Snippets as Raycast JSON format from YAML file
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

import { mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname } from 'path';
import YAML from 'yaml';

interface Snippet {
  keyword: string;
  name: string;
  text: string;
}

interface SnippetsData {
  snippets: Record<string, {
    name: string;
    text: string;
  }>;
}

/**
 * Extract Raycast Snippets from YAML file to JSON
 * @param yamlPath - The path to the YAML file. Defaults to ~/.config/kb/raycast.yml.
 * @returns void
 */
async function extractRaycastSnippets(yamlPath?: string): Promise<void> {
  try {
    // Read the YAML file
    const yamlContent = readFileSync(yamlPath ?? `${process.env.HOME || ''}/.config/kb/raycast.yml`, 'utf8');

    // Parse YAML content
    const data = YAML.parse(yamlContent) as SnippetsData;

    if (!data.snippets) {
      console.log('No snippets found in the YAML file');
      return;
    }

    // Extract snippets and convert to the required format
    const snippets: Snippet[] = Object.entries(data.snippets).map(([keyword, snippet]) => ({
      keyword,
      name: snippet.name,
      text: snippet.text
    }));

    // Define output path
    const outputPath = `${process.env.HOME || ''}/.config/raycast/snippets.json`;

    // Ensure the assets directory exists
    const assetsDir = dirname(outputPath);
    mkdirSync(assetsDir, { recursive: true });

    // Write the JSON file (this will overwrite if it already exists)
    writeFileSync(outputPath, JSON.stringify(snippets, null, 2));

    console.log(`Successfully extracted ${snippets.length} snippets to ${outputPath} (overwritten if existed)`);
  } catch (error) {
    console.error('Error extracting snippets:', error);
    process.exit(1);
  }
}

extractRaycastSnippets(process.argv[2]?.trim() || undefined);

// vi: set ft=javascript
