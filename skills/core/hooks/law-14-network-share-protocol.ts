#!/usr/bin/env bun
/**
 * law-14-network-share-protocol.ts - LAW 14 Enforcement
 *
 * Enforces: LAW 14 - Network Share Protocol
 *
 * Blocks raw mount commands for SMB/NFS without following the
 * network share protocol. Allows umount (unmounting is always safe).
 *
 * Hook Type: PreToolUse (blocking)
 * Matcher: Bash
 */

import type { HookInput } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  blockDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** Mount command patterns that indicate raw SMB/NFS mounting */
const RAW_MOUNT_PATTERNS = [
  "mount -t smbfs",
  "mount -t nfs",
  "mount_smbfs",
  "mount_nfs",
  "mount -t cifs",
  "mount.cifs",
  "mount.nfs",
] as const;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  if (isSubagent()) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const raw = JSON.parse(await Bun.stdin.text());
  const input = normalizeInput(raw);

  if (input.tool_name !== "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const command = ((input.tool_input?.command as string) || "").toLowerCase();

  // Allow unmount commands (always safe)
  if (command.includes("umount") || command.includes("diskutil unmount")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check for raw mount patterns
  let detectedPattern: string | null = null;
  for (const pattern of RAW_MOUNT_PATTERNS) {
    if (command.includes(pattern.toLowerCase())) {
      detectedPattern = pattern;
      break;
    }
  }

  if (!detectedPattern) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Network Share Protocol",
    lawNumber: 14,
    title: "Use Network Share Protocol Script",
    problem: "Raw SMB/NFS mount command detected. Use the network share protocol instead.",
    detected: detectedPattern,
    requiredActions: [
      "Use the network share protocol script for mounting",
      "Never use raw mount commands for SMB/NFS shares",
      "The protocol handles credentials, mount points, and error recovery",
      "Check existing mounts with `mount | grep -E 'smbfs|nfs'`",
    ],
    examples: [
      "Use the deploy-service or infra-sync skills for share management",
      "Check ~/.config/pai/shares/ for share configurations",
    ],
    reference: "skills/core/references/laws/law-14-network-share-protocol.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
