#!/usr/bin/env node
// Точная замена подстроки в JS-файле бандла, с проверками.
// Использование: node patch-js.mjs <file> <needle> <replacement> [label]
// В replacement последовательности \n и \t разворачиваются в перевод строки и таб.
// Код возврата: 0 — заменено, 1 — шаблон не найден или неоднозначен, 2 — аргументы.
import { readFileSync, writeFileSync } from "node:fs";

const [file, needle, rawReplacement, label = "patch"] = process.argv.slice(2);
if (!file || !needle || rawReplacement === undefined) {
  console.error("usage: patch-js.mjs <file> <needle> <replacement> [label]");
  process.exit(2);
}

const replacement = rawReplacement.replace(/\\n/g, "\n").replace(/\\t/g, "\t");
const source = readFileSync(file, "utf8");
const occurrences = source.split(needle).length - 1;

if (occurrences === 0) {
  console.error(`!! ${label}: шаблон не найден в ${file}`);
  console.error(`   шаблон: ${needle.slice(0, 160)}`);
  process.exit(1);
}
if (occurrences > 1) {
  console.error(`!! ${label}: шаблон встречается ${occurrences} раз(а) в ${file} — замена неоднозначна`);
  process.exit(1);
}

writeFileSync(file, source.replace(needle, replacement));
console.log(`   ok ${label}`);
