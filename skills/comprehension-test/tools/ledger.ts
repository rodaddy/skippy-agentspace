#!/usr/bin/env bun
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const LEDGER_PATH = join(
  homedir(),
  ".config",
  "pai-private",
  "memory",
  "comprehension-ledger.json"
);

interface SectionScores {
  what_is_this: number;
  why_this_approach: number;
  what_would_break: number;
  what_i_learned: number;
}

interface LedgerEntry {
  project: string;
  tested: string;
  sections: SectionScores;
  overall: number;
  weak_spots: string[];
  bullets_generated: number;
  notes: string;
}

interface Ledger {
  entries: LedgerEntry[];
  last_updated: string;
}

function loadLedger(): Ledger {
  if (!existsSync(LEDGER_PATH)) {
    return { entries: [], last_updated: new Date().toISOString() };
  }
  return JSON.parse(readFileSync(LEDGER_PATH, "utf-8"));
}

function saveLedger(ledger: Ledger): void {
  const dir = join(homedir(), ".config", "pai-private", "memory");
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  ledger.last_updated = new Date().toISOString();
  writeFileSync(LEDGER_PATH, JSON.stringify(ledger, null, 2) + "\n");
}

function parseArgs(): { command: string; flags: Record<string, string> } {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === "--help") {
    console.log(`comprehension-test ledger -- track project understanding

Usage:
  ledger add     --project NAME --what-is-this N --why-this-approach N
                 --what-would-break N --what-i-learned N
                 [--weak-spots "a, b"] [--bullets-generated N] [--notes "..."]
  ledger list    Show all tested projects with scores
  ledger gaps    Show weak spots across all projects
  ledger remove  --project NAME   Remove a project entry

Scores: 1 (weak) to 5 (strong). Overall is auto-calculated as the average.`);
    process.exit(0);
  }

  const command = args[0];
  const flags: Record<string, string> = {};
  for (let i = 1; i < args.length; i++) {
    if (args[i].startsWith("--") && i + 1 < args.length) {
      flags[args[i].slice(2)] = args[i + 1];
      i++;
    }
  }
  return { command, flags };
}

function addEntry(flags: Record<string, string>): void {
  const required = [
    "project",
    "what-is-this",
    "why-this-approach",
    "what-would-break",
    "what-i-learned",
  ];
  for (const key of required) {
    if (!flags[key]) {
      console.error(`Missing required flag: --${key}`);
      process.exit(1);
    }
  }

  const sections: SectionScores = {
    what_is_this: parseInt(flags["what-is-this"]),
    why_this_approach: parseInt(flags["why-this-approach"]),
    what_would_break: parseInt(flags["what-would-break"]),
    what_i_learned: parseInt(flags["what-i-learned"]),
  };

  for (const [key, val] of Object.entries(sections)) {
    if (isNaN(val) || val < 1 || val > 5) {
      console.error(`Invalid score for ${key}: must be 1-5`);
      process.exit(1);
    }
  }

  const overall =
    Math.round(
      ((sections.what_is_this +
        sections.why_this_approach +
        sections.what_would_break +
        sections.what_i_learned) /
        4) *
        10
    ) / 10;

  const entry: LedgerEntry = {
    project: flags.project,
    tested: new Date().toISOString().split("T")[0],
    sections,
    overall,
    weak_spots: flags["weak-spots"]
      ? flags["weak-spots"].split(",").map((s) => s.trim())
      : [],
    bullets_generated: parseInt(flags["bullets-generated"] || "0"),
    notes: flags.notes || "",
  };

  const ledger = loadLedger();

  const existing = ledger.entries.findIndex(
    (e) => e.project.toLowerCase() === entry.project.toLowerCase()
  );
  if (existing >= 0) {
    ledger.entries[existing] = entry;
    console.log(`Updated existing entry for "${entry.project}"`);
  } else {
    ledger.entries.push(entry);
    console.log(`Added new entry for "${entry.project}"`);
  }

  saveLedger(ledger);
  printEntry(entry);
}

function printEntry(entry: LedgerEntry): void {
  console.log(`\n  ${entry.project} (tested ${entry.tested})`);
  console.log(`  Overall: ${entry.overall}/5`);
  console.log(`  What Is This:      ${scoreBar(entry.sections.what_is_this)}`);
  console.log(
    `  Why This Approach: ${scoreBar(entry.sections.why_this_approach)}`
  );
  console.log(
    `  What Would Break:  ${scoreBar(entry.sections.what_would_break)}`
  );
  console.log(`  What I Learned:    ${scoreBar(entry.sections.what_i_learned)}`);
  if (entry.weak_spots.length > 0)
    console.log(`  Weak spots: ${entry.weak_spots.join(", ")}`);
  if (entry.bullets_generated > 0)
    console.log(`  Bullets generated: ${entry.bullets_generated}`);
  if (entry.notes) console.log(`  Notes: ${entry.notes}`);
}

