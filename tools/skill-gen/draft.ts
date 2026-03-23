// draft.ts -- Generates a complete skill draft from a task description,
// runs it through the security scanner, and quarantines it for review.

import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { generateSkillMd, validateSkillName, DEFAULT_VERSION } from "./template.ts";
import type { SkillContent, SkillMetadata } from "./template.ts";
import { quarantineSkill, ensureQuarantineDir } from "./quarantine.ts";
import { suggestSkillName } from "./detect.ts";
import { scanSkill } from "../security/scan.ts";
import { formatReport } from "../security/report.ts";
import type { ScanResult } from "../security/types.ts";

export interface DraftInput {
  /** What the task accomplished */
  description: string;
  /** Step-by-step workflow that was performed */
  steps: string[];
  /** When to use this skill (trigger phrases) */
  triggerPatterns?: string[];
  /** Related docs or skills */
  references?: string[];
  /** Override the auto-suggested name */
  skillName?: string;
  /** Session ID for provenance tracking */
  sessionId?: string;
}

export interface DraftResult {
  /** Whether the draft was created and quarantined */
  success: boolean;
  /** Skill name used */
  skillName: string;
  /** Path to quarantined skill (if successful) */
  quarantinePath?: string;
  /** Security scan result */
  scanResult?: ScanResult;
  /** Formatted scan report */
  scanReport?: string;
  /** Why it failed (if !success) */
  error?: string;
}

export function buildSkillContent(input: DraftInput, skillName: string): SkillContent {
  const metadata: SkillMetadata = {
    name: skillName,
    description: input.description,
    version: DEFAULT_VERSION,
    source: "pai-proposed",
    generated: new Date().toISOString(),
    ...(input.sessionId ? { session: input.sessionId } : {}),
  };

  return {
    metadata,
    purpose: input.description,
    usage: `Invoke via \`/${skillName}\` when the task matches this workflow.`,
    workflow: input.steps,
    ...(input.references?.length ? { references: input.references } : {}),
    ...(input.triggerPatterns?.length ? { triggerPatterns: input.triggerPatterns } : {}),
  };
}

export function generateProposal(input: DraftInput, scanResult: ScanResult): string {
  const steps = input.steps.map((s, i) => `${i + 1}. ${s}`).join("\n");
  const scan = [
    `- **Verdict:** ${scanResult.verdict.toUpperCase()}`,
    `- **Findings:** ${scanResult.findings.length}`,
    `- **Structural issues:** ${scanResult.structuralIssues.length}`,
    `- **Summary:** ${scanResult.summary}`,
  ].join("\n");

  return [
    "# Skill Proposal",
    "",
    "## What",
    "",
    input.description,
    "",
    "## Why",
    "",
    "This skill was auto-proposed because the completed task matched reusable workflow patterns.",
    "It encodes a multi-step process that would otherwise need to be repeated manually.",
    "",
    "## Workflow",
    "",
    steps,
    "",
    "## Security Scan",
    "",
    scan,
    "",
    "## Actions",
    "",
    '- **Approve:** Run `promoteSkill("<name>")` to move from quarantine to active skills',
    '- **Reject:** Run `removeQuarantined("<name>")` to delete the draft',
    "- **Edit:** Modify files in the quarantine directory, then re-scan before promoting",
    "",
  ].join("\n");
}

export async function draftSkill(input: DraftInput): Promise<DraftResult> {
  // Step 1: Validate or generate skill name
  const skillName = input.skillName ?? suggestSkillName(input.description);
  const validation = validateSkillName(skillName);

  if (!validation.valid) {
    return {
      success: false,
      skillName,
      error: `Invalid skill name "${skillName}": ${validation.reason}`,
    };
  }

  // Step 2: Build skill content and generate SKILL.md
  const content = buildSkillContent(input, skillName);
  const skillMd = generateSkillMd(content);

  // Step 3: Ensure quarantine dir and write initial skill files
  await ensureQuarantineDir();

  let quarantinePath: string;
  try {
    quarantinePath = await quarantineSkill(skillName, new Map([["SKILL.md", skillMd]]));
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return { success: false, skillName, error: msg };
  }

  // Step 4: Run security scan against quarantined path
  const scanResult = await scanSkill({
    skillPath: quarantinePath,
    trustLevel: "pai-proposed",
    skillName,
  });
  const scanReport = formatReport(scanResult);

  // Step 5: Write PROPOSAL.md and SCAN-RESULT.md into quarantine
  const proposal = generateProposal(input, scanResult);
  await writeFile(join(quarantinePath, "PROPOSAL.md"), proposal, "utf-8");
  await writeFile(join(quarantinePath, "SCAN-RESULT.md"), scanReport, "utf-8");

  return { success: true, skillName, quarantinePath, scanResult, scanReport };
}
