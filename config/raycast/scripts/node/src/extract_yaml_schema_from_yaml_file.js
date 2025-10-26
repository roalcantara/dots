#!/usr/bin/env node

// Raycast Script Command: Javascript (requires Nodejs)
// https://github.com/raycast/script-commands
// SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.js
// ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
// OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
//
// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Extract YAML Schema from YAML File
// @raycast.mode fullOutput
// @raycast.packageName Raycast Scripts
//
// Optional parameters:
// @raycast.icon ⌨️
//
// Documentation:
// @raycast.description Extract the YAML schema from a YAML file.
// @raycast.author roalcantara
// @raycast.authorURL https://github.com/roalcantara

// USAGE:
// node extract_yaml_schema_from_yaml_file.js (from clipboard by default)
// node extract_yaml_schema_from_yaml_file.js <path-to-yaml-file>

// YAML Schema Generator
// This script takes a sample YAML file and generates a schema for it

const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');

function inferType(value) {
  if (value === null) return { type: 'null' };
  if (Array.isArray(value)) {
    if (value.length === 0) return { type: 'array' };
    // Infer the type of array items
    const itemSchemas = value.map(inferType);
    // Simplify if all items are the same type
    const allSameType = itemSchemas.every(schema =>
      JSON.stringify(schema) === JSON.stringify(itemSchemas[0])
    );
    return {
      type: 'array',
      items: allSameType ? itemSchemas[0] : { anyOf: itemSchemas }
    };
  }
  if (typeof value === 'object') {
    const properties = {};
    const required = [];

    for (const [key, val] of Object.entries(value)) {
      properties[key] = inferType(val);
      required.push(key);
    }

    return {
      type: 'object',
      properties,
      required,
      additionalProperties: false
    };
  }

  return { type: typeof value };
}

function generateSchema(yamlData, title = 'YAML Schema') {
  const schema = {
    $schema: 'http://json-schema.org/draft-07/schema#',
    title,
    ...inferType(yamlData)
  };

  return schema;
}

function generate_schema_from_filepath(yamlFilePath = process.argv[2]) {
  if (!yamlFilePath) {
    console.error('Please provide a YAML file path');
    process.exit(1);
  }

  try {
    const yamlContent = fs.readFileSync(yamlFilePath, 'utf8');
    const yamlData = yaml.load(yamlContent);

    const schema = generateSchema(yamlData, path.basename(yamlFilePath, path.extname(yamlFilePath)));

    // Output schema as YAML
    const schemaYaml = yaml.dump(schema);
    const outputPath = yamlFilePath + '.schema.yaml';
    fs.writeFileSync(outputPath, schemaYaml);

    console.log(`Schema generated and saved to ${outputPath}`);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

function generate_schema_from_clipboard(yamlContent = clipboard.readText()) {
  const schema = generateSchema(yamlContent);
  console.log(schema);
}

function generate_schema_from_clipbord_or_filepath() {
  const yamlFilePath = process.argv[2];
  if (yamlFilePath) {
    generate_schema_from_filepath(yamlFilePath);
  } else {
    generate_schema_from_clipboard();
  }
}

generate_schema_from_clipbord_or_filepath();
