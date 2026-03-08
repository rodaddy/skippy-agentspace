#!/usr/bin/env bun
/**
 * law-15-no-litellm-self-surgery.ts - LAW 15 Enforcement
 *
 * Enforces: LAW 15 - No LiteLLM Self-Surgery
 *
 * Blocks Bash commands that target LiteLLM infrastructure when the current
 * session is routed through LiteLLM. Modifying the proxy while using it
 * will kill the session with no AI to fix it.
 *
 * Safe API calls (curl/wget to health/metrics endpoints) are allowed.
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
// Configuration (sanitized -- no private IPs in portable hooks)
// ---------------------------------------------------------------------------

/** Safe read-only API endpoint patterns (allow these through) */
const SAFE_API_PATTERNS = [
  /curl.*litellm.*\/v1\//i,
  /curl.*litellm.*\/health/i,
  /curl.*litellm.*\/metrics/i,
  /wget.*litellm.*\/v1\//i,
  /wget.*litellm.*\/health/i,
] as const;

/** Patterns indicating destructive LiteLLM operations */
const LITELLM_TARGET_PATTERNS = [
  "ssh litellm",
  "ssh root@litellm",
  "ansible litellm",
  "litellm.service",
  "litellm-config",
  "litellm-env",
  "systemctl.*litellm",
  "service litellm",
] as const;

// ---------------------------------------------------------------------------
// Detection
// ---------------------------------------------------------------------------

function isRoutedThroughLiteLLM(): boolean {
  const baseUrl = (process.env.ANTHROPIC_BASE_URL || "").toLowerCase();
  return baseUrl.includes("litellm");
}

function isDirectVertex(): boolean {
  return (
    process.env.CLAUDE_CODE_USE_VERTEX === "1" &&
    !isRoutedThroughLiteLLM()
  );
}

function isSafeApiCall(command: string): boolean {
  for (const pattern of SAFE_API_PATTERNS) {
    if (pattern.test(command)) return true;
  }
  return false;
}

function commandTargetsLiteLLM(command: string): boolean {
  const cmd = command.toLowerCase();

  // Allow safe API calls
  if (isSafeApiCall(cmd)) return false;

  // Check destructive patterns
  for (const pattern of LITELLM_TARGET_PATTERNS) {
    if (pattern.includes(".*")) {
      if (new RegExp(pattern, "i").test(cmd)) return true;
    } else {
      if (cmd.includes(pattern.toLowerCase())) return true;
    }
  }

  // Ansible playbooks that might target litellm
  if (cmd.includes("ansible-playbook")) {
    if (cmd.includes("litellm") || /--limit.*litellm/i.test(cmd)) return true;
  }

  return false;
}

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

  // If running direct Vertex or not routed through LiteLLM, allow
  if (isDirectVertex() || !isRoutedThroughLiteLLM()) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const command = ((input.tool_input?.command as string) || "");

  if (!commandTargetsLiteLLM(command)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "No LiteLLM Self-Surgery",
    lawNumber: 15,
    title: "Cannot Modify LiteLLM While Routed Through It",
    problem: "Modifying LiteLLM while this session uses it as proxy will kill the session.",
    detected: command.substring(0, 120),
    requiredActions: [
      "Start a direct Vertex session: CLAUDE_CODE_USE_VERTEX=1 claude",
      "Run LiteLLM changes from that direct session instead",
      "Never modify the proxy you're currently using",
    ],
    reference: "skills/core/references/laws/law-15-no-litellm-self-surgery.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
