/**
 * Violation message builder and decision helpers for PAI LAW enforcement hooks.
 *
 * Ported from ~/.claude/hooks/law-enforcement/shared/feedback-builder.ts
 * with updates for the official hookSpecificOutput wrapper format.
 */

import type {
  ViolationDetails,
  PreToolUseOutput,
  TopLevelDecisionOutput,
} from "./types.ts";

// ---------------------------------------------------------------------------
// Violation feedback message
// ---------------------------------------------------------------------------

/**
 * Create a formatted LAW violation feedback message.
 *
 * Produces a structured markdown message with law number, title, problem,
 * detected value, required actions, examples, and reference link.
 */
export function createViolationFeedback(details: ViolationDetails): string {
  const {
    law,
    lawNumber,
    title,
    problem,
    detected,
    requiredActions,
    examples = [],
    reference,
  } = details;

  let message = `
**LAW #${lawNumber} VIOLATION: ${title}**

**Law:** ${law}

**Problem:** ${problem}
`;

  if (detected) {
    message += `\n**Detected:** "${detected}"\n`;
  }

  message += `\n**Required Actions:**\n`;
  requiredActions.forEach((action, i) => {
    message += `${i + 1}. ${action}\n`;
  });

  if (examples.length > 0) {
    message += `\n**Examples:**\n`;
    examples.forEach((example) => {
      message += `- ${example}\n`;
    });
  }

  if (reference) {
    message += `\n**Reference:** ${reference}\n`;
  }

  message += `
**After addressing this violation, you can proceed.**

Hook: skills/core/hooks/
`;

  return message;
}

// ---------------------------------------------------------------------------
// PreToolUse decision helpers (hookSpecificOutput wrapper)
// ---------------------------------------------------------------------------

/**
 * Create an allow decision for PreToolUse hooks.
 * Returns the hookSpecificOutput-wrapped format per official docs.
 */
export function allowDecision(): PreToolUseOutput {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
    },
  };
}

/**
 * Create a block (deny) decision for PreToolUse hooks.
 * Returns the hookSpecificOutput-wrapped format per official docs.
 */
export function blockDecision(feedback: string): PreToolUseOutput {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: feedback,
    },
  };
}

/**
 * Create an ask decision for PreToolUse hooks.
 * Shows warning but asks user instead of blocking outright.
 */
export function askDecision(feedback: string): PreToolUseOutput {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: feedback,
    },
  };
}

// ---------------------------------------------------------------------------
// Non-PreToolUse decision helper (top-level format)
// ---------------------------------------------------------------------------

/**
 * Create a block decision for non-PreToolUse events.
 * Used by UserPromptSubmit, PostToolUse, Stop hooks.
 * Returns top-level decision format (no hookSpecificOutput wrapper).
 */
export function blockTopLevel(reason: string): TopLevelDecisionOutput {
  return {
    decision: "block",
    reason,
  };
}
