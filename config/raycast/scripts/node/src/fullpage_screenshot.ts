#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands/blob/master/commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Screenshot Full Page (w/ Mermaid)
// @raycast.mode fullOutput
// @raycast.packageName Screenshots
//
// Optional parameters:
// @raycast.icon 🤖
// @raycast.argument1 { "type": "text", "placeholder": "path/to/file.html" }
//
// Documentation:
// @raycast.description Capture a full-page screenshot of a local HTML file, ensuring all Mermaid graphics are fully rendered before capture.
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

import { exec } from 'child_process'
import path from 'path'
import puppeteer from 'puppeteer'

async function main(htmlFilePath: string): Promise<string> {
  const absolutePath = path.resolve(htmlFilePath);
  const fileUrl = `file://${absolutePath}`;
  const outputPath = htmlFilePath.replace('.html', '_fullpage_screenshot');

  console.log('📸 Starting full page capture...');
  console.log('🔗 URL:', fileUrl);
  console.log('💾 Saving to:', outputPath);

  try {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();

    // Configure viewport for good resolution
    await page.setViewport({
      width: 1200,
      height: 800,
      deviceScaleFactor: 2, // For better quality
    });

    // Navigate to the page
    await page.goto(fileUrl, {
      waitUntil: 'networkidle0',  // Wait for all resources to load
      timeout: 30000
    });

    // Wait for Mermaid graphics to render
    console.log('⏳ Waiting for Mermaid graphics to render...');

    try {
      // Wait for Mermaid elements to appear
      await page.waitForSelector('.mermaid svg', { timeout: 10000 });
      console.log('✅ Mermaid graphics detected!');
    } catch {
      console.log('⚠️ Some graphics may not have loaded, continuing...');
    }

    // Wait a bit more to ensure complete rendering
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Capture full page screenshot
    await page.screenshot({
      path: `${outputPath}.png`,
      fullPage: true,  // takes a screenshot of the full page
      type: 'png'
    });

    await browser.close();

    console.log('✅ Full page screenshot saved successfully!');
    console.log('📂 File:', `${outputPath}.png`);

    return `${outputPath}.png`;
  } catch (error) {
    console.error('❌ Error capturing screenshot:', error);
    throw error;
  }
}

// Check command line arguments
const htmlFile = process.argv[2];
if (!htmlFile) {
  console.error('Usage: node fullpage_screenshot.ts <file.html>');
  process.exit(1);
}

// Execute
main(htmlFile)
  .then(outputPath => {
    console.log('🚀 Process completed!');
    exec(`open "${outputPath}"`, (error) => { // Open file automatically on macOS
      if (error) {
        console.log('📁 File saved at:', outputPath);
      } else {
        console.log('🖼️ Image opened automatically!');
      }
    });
  })
  .catch(error => {
    console.error('💥 Failed:', error.message);
    process.exit(1);
  });