#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Extract VS Code Keybindings
// @raycast.mode fullOutput
// @raycast.packageName Raycast Scripts
//
// Optional parameters:
// @raycast.icon ⌨️
//
// Documentation:
// @raycast.description Export your custom VS Code keybindings to different formats.
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

// USAGE:
// node extract_vscode_keybindings.js (json by default)
// node extract_vscode_keybindings.js json
// node extract_vscode_keybindings.js csv
// node extract_vscode_keybindings.js markdown
// node extract_vscode_keybindings.js html

import { readFileSync } from "fs";
import { join } from "path";
import { homedir as _homedir } from "os";
import { get } from 'https';

export const vscode_keybindings_extractor_helper = {
  /**
   * Promisify https.get request
   * @param {string} url - The URL to fetch from
   * @returns {Promise<string>} The response data
   */
  httpsGet: async (url) => {
    return new Promise((resolve, reject) => {
      get(url, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => resolve(data));
      }).on('error', reject);
    });
  },

  /**
   * Fetch JSON from a URL using async/await
   * @param {string} url - The URL to fetch from
   * @returns {Promise<Object>} The parsed JSON data
   */
  fetchJson: async (url) => {
    try {
      const data = await vscode_keybindings_extractor_helper.httpsGet(url);
      const jsonData = data.replace(/\\"|"(?:\\"|[^"])*"|(\/\/.*|\/\*[\s\S]*?\*\/)/g, (m, g) => g ? "" : m);
      return JSON.parse(jsonData);
    } catch (error) {
      throw new Error(`Failed to fetch JSON from ${url}: ${error.message}`);
    }
  },

  /**
   * Get default VS Code keybindings by fetching from GitHub repository
   * @returns {Promise<Array>} The combined keybindings
   */
  get_default_vscode_keybindings: async (platform = process.platform, baseUrl = 'https://raw.githubusercontent.com/codebling/vs-code-default-keybindings/refs/heads/master') => {
    let mainFile, negativeFile;

    switch (platform) {
      case 'darwin':
        mainFile = `${baseUrl}/macos.keybindings.json`;
        negativeFile = `${baseUrl}/macos.negative.keybindings.json`;
        break;
      case 'linux':
        mainFile = `${baseUrl}/linux.keybindings.json`;
        negativeFile = `${baseUrl}/linux.negative.keybindings.json`;
        break;
      case 'win32':
        mainFile = `${baseUrl}/windows.keybindings.json`;
        negativeFile = `${baseUrl}/windows.negative.keybindings.json`;
        break;
      default:
        throw new Error('Unsupported platform');
    }

    try {
      const [mainKeybindings, negativeKeybindings] = await Promise.all([
        vscode_keybindings_extractor_helper.fetchJson(mainFile),
        vscode_keybindings_extractor_helper.fetchJson(negativeFile)
      ]);

      // Merge both keybindings arrays
      return [...mainKeybindings, ...negativeKeybindings];
    } catch (error) {
      console.error('Error fetching default keybindings:', error);
      return [];
    }
  },

  /**
   * Find the VS Code keybindings file
   *
   * This function finds the keybindings file for VS Code based on the operating system.
   *
   * @returns {string} The path to the keybindings file.
   */
  find_vscode_keybindings_file: (platform = process.platform, homedir = _homedir()) => {
    // Default paths based on OS
    if (platform === "win32") {
      return join(
        homedir,
        "AppData",
        "Roaming",
        "Code",
        "User",
        "keybindings.json",
      );
    }

    if (platform === "darwin") {
      return join(
        homedir,
        "Library",
        "Application Support",
        "Code",
        "User",
        "keybindings.json",
      );
    }

    if (platform === "linux") {
      return join(
        homedir,
        ".config",
        "Code",
        "User",
        "keybindings.json",
      );
    }

    return null;
  },

  /**
   * Find VS Code keybindings
   *
   * This function reads the keybindings from the given path and parses them as JSON.
   * If the file doesn't exist or is empty, returns an empty array.
   *
   * @param {string} keybindingsPath - The path to the keybindings file.
   * @returns {Array} The parsed keybindings or empty array if file doesn't exist.
   */
  find_vscode_keybindings: (keybindingsPath) => {
    try {
      const rawData = readFileSync(keybindingsPath, "utf8");
      if (!rawData.trim()) {
        return [];
      }

      // Remove any potential comments from the JSON
      const jsonData = rawData.replace(/\\"|"(?:\\"|[^"])*"|(\/\/.*|\/\*[\s\S]*?\*\/)/g, (m, g) => g ? "" : m);
      return JSON.parse(jsonData);
    } catch (error) {
      console.warn(`Warning: Could not parse keybindings from ${keybindingsPath}:`, error.message);
      return [];
    }
  },
}