function scoreBar(score: number): string {
  const filled = "=".repeat(score);
  const empty = "-".repeat(5 - score);
  return `[${filled}${empty}] ${score}/5`;
}

function listEntries(): void {
  const ledger = loadLedger();
  if (ledger.entries.length === 0) {
    console.log("No projects tested yet. Run a comprehension test first.");
    return;
  }

  console.log(
    `\nComprehension Ledger (${ledger.entries.length} projects tested)\n`
  );

  const sorted = [...ledger.entries].sort((a, b) => b.overall - a.overall);
  for (const entry of sorted) {
    printEntry(entry);
    console.log("");
  }

  const avg =
    Math.round(
      (sorted.reduce((sum, e) => sum + e.overall, 0) / sorted.length) * 10
    ) / 10;
  console.log(`Average comprehension: ${avg}/5`);

  const strong = sorted.filter((e) => e.overall >= 4);
  const marginal = sorted.filter((e) => e.overall >= 3 && e.overall < 4);
  const weak = sorted.filter((e) => e.overall < 3);

  if (strong.length > 0)
    console.log(
      `Lead with: ${strong.map((e) => e.project).join(", ")}`
    );
  if (marginal.length > 0)
    console.log(
      `Mention carefully: ${marginal.map((e) => e.project).join(", ")}`
    );
  if (weak.length > 0)
    console.log(
      `Retest or omit: ${weak.map((e) => e.project).join(", ")}`
    );
}

function showGaps(): void {
  const ledger = loadLedger();
  if (ledger.entries.length === 0) {
    console.log("No projects tested yet.");
    return;
  }

  console.log("\nComprehension Gaps\n");

  const allWeakSpots: Array<{ project: string; spot: string }> = [];
  const sectionWeaknesses: Record<string, string[]> = {
    what_is_this: [],
    why_this_approach: [],
    what_would_break: [],
    what_i_learned: [],
  };

  for (const entry of ledger.entries) {
    for (const spot of entry.weak_spots) {
      allWeakSpots.push({ project: entry.project, spot });
    }
    for (const [section, score] of Object.entries(entry.sections)) {
      if (score <= 2) {
        sectionWeaknesses[section].push(
          `${entry.project} (${score}/5)`
        );
      }
    }
  }

  console.log("Weak sections across projects:");
  for (const [section, projects] of Object.entries(sectionWeaknesses)) {
    if (projects.length > 0) {
      const label = section.replace(/_/g, " ");
      console.log(`  ${label}: ${projects.join(", ")}`);
    }
  }

  if (allWeakSpots.length > 0) {
    console.log("\nSpecific weak spots:");
    for (const { project, spot } of allWeakSpots) {
      console.log(`  [${project}] ${spot}`);
    }
  }

  const phaseAverages: Record<string, number> = {};
  for (const section of Object.keys(sectionWeaknesses)) {
    const scores = ledger.entries.map(
      (e) => e.sections[section as keyof SectionScores]
    );
    phaseAverages[section] =
      Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) /
      10;
  }

  console.log("\nPhase averages:");
  for (const [section, avg] of Object.entries(phaseAverages)) {
    const label = section.replace(/_/g, " ");
    console.log(`  ${label}: ${avg}/5`);
  }
}

function removeEntry(flags: Record<string, string>): void {
  if (!flags.project) {
    console.error("Missing required flag: --project");
    process.exit(1);
  }

  const ledger = loadLedger();
  const idx = ledger.entries.findIndex(
    (e) => e.project.toLowerCase() === flags.project.toLowerCase()
  );

  if (idx < 0) {
    console.error(`No entry found for "${flags.project}"`);
    process.exit(1);
  }

  const removed = ledger.entries.splice(idx, 1)[0];
  saveLedger(ledger);
  console.log(`Removed entry for "${removed.project}"`);
}

const { command, flags } = parseArgs();

switch (command) {
  case "add":
    addEntry(flags);
    break;
  case "list":
    listEntries();
    break;
  case "gaps":
    showGaps();
    break;
  case "remove":
    removeEntry(flags);
    break;
  default:
    console.error(`Unknown command: ${command}. Use --help for usage.`);
    process.exit(1);
}
