/**
 * Skill proposal display and action handling.
 *
 * Presents quarantined skill proposals for user review within a Claude Code
 * session. Formats proposals for display and handles approve/reject/defer.
 */

import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { promoteSkill, removeQuarantined, listQuarantined } from "./quarantine.ts";

export type ProposalAction = "approve" | "reject" | "defer";

export interface ProposalSummary {
  skillName: string;
  description: string;
  scanSummary: string;
  quarantinePath: string;
  createdAt: string;
  /** Full proposal text for display */
  proposalText: string;
}

export interface ProposalActionResult {
  action: ProposalAction;
  skillName: string;
  /** Path where skill was installed (if approved) */
  installedPath?: string;
  message: string;
}

/** Read a file from quarantine, returning null if missing. */
async function readQuarantineFile(skillPath: string, filename: string): Promise<string | null> {
  try {
    return await readFile(join(skillPath, filename), "utf-8");
  } catch {
    return null;
  }
}

/** Build a scan summary string from SCAN-RESULT.md content or fall back to raw text. */
function parseScanSummary(scanContent: string | null): string {
  if (!scanContent) return "No scan result available";

  // Extract the verdict line from the scan report markdown
  const verdictMatch = scanContent.match(/\*\*Verdict:\s*(\w+)\*\*/);
  const durationMatch = scanContent.match(/Scan completed in (\d+)ms/);
  const summaryMatch = scanContent.match(/^>\s*(.+)$/m);

  if (verdictMatch) {
    const verdict = verdictMatch[1];
    const duration = durationMatch ? `, ${durationMatch[1]}ms` : "";
    const detail = summaryMatch ? ` -- ${summaryMatch[1]}` : "";
    return `${verdict}${duration}${detail}`;
  }

  // Fall back to first non-empty line
  const firstLine = scanContent.split("\n").find((l) => l.trim().length > 0);
  return firstLine?.trim() ?? "Scan result unparseable";
}

/** Extract a short description from PROPOSAL.md content. */
function parseDescription(proposalContent: string | null): string {
  if (!proposalContent) return "No proposal description available";

  // Look for a "What it does" or "Description" section
  const sectionMatch = proposalContent.match(
    /##\s*(?:What it does|Description)\s*\n+([^\n#]+)/i,
  );
  if (sectionMatch) return sectionMatch[1].trim();

  // Fall back to first non-heading, non-empty line
  const lines = proposalContent.split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.length > 0 && !trimmed.startsWith("#")) return trimmed;
  }

  return "No description found";
}

export async function getProposal(skillName: string): Promise<ProposalSummary | null> {
  const entries = await listQuarantined();
  const entry = entries.find((e) => e.skillName === skillName);
  if (!entry) return null;

  const proposalContent = await readQuarantineFile(entry.path, "PROPOSAL.md");
  const scanContent = await readQuarantineFile(entry.path, "SCAN-RESULT.md");

  return {
    skillName: entry.skillName,
    description: parseDescription(proposalContent),
    scanSummary: parseScanSummary(scanContent),
    quarantinePath: entry.path,
    createdAt: entry.createdAt,
    proposalText: proposalContent ?? "No proposal file found.",
  };
}

export async function listProposals(): Promise<ProposalSummary[]> {
  const entries = await listQuarantined();
  const summaries: ProposalSummary[] = [];

  for (const entry of entries) {
    const summary = await getProposal(entry.skillName);
    if (summary) summaries.push(summary);
  }

  return summaries;
}

export function formatProposalForDisplay(summary: ProposalSummary): string {
  const lines: string[] = [];

  lines.push(`## Proposed Skill: ${summary.skillName}`);
  lines.push("");
  lines.push(`**Created:** ${summary.createdAt}`);
  lines.push(`**Security:** ${summary.scanSummary}`);
  lines.push("");
  lines.push("### What it does");
  lines.push("");
  lines.push(summary.proposalText);
  lines.push("");
  lines.push("### Actions");
  lines.push("");
  lines.push(`- Approve: \`approveProposal("${summary.skillName}")\``);
  lines.push(`- Reject: \`rejectProposal("${summary.skillName}")\``);
  lines.push(`- Defer: \`deferProposal("${summary.skillName}")\``);

  return lines.join("\n");
}

export async function approveProposal(skillName: string): Promise<ProposalActionResult> {
  const installedPath = await promoteSkill(skillName);
  return {
    action: "approve",
    skillName,
    installedPath,
    message: `Skill "${skillName}" approved and installed to ${installedPath}`,
  };
}

export async function rejectProposal(
  skillName: string,
  reason?: string,
): Promise<ProposalActionResult> {
  await removeQuarantined(skillName);
  const reasonSuffix = reason ? `: ${reason}` : "";
  return {
    action: "reject",
    skillName,
    message: `Skill "${skillName}" rejected and removed from quarantine${reasonSuffix}`,
  };
}

export async function deferProposal(skillName: string): Promise<ProposalActionResult> {
  // Verify the skill exists in quarantine before confirming deferral
  const entries = await listQuarantined();
  const exists = entries.some((e) => e.skillName === skillName);
  if (!exists) {
    throw new Error(`Skill "${skillName}" not found in quarantine`);
  }

  return {
    action: "defer",
    skillName,
    message: `Skill "${skillName}" deferred -- remains in quarantine until expiry`,
  };
}
