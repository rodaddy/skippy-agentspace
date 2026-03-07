#!/usr/bin/env bun
/**
 * law-13-no-silent-autopilot.ts - LAW 13 Enforcement
 *
 * Enforces: LAW 13 - No Silent Autopilot
 *
 * This is the ONLY UserPromptSubmit hook. Different event type --
 * no tool_name/tool_input. Detects keywords in user prompts that
 * suggest enabling autopilot without safeguards.
 *
 * Uses blockTopLevel (NOT blockDecision -- different output format
 * for non-PreToolUse events).
 *
 * Hook Type: UserPromptSubmit (blocking)
 * Matcher: null (UserPromptSubmit doesn't support matchers)
 */

import type { HookInput } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import { allowDecision, blockTopLevel } from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** Keywords that suggest silent autopilot mode */
const AUTOPILOT_KEYWORDS = [
  "do everything",
  "don't ask",
  "dont ask",
  "just do it",
  "autopilot",
  "yolo mode",
  "full auto",
  "do it all",
  "don't stop",
  "dont stop",
  "no questions",
  "skip confirmation",
  "skip approvals",
] as const;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  if (isSubagent()) {
    // For UserPromptSubmit, output nothing to allow (no hookSpecificOutput needed)
    return;
  }

  const raw = JSON.parse(await Bun.stdin.text());

  // UserPromptSubmit has a `prompt` field with the user's message text
  const prompt = ((raw.prompt as string) || "").toLowerCase();

  if (!prompt) {
    return;
  }

  // Check for autopilot keywords
  let detectedKeyword: string | null = null;
  for (const keyword of AUTOPILOT_KEYWORDS) {
    if (prompt.includes(keyword)) {
      detectedKeyword = keyword;
      break;
    }
  }

  if (!detectedKeyword) {
    return;
  }

  // VIOLATION: blockTopLevel for UserPromptSubmit events
  const reason = [
    `**LAW #13 VIOLATION: No Silent Autopilot**`,
    ``,
    `**Detected:** "${detectedKeyword}"`,
    ``,
    `**Problem:** Requesting full autopilot mode bypasses safety checks,`,
    `code review, and user approval gates. This can lead to:`,
    `- Unreviewed changes to critical files`,
    `- Secrets accidentally committed`,
    `- Destructive operations without confirmation`,
    ``,
    `**Instead:**`,
    `1. Be specific about what you want done`,
    `2. Review changes at key checkpoints`,
    `3. Use permission modes (plan, acceptEdits) for controlled automation`,
    `4. Approve batches of related changes, not "everything"`,
    ``,
    `**Reference:** skills/core/references/laws/law-13-no-silent-autopilot.md`,
  ].join("\n");

  console.log(JSON.stringify(blockTopLevel(reason)));
}

try {
  await main();
} catch {
  // Fail open -- output nothing for UserPromptSubmit = allow
}
