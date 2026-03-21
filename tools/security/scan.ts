/**
 * Security gate scanner orchestrator.
 *
 * Coordinates pattern scanning, structural checks, and unicode detection
 * to produce a unified ScanResult for a skill directory.
 */

import { readdir, readFile } from "node:fs/promises";
import { join, relative, extname, basename } from "node:path";
import type {
  ScanResult,
  ScanOptions,
  Finding,
  TrustLevel,
  Verdict,
  StructuralIssue,
} from "./types.ts";
import { GENERAL_PATTERNS } from "./patterns.ts";
import { PAI_PATTERNS } from "./pai-patterns.ts";
import { checkStructural } from "./structural.ts";
import { checkUnicode, checkHomoglyphs } from "./unicode.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MAX_FILE_SIZE = 262_144; // 256KB -- skip files larger than this

const TEXT_EXTENSIONS = new Set([
  ".md", ".ts", ".js", ".sh", ".bash", ".py",
  ".json", ".yaml", ".yml", ".toml", ".txt",
  ".cfg", ".conf", ".env.example",
]);

const BINARY_EXTENSIONS = new Set([
  ".exe", ".dll", ".so", ".dylib", ".dmg", ".bin",
  ".com", ".msi", ".deb", ".rpm", ".wasm",
  ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp",
  ".zip", ".tar", ".gz", ".bz2", ".xz", ".7z",
  ".mp3", ".mp4", ".wav", ".ogg", ".mov", ".avi",
  ".pdf", ".doc", ".docx", ".xls", ".xlsx",
]);

// ---------------------------------------------------------------------------
// File collection
// ---------------------------------------------------------------------------

async function collectTextFiles(
  skillPath: string,
): Promise<{ fullPath: string; relativePath: string }[]> {
  const entries = await readdir(skillPath, { recursive: true, withFileTypes: true });
  const files: { fullPath: string; relativePath: string }[] = [];

  for (const entry of entries) {
    if (entry.isDirectory()) continue;
    const fullPath = join(entry.parentPath ?? entry.path, entry.name);
    const relPath = relative(skillPath, fullPath);
    const ext = extname(entry.name).toLowerCase();

    // Skip known binary extensions
    if (BINARY_EXTENSIONS.has(ext)) continue;

    // Include if text extension OR no extension (could be a script)
    if (TEXT_EXTENSIONS.has(ext) || ext === "") {
      files.push({ fullPath, relativePath: relPath });
    }
  }

  return files;
}

// ---------------------------------------------------------------------------
// Pattern scanning
// ---------------------------------------------------------------------------

const ALL_PATTERNS = [...GENERAL_PATTERNS, ...PAI_PATTERNS];

function scanFileContent(
  _filePath: string,
  relativePath: string,
  content: string,
): Finding[] {
  const findings: Finding[] = [];
  const lines = content.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    for (const pattern of ALL_PATTERNS) {
      const match = pattern.pattern.exec(line);
      if (match) {
        const matchText = match[0].length > 200
          ? match[0].slice(0, 200)
          : match[0];

        findings.push({
          patternId: pattern.id,
          category: pattern.category,
          severity: pattern.severity,
          description: pattern.description,
          file: relativePath,
          line: i + 1,
          match: matchText,
          ...(pattern.falsePositiveHint
            ? { falsePositiveHint: pattern.falsePositiveHint }
            : {}),
        });
      }
    }
  }

  return findings;
}

// ---------------------------------------------------------------------------
// Verdict determination
// ---------------------------------------------------------------------------

function determineVerdict(findings: Finding[], trustLevel: TrustLevel): Verdict {
  if (trustLevel === "pai-core") return "safe";

  const hasCritical = findings.some((f) => f.severity === "critical");
  const hasHigh = findings.some((f) => f.severity === "high");
  const hasMedium = findings.some((f) => f.severity === "medium");

  if (trustLevel === "external") {
    if (hasCritical) return "dangerous";
    if (hasHigh) return "dangerous";
    if (hasMedium) return "caution";
    return "safe";
  }

  // pai-proposed
  if (hasCritical) return "dangerous";
  if (hasHigh) return "caution";
  return "safe";
}

// ---------------------------------------------------------------------------
// Summary generation
// ---------------------------------------------------------------------------

function generateSummary(
  findings: Finding[],
  structuralIssues: StructuralIssue[],
  verdict: Verdict,
): string {
  const totalIssues = findings.length + structuralIssues.length;

  if (totalIssues === 0) return "Clean: no issues found";

  const criticalCount = findings.filter((f) => f.severity === "critical").length;
  const highCount = findings.filter((f) => f.severity === "high").length;
  const mediumCount = findings.filter((f) => f.severity === "medium").length;

  const uniqueCategories = [...new Set(findings.map((f) => f.category))];
  const affectedFiles = [...new Set(findings.map((f) => f.file))];

  if (verdict === "dangerous") {
    const parts: string[] = [];
    if (criticalCount > 0) parts.push(`${criticalCount} critical`);
    if (highCount > 0) parts.push(`${highCount} high`);
    const categories = uniqueCategories.join(", ");
    return `BLOCKED: ${parts.join(", ")} findings (${categories})`;
  }

  if (verdict === "caution") {
    const parts: string[] = [];
    if (highCount > 0) parts.push(`${highCount} high`);
    if (mediumCount > 0) parts.push(`${mediumCount} medium`);
    const fileNote = affectedFiles.length === 1
      ? "in 1 file"
      : `in ${affectedFiles.length} files`;
    return `Caution: ${parts.join(", ")} findings ${fileNote}`;
  }

  // safe but with some low/informational findings or structural issues
  if (structuralIssues.length > 0) {
    return `Safe: ${structuralIssues.length} structural note(s), no blocking findings`;
  }
  return `Safe: ${totalIssues} low-severity finding(s)`;
}

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

export async function scanSkill(options: ScanOptions): Promise<ScanResult> {
  const start = performance.now();

  const skillName = options.skillName ?? basename(options.skillPath);
  const { skillPath, trustLevel } = options;

  // Step 1: Collect text files
  const textFiles = await collectTextFiles(skillPath);

  // Step 2: Run pattern + unicode scans in parallel per file
  const fileScanPromises = textFiles.map(async ({ fullPath, relativePath }) => {
    let content: string;
    try {
      const buf = await readFile(fullPath);
      if (buf.length > MAX_FILE_SIZE) return { patternFindings: [], unicodeFindings: [] };
      content = buf.toString("utf-8");
    } catch {
      return { patternFindings: [], unicodeFindings: [] };
    }

    const patternFindings = scanFileContent(fullPath, relativePath, content);
    const unicodeFindings = [
      ...checkUnicode(relativePath, content),
      ...checkHomoglyphs(relativePath, content),
    ];

    return { patternFindings, unicodeFindings };
  });

  // Step 3: Run structural checks in parallel with file scans
  const [fileResults, structuralIssues] = await Promise.all([
    Promise.all(fileScanPromises),
    checkStructural(skillPath),
  ]);

  // Step 4: Combine all findings
  const findings: Finding[] = [];
  for (const result of fileResults) {
    findings.push(...result.patternFindings);
    findings.push(...result.unicodeFindings);
  }

  // Step 5: Determine verdict and summary
  const verdict = determineVerdict(findings, trustLevel);
  const summary = generateSummary(findings, structuralIssues, verdict);

  const durationMs = Math.round(performance.now() - start);

  return {
    verdict,
    trustLevel,
    skillName,
    skillPath,
    scannedAt: new Date().toISOString(),
    findings,
    structuralIssues,
    summary,
    durationMs,
  };
}