/**
 * Export keybindings to different formats
 *
 * This function exports the keybindings to different formats.
 *
 * @param {string} format - The format to export the keybindings to.
 */
export const extract_vscode_keybindings = async (format = "json", platform = process.platform, homedir = _homedir()) => {
  try {
    // Find keybindings file
    const keybindingsPath = vscode_keybindings_extractor_helper.find_vscode_keybindings_file(platform, homedir);

    // Read custom keybindings
    const customKeybindings = vscode_keybindings_extractor_helper.find_vscode_keybindings(keybindingsPath);

    // Get default keybindings
    const defaultKeybindings = await vscode_keybindings_extractor_helper.get_default_vscode_keybindings(platform);

    // Combine keybindings
    const allKeybindings = [...defaultKeybindings, ...customKeybindings];

    // Export based on format
    switch (format.toLowerCase()) {
      case "json":
        return JSON.stringify(allKeybindings, null, 2)

      case "csv":
        const csvHeader = "key,command,when\n";
        const csvContent = allKeybindings
          .map(
            (kb) =>
              `"${kb.key || ""}","${kb.command || ""}","${kb.when || ""}"`,
          )
          .join("\n");

        return csvHeader + csvContent

      case "markdown":
        const mdHeader =
          "# VS Code Keybindings\n\n| Key | Command | When |\n| --- | --- | --- |\n";
        const mdContent = allKeybindings
          .map(
            (kb) =>
              `| \`${kb.key || ""}\` | \`${kb.command || ""}\` | \`${kb.when || ""}\` |`,
          )
          .join("\n");

        return mdHeader + mdContent

      case "html":
        const htmlContent = `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>VS Code Keybindings</title>
                    <style>
                        body { font-family: Arial, sans-serif; margin: 20px; }
                        table { border-collapse: collapse; width: 100%; }
                        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                        th { background-color: #f2f2f2; }
                        tr:nth-child(even) { background-color: #f9f9f9; }
                    </style>
                </head>
                <body>
                    <h1>VS Code Keybindings</h1>
                    <table>
                        <tr>
                            <th>Key</th>
                            <th>Command</th>
                            <th>When</th>
                        </tr>
                        ${allKeybindings
                          .map(
                            (kb) => `
                        <tr>
                            <td><code>${kb.key || ""}</code></td>
                            <td><code>${kb.command || ""}</code></td>
                            <td><code>${kb.when || ""}</code></td>
                        </tr>
                        `,
                          )
                          .join("")}
                    </table>
                </body>
                </html>
                `;

        return htmlContent

      default:
        console.error("Unsupported format. Use json, csv, markdown, or html.");
    }
  } catch (error) {
    console.error("Error exporting keybindings:", error.message);

    if (error.code === "ENOENT") {
      console.error("Keybindings file not found at:", keybindingsPath);
      console.error(
        "You may need to adjust the path for your VS Code installation.",
      );
    }
  }
}

extract_vscode_keybindings(process.argv[2] || "json")
  .then(console.log)
  .catch(error => {
    console.error("Error:", error);
    process.exit(1);
  });

// vi: set ft=javascript
