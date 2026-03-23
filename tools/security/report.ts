/**
 * Security scan report formatter.
 *
 * Human-readable output for CLI display and SCAN-RESULT.md files.
 * Pure string formatting -- no external dependencies.
 */

import type { ScanResult, Finding, StructuralIssue, Verdict, Severity } from "./types.ts";

const SEVERITY_ORDER: Severity[] = ["critical", "high", "medium", "low"];

/** Count findings grouped by severity level. */
export function countBySeverity(findings: Finding[]): Record<Severity, number> {
  const counts: Record<Severity, number> = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const f of findings) {
    counts[f.severity] = (counts[f.severity] || 0) + 1;
  }
  return counts;
}

/** Returns the verdict in uppercase for display. */
export function verdictBadge(verdict: Verdict): string {
  return verdict.toUpperCase();
}

/** Single finding as a markdown table row. Truncates description to 80 chars. */
export function formatFinding(finding: Finding, index: number): string {
  const location = finding.line != null ? `${finding.file}:${finding.line}` : finding.file;
  const desc = finding.description.length > 80
    ? finding.description.slice(0, 77) + "..."
    : finding.description;
  return `| ${index} | ${location} | ${finding.patternId} | ${desc} |`;
}

/** Single structural issue as a markdown bullet. */
export function formatStructuralIssue(issue: StructuralIssue): string {
  return `- [${issue.severity}] ${issue.description}`;
}

/** Build the summary line describing finding counts. */
function buildSummaryLine(counts: Record<Severity, number>, fileCount: number): string {
  const parts: string[] = [];
  for (const sev of SEVERITY_ORDER) {
    if (counts[sev] > 0) {
      parts.push(`${counts[sev]} ${sev} finding${counts[sev] !== 1 ? "s" : ""}`);
    }
  }
  if (parts.length === 0) return "Clean: no issues found";
  const filesNote = fileCount > 0 ? ` across ${fileCount} file${fileCount !== 1 ? "s" : ""}` : "";
  return parts.join(", ") + filesNote;
}

/** Produce a full human-readable markdown report from a scan result. */
export function formatReport(result: ScanResult): string {
  const lines: string[] = [];
  const badge = verdictBadge(result.verdict);
  const counts = countBySeverity(result.findings);

  // Unique files with findings
  const affectedFiles = new Set(result.findings.map((f) => f.file));

  // Header
  lines.push(`# Security Scan: ${result.skillName}`);
  lines.push("");
  lines.push(`**Verdict: ${badge}** | Trust: ${result.trustLevel} | Scanned: ${result.scannedAt}`);
  lines.push("");
  lines.push(`> ${buildSummaryLine(counts, affectedFiles.size)}`);

  // Findings grouped by severity
  for (const sev of SEVERITY_ORDER) {
    const group = result.findings.filter((f) => f.severity === sev);
    if (group.length === 0) continue;

    const label = sev.charAt(0).toUpperCase() + sev.slice(1);
    lines.push("");
    lines.push(`## ${label} Findings`);
    lines.push("");
    lines.push("| # | File | Pattern | Description |");
    lines.push("|---|------|---------|-------------|");
    group.forEach((f, i) => {
      lines.push(formatFinding(f, i + 1));
    });
  }

  // Structural issues
  if (result.structuralIssues.length > 0) {
    lines.push("");
    lines.push("## Structural Issues");
    lines.push("");
    for (const issue of result.structuralIssues) {
      lines.push(formatStructuralIssue(issue));
    }
  }

  // Footer
  lines.push("");
  lines.push("---");
  lines.push(`Scan completed in ${result.durationMs}ms`);

  return lines.join("\n");
}

/** One-line compact summary for CLI output (no markdown). */
export function formatCompact(result: ScanResult): string {
  const badge = verdictBadge(result.verdict);
  const counts = countBySeverity(result.findings);

  const parts: string[] = [];
  for (const sev of SEVERITY_ORDER) {
    if (counts[sev] > 0) {
      parts.push(`${counts[sev]} ${sev}`);
    }
  }

  if (parts.length === 0) {
    return `${badge} ${result.skillName} (0 findings, ${result.durationMs}ms)`;
  }
  return `${badge} ${result.skillName} (${parts.join(", ")}, ${result.durationMs}ms)`;
}
