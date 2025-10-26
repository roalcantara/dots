#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands/blob/master/commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title My First Script
// @raycast.mode fullOutput
// @raycast.packageName Raycast Scripts
//
// Optional parameters:
// @raycast.icon 🤖
// @raycast.argument1 { "type": "text", "placeholder": "js, css, html", "optional": true}
// @raycast.argument2 { "type": "text", "placeholder": "query" }
//
// Documentation:
// @raycast.description Write a nice and descriptive summary about your script command here
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara
//
/*
	ABOUT THIS TEMPLATE:
	This template demonstrates the following ideas:
	* Extracting passed arguments.
	* Using both required and optional arguments
	* URI Encoding
	* Outputting result to Raycast
	* Opening a url using exec and the unix open command
	* Use of destructuring
	* Use of template literals
*/
const { exec } = require('child_process')

// Use destructuring to grab arguments.
// Use slice to start from position 3.
let [topic, query] = process.argv.slice(2)
let uri = `https://developer.mozilla.org/search?topic=${topic}&q=${encodeURIComponent(query)}`

// console.log() displays output in fullOutput mode.
console.log(`The arguments are: \n   ${process.argv.join('\n   ')}\n`)
console.log(`Your topic is "${topic}"`)
console.log(`Your query is "${query}"`)
console.log(`Your query uri encoded is "${encodeURIComponent(query)}"`)
console.log(`The uri is "${uri}"`)

// Uncomment the exec line below to open this query in your web browser.
// Use double quotes around the uri to avoid processing issues.
//exec(`open "${uri}"`)

// vi: set ft=javascript
