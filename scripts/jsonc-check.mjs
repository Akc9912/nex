#!/usr/bin/env node
/**
 * Validate a JSONC file: strip // and /* *\/ comments and trailing commas,
 * then JSON.parse. Comments inside strings are preserved correctly.
 *
 * Usage: node scripts/jsonc-check.mjs <file>...
 */
import { readFileSync } from "node:fs";

function stripComments(input) {
  let out = "";
  let i = 0;
  let inString = false;
  let escaped = false;
  while (i < input.length) {
    const ch = input[i];
    const next = input[i + 1];
    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      i++;
      continue;
    }
    if (ch === '"') {
      inString = true;
      out += ch;
      i++;
      continue;
    }
    if (ch === "/" && next === "/") {
      while (i < input.length && input[i] !== "\n") i++;
      continue;
    }
    if (ch === "/" && next === "*") {
      i += 2;
      while (i < input.length && !(input[i] === "*" && input[i + 1] === "/")) {
        if (input[i] === "\n") out += "\n";
        i++;
      }
      i += 2;
      continue;
    }
    out += ch;
    i++;
  }
  return out;
}

function stripTrailingCommas(input) {
  let out = "";
  let i = 0;
  let inString = false;
  let escaped = false;
  while (i < input.length) {
    const ch = input[i];
    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      i++;
      continue;
    }
    if (ch === '"') { inString = true; out += ch; i++; continue; }
    if (ch === ",") {
      let j = i + 1;
      while (j < input.length && /\s/.test(input[j])) j++;
      if (input[j] === "}" || input[j] === "]") {
        i++; // drop comma, keep whitespace
        continue;
      }
    }
    out += ch;
    i++;
  }
  return out;
}

let failed = false;
for (const file of process.argv.slice(2)) {
  try {
    const raw = readFileSync(file, "utf8");
    JSON.parse(stripTrailingCommas(stripComments(raw)));
    console.log(`ok ${file}`);
  } catch (error) {
    failed = true;
    console.error(`invalid ${file}: ${error.message}`);
  }
}
process.exit(failed ? 1 : 0);
