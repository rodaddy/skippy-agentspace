#!/usr/bin/env bun
/**
 * law-05-explain-before-doing.ts - LAW 5 Enforcement
 *
 * Enforces: LAW 5 - Explain Before Doing
 *
 * Blocks file operations (Write, Edit) when no explanation of what/why
 * was provided in recent assistant messages.
 *
 * Hook Type: PreToolUse (blocking)
 * Matcher: Write|Edit|Bash
 */

import type { HookInput, Message, ContentBlock, TextBlock } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  blockDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const MULTI_STEP_KEYWORDS = [
  "two edits",
  "two steps",
  "multiple edits",
  "both edits",
  "this requires",
  "two-step",
  "multi-step",
  "step 1",
  "step 2",
] as const;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function extractTextContent(content: ContentBlock[] | string): string {
  if (typeof content === "string") return content;
  return content
    .filter((b): b is TextBlock => b.type === "text")
    .map((b) => b.text)
    .join("\n");
}

function getRecentAssistantText(messages: Message[], count: number): string[] {
  const texts: string[] = [];
  for (const msg of messages.slice(-count)) {
    if (msg.role !== "assistant") continue;
    const t = extractTextContent(msg.content);
    if (t.trim()) texts.push(t);
  }
  return texts;
}

function countPendingToolUses(messages: Message[], toolNames: string[]): number {
  const last = messages[messages.length - 1];
  if (!last || last.role !== "assistant") return 0;
  const content = Array.isArray(last.content) ? last.content : [];
  let count = 0;
  for (const block of content) {
    if (block.type === "tool_use" && toolNames.includes(block.name)) count++;
  }
  return count;
}

/**
 * Check if explanation was provided in recent messages.
 * Looks for WHAT/WHY indicators alongside file path mentions.
 */
function hasExplanation(messages: Message[], toolInput: Record<string, unknown>): boolean {
  const texts = getRecentAssistantText(messages, 2);
  const recentText = texts.join(" ").toLowerCase();

  const filePath = toolInput.file_path as string;
  if (filePath) {
    const fileName = filePath.split("/").pop() || "";
    if (fileName && recentText.includes(fileName.toLowerCase())) {
      const hasWhat = /\b(updating?|modifying?|changing?|creating?|adding?|fixing?)\s+\S+/.test(recentText);
      const hasWhy = /\b(because|to|in order to|so that|for)\s+\S+/.test(recentText);
      if (hasWhat || hasWhy) return true;
    }
  }

  return false;
}

function hasMultiStepExplanation(messages: Message[]): boolean {
  const texts = getRecentAssistantText(messages, 2);
  for (const text of texts) {
    const lower = text.toLowerCase();
    for (const keyword of MULTI_STEP_KEYWORDS) {
      if (lower.includes(keyword)) return true;
    }
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
  const recentMessages: Message[] = (raw.recentMessages ?? raw.recent_messages ?? []) as Message[];

  // Skip Bash commands (often read-only or explained separately)
  if (!input.tool_name || input.tool_name === "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Only check Write/Edit/NotebookEdit
  if (!["Write", "Edit", "NotebookEdit"].includes(input.tool_name)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check for multi-edit operations
  const multiEditCount = countPendingToolUses(recentMessages, ["Edit", "Write", "NotebookEdit"]);

  if (multiEditCount >= 2) {
    if (!hasMultiStepExplanation(recentMessages)) {
      const feedback = createViolationFeedback({
        law: "Explain Before Doing (Multi-Step Operations)",
        lawNumber: 5,
        title: "Explain Multi-Step Operations",
        problem: `You're about to make ${multiEditCount} edits without explaining it's a multi-step operation.`,
        detected: `${multiEditCount} Edit/Write calls detected in this response`,
        requiredActions: [
          "Explain this is a **multi-step operation** (e.g., 'This requires two edits...')",
          "List each step clearly (Step 1: ... Step 2: ...)",
          "Show what each edit does and why it's needed",
          "Then make all edits in the same message",
        ],
        examples: [
          "This requires two edits:\\n1. Add to Bash section\\n2. Remove from wildcard section",
          "I need to make two changes:\\n1. Update import\\n2. Update export",
        ],
        reference: "skills/core/references/laws/law-05-explain-before-doing.md",
      });

      console.log(JSON.stringify(blockDecision(feedback)));
      return;
    }
    // Multi-step explanation provided
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Single edit -- check for basic explanation
  if (hasExplanation(recentMessages, input.tool_input || {})) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Explain Before Doing",
    lawNumber: 5,
    title: "Explain Before Doing",
    problem: "You're about to modify files without explaining what and why.",
    requiredActions: [
      "Explain **WHAT** you're going to do",
      "Explain **WHY** it's necessary",
      "Show **WHAT** will be affected (file count, scope)",
      "Then proceed with the file operation",
    ],
    examples: [
      "I need to update config.ts because...",
      "Let me refactor the auth module to fix...",
      "First, I'll create a new component for...",
    ],
    reference: "skills/core/references/laws/law-05-explain-before-doing.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
