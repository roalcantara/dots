#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands/blob/master/commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title HTML List to JSON
// @raycast.mode fullOutput
// @raycast.packageName HTML Scripts
//
// Optional parameters:
// @raycast.icon 📋
// @raycast.argument1 { "type": "text", "placeholder": "marvel"}
//
// Documentation:
// @raycast.description Convert the HTML list from clipboard to JSON and paste into clipboard
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara
//

import assert from 'assert';
import { execSync } from 'child_process';

/**
 * Get the text from the clipboard
 */
const getClipboardText = async () => {
  return execSync('pbpaste', { encoding: 'utf-8' });
}

import { promises as fs } from 'fs';
import { resolve } from 'path';

type ListItem = {
  title: string;
  issueDate?: string;
  url: string;
  image: string;
}

const expectedJson: Record<'comicvine' | 'marvel', ListItem[]> = {
  comicvine: [
      {
      title: "The War of Greedy Witches #10",
      issueDate: "January 2025",
      url: "/the-war-of-greedy-witches-10/4000-1149526/",
      image: "https://comicvine.gamespot.com/a/uploads/scale_small/11/110017/9942883-ww.jpg",
    },
    {
      title: "The War of Greedy Witches #9",
      issueDate: "November 2024",
      url: "/the-war-of-greedy-witches-9/4000-1149525/",
      image: "https://comicvine.gamespot.com/a/uploads/scale_small/11/110017/9942882-www.jpg",
    },
    {
      title: "The War of Greedy Witches #8",
      issueDate: "September 2024",
      url: "/the-war-of-greedy-witches-8/4000-1149524/",
      image: "https://comicvine.gamespot.com/a/uploads/scale_small/11/110017/9942881-wwww.jpg",
    },
    {
      title: "The War of Greedy Witches #7",
      issueDate: "July 2024",
      url: "/the-war-of-greedy-witches-7/4000-1149523/",
      image: "https://comicvine.gamespot.com/a/uploads/scale_small/11/110017/9942880-1307701-isidoro.jpg",
    },
    {
      title: "The War of Greedy Witches #6",
      issueDate: "May 2024",
      url: "/the-war-of-greedy-witches-6/4000-1149522/",
      image: "https://comicvine.gamespot.com/a/uploads/scale_small/11/110017/9942879-1974746305.jpg",
    }
  ],
  marvel: [
    {
      title: "Black Panther: Intergalactic (2025) #1",
      url: "/comics/issue/126399/black_panther_intergalactic_2025_1",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/b/40/6933206864929/portrait_uncanny.jpg",
    },
    {
      title: "MARVEL RIVALS: IGNITE - IN COLOR #1 (2025) #1",
      url: "/comics/issue/133088/marvel_rivals_ignite_-_in_color_1_2025_1",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/c/00/69331ff0a0bee/portrait_uncanny.jpg",
    },
    {
      title: "Planet She-Hulk (2025) #2",
      url: "/comics/issue/122195/planet_she-hulk_2025_2",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/2/03/693320952b43a/portrait_uncanny.jpg",
    },
    {
      title: "Alien Vs. Captain America (2025) #2",
      url: "/comics/issue/129641/alien_vs_captain_america_2025_2",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/3/90/69331ff1293c4/portrait_uncanny.jpg",
    },
    {
      title: "Daredevil/Punisher: The Devil's Trigger (2025) #2",
      url: "/comics/issue/131971/daredevilpunisher_the_devils_trigger_2025_2",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/3/a0/69331fe28146c/portrait_uncanny.jpg",
    },
    {
      title: "Amazing Spider-Man: Torn (2025) #3",
      url: "/comics/issue/124712/amazing_spider-man_torn_2025_3",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/1/40/69331ff125997/portrait_uncanny.jpg",
    },
    {
      title: "Strange Tales (2025) #3",
      url: "/comics/issue/128456/strange_tales_2025_3",
      image: "https://cdn.marvel.com/u/prod/marvel/i/mg/1/03/693320a3c7731/portrait_uncanny.jpg",
    }
  ]
}

const readHtmlFixtureFile = async (source: 'comicvine' | 'marvel') => {
  const filePath = resolve(`src/assets/fixtures/${source}.html`);
  return fs.readFile(filePath, 'utf-8');
}

/**
 * Decode HTML entities
 */
const decodeHtmlEntities = (text: string): string => {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
};

/**
 * Extract text content from HTML tag
 */
const extractTextContent = (html: string, tagPattern: RegExp): string => {
  const match = html.match(tagPattern);
  if (!match || !match[1]) return '';

  // Remove nested HTML tags and decode entities
  return decodeHtmlEntities(match[1].replace(/<[^>]+>/g, ''));
};

/**
 * Extract attribute value from HTML tag
 */
