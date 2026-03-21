#!/usr/bin/env bun
/**
 * CLI wrapper for the security gate scanner.
 * Usage: bun run scan-cli.ts <skill-path> [--trust <level>] [--verbose]
 */

import { scanSkill } from "./scan.ts";
import { formatReport, formatCompact } from "./report.ts";
import type { TrustLevel } from "./types.ts";
import { basename } from "node:path";
import { resolve } from "node:path";

const args = process.argv.slice(2);

if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
  console.log(`Usage: bun run scan-cli.ts <skill-path> [options]

Options:
  --trust <level>   Trust level: pai-core, pai-proposed, external (default: external)
  --verbose         Show verbose output
  --compact         One-line summary only
  --help, -h        Show this help

Examples:
  bun run scan-cli.ts ~/.config/pai/Skills/add-todo
  bun run scan-cli.ts ./skills/skippy --trust pai-core
  bun run scan-cli.ts /path/to/suspicious-skill --compact`);
  process.exit(0);
}

const skillPath = resolve(args[0]);
const trustIdx = args.indexOf("--trust");
const trustLevel: TrustLevel = trustIdx >= 0 && args[trustIdx + 1]
  ? (args[trustIdx + 1] as TrustLevel)
  : "external";
const verbose = args.includes("--verbose");
const compact = args.includes("--compact");

try {
  const result = await scanSkill({
    skillPath,
    trustLevel,
    skillName: basename(skillPath),
    verbose,
  });

  if (compact) {
    console.log(formatCompact(result));
  } else {
    console.log(formatReport(result));
  }

  // Exit code: 0 = safe, 1 = caution, 2 = dangerous
  if (result.verdict === "dangerous") process.exit(2);
  if (result.verdict === "caution") process.exit(1);
  process.exit(0);
} catch (err) {
  console.error(`Scan failed: ${err instanceof Error ? err.message : err}`);
  process.exit(3);
}