const extractAttribute = (html: string, tagPattern: RegExp, attrName: string): string => {
  const match = html.match(tagPattern);
  if (!match) return '';

  // Extract attribute value using regex
  const attrRegex = new RegExp(`${attrName}=["']([^"']+)["']`, 'i');
  const attrMatch = match[0].match(attrRegex);
  return attrMatch && attrMatch[1] ? attrMatch[1] : '';
};

const extractFromList = (html: string) => {

  // Extract list items from HTML
  interface ListItem {
    title: string;
    issueDate: string;
    url: string;
    image: string;
  }

  const listItems: ListItem[] = [];

  // Match <li> tags and extract their content
  const liRegex = /<li[^>]*>(.*?)<\/li>/gis;
  let match;

  while ((match = liRegex.exec(html)) !== null) {
    const liContent = match[1];
    if (!liContent) continue;

    // Extract URL from <a href="...">
    const url = extractAttribute(liContent, /<a[^>]+href=["'][^"']*["'][^>]*>/i, 'href');

    // Extract image URL from <img src="...">
    const image = extractAttribute(liContent, /<img[^>]+>/i, 'src');

    // Extract title from <h3 class="title">...</h3>
    const title = extractTextContent(liContent, /<h3[^>]*class=["']title["'][^>]*>(.*?)<\/h3>/is);

    // Extract issue date from <p class="issue-date">...</p>
    const issueDate = extractTextContent(liContent, /<p[^>]*class=["']issue-date["'][^>]*>(.*?)<\/p>/is);

    if (title && issueDate && url && image) {
      listItems.push({ title, issueDate, url, image });
    }
  }

  return listItems;
}

const extractFromMarvel = (html: string) => {
  const listItems: ListItem[] = [];

  // Marvel uses <div class="ComicCard"> structure
  // Match each ComicCard div (non-greedy to get individual cards)
  const cardRegex = /<div class="ComicCard[^"]*"[^>]*>(.*?)<\/div>\s*<\/div>\s*<\/div>/gis;
  let match;

  while ((match = cardRegex.exec(html)) !== null) {
    const cardContent = match[1];
    if (!cardContent) continue;

    // Extract URL from the first <a> tag with ComicCard__Link class (the image link)
    const linkMatch = cardContent.match(/<a[^>]*class=["'][^"']*ComicCard__Link[^"']*["'][^>]*href=["']([^"']+)["']/i);
    const url = linkMatch ? linkMatch[1] : '';

    // Extract image URL from <img src="...">
    const imageMatch = cardContent.match(/<img[^>]+src=["']([^"']+)["'][^>]*>/i);
    const image = imageMatch ? imageMatch[1] : '';

    // Extract title from <p class="ComicCard__Meta__Title"><a>...</a></p>
    const titleMatch = cardContent.match(/<p[^>]*class=["']ComicCard__Meta__Title["'][^>]*>.*?<a[^>]*>(.*?)<\/a>.*?<\/p>/is);
    let title = titleMatch ? titleMatch[1] : '';
    // Clean up title - remove extra whitespace and decode entities
    if (title) {
      title = decodeHtmlEntities(title.replace(/\s+/g, ' ').trim());
    }

    // Issue date is not in the HTML, but expected JSON shows "January 2025" for all
    // const issueDate = "January 2025";

    if (title && url && image) {
      listItems.push({ title, url, image });
    }
  }
  return listItems;
}

/**
 * Convert the HTML list from clipboard to JSON
 */
const main = async (source: 'comicvine' | 'marvel', fn: () => Promise<string>) => {
  const html = await fn();
  console.log(`main(${source}) HTML ------>\n\n`, html);

  if (source === 'comicvine') {
    return extractFromList(html);
  }

  return extractFromMarvel(html);
}

// Parse command line arguments
// Handle both --source=marvel and --source marvel formats
let source: 'comicvine' | 'marvel' | null = null;
if (process.argv.includes('comicvine')) {
  source = 'comicvine';
} else if (process.argv.includes('marvel')) {
  source = 'marvel';
}

if (!source || (source !== 'comicvine' && source !== 'marvel')) {
  console.error(`Invalid source: ${source}. Must be 'comicvine' or 'marvel'`, {
    source: process.argv,
  });
  process.exit(1);
}

if (process.argv.includes('--test')) {
  main(source, () => readHtmlFixtureFile(source!)).catch(console.error).then((res) => {
    console.log(JSON.stringify(res, null, 2));
    const expected = expectedJson[source];
    assert(JSON.stringify(res, null, 2) === JSON.stringify(expected, null, 2), 'JSON does not match expected value');
    return res;
  });
} else {
  main(source, getClipboardText).catch(console.error).then((res) => {
    // paste it into the clipboard
    console.log('Copying to clipboard ------>\n\n', JSON.stringify(res, null, 2));
    execSync('pbcopy', { input: JSON.stringify(res, null, 2), encoding: 'utf-8' });
    return res;
  });
}
