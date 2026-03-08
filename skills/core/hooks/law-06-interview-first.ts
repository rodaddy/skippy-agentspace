#!/usr/bin/env bun
/**
 * law-06-interview-first.ts - LAW 6 Enforcement
 *
 * Enforces: LAW 6 - Interview-First
 *
 * Detects when Claude is about to implement a significant feature without
 * first asking clarifying questions. Soft nudge (askDecision), not a hard gate.
 *
 * Skips for small edits, config files, and test files.
 *
 * Hook Type: PreToolUse (soft warning)
 * Matcher: Write|Edit|Bash
 */

import type { HookInput, Message, ContentBlock, TextBlock } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  askDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** File patterns that skip interview check (config, tests, small edits) */
const SKIP_FILE_PATTERNS = [
  /\.config\./i,
  /\.env/i,
  /tsconfig/i,
  /package\.json/i,
  /\.gitignore/i,
  /\.eslintrc/i,
  /\.prettierrc/i,
  /\.test\./i,
  /\.spec\./i,
  /test\//i,
  /tests\//i,
  /__tests__\//i,
  /\.planning\//i,
  /\.md$/i,
] as const;

/** Minimum content size to trigger interview check (lines) */
const MIN_LINES_THRESHOLD = 20;

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

function checkToolUsed(messages: Message[], toolName: string, lookback = 5): boolean {
  for (const msg of messages.slice(-lookback)) {
    if (msg.role !== "assistant") continue;
    const content = Array.isArray(msg.content) ? msg.content : [];
    for (const block of content) {
      if (block.type === "tool_use" && block.name === toolName) return true;
    }
  }
  return false;
}

/**
 * Check if the conversation has enough back-and-forth to suggest
 * requirements were gathered. Looks for question marks in assistant
 * messages and user responses.
 */
function hasRequirementsGathering(messages: Message[]): boolean {
  let assistantQuestions = 0;
  let userResponses = 0;

  for (const msg of messages.slice(-10)) {
    const text = extractTextContent(msg.content);
    if (msg.role === "assistant" && text.includes("?")) {
      assistantQuestions++;
    }
    if (msg.role === "user" && assistantQuestions > 0) {
      userResponses++;
    }
  }

  // At least one Q&A exchange suggests interview happened
  return assistantQuestions >= 1 && userResponses >= 1;
}

function isSkippableFile(filePath: string): boolean {
  return SKIP_FILE_PATTERNS.some((pattern) => pattern.test(filePath));
}

function isSmallEdit(toolInput: Record<string, unknown>, toolName: string): boolean {
  if (toolName === "Edit") {
    const newString = (toolInput.new_string as string) || "";
    return newString.split("\n").length < MIN_LINES_THRESHOLD;
  }
  if (toolName === "Write") {
    const content = (toolInput.content as string) || "";
    return content.split("\n").length < MIN_LINES_THRESHOLD;
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

  if (!input.tool_name || !["Write", "Edit", "Bash"].includes(input.tool_name)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const toolInput = input.tool_input || {};

  // Skip for config/test files
  const filePath = (toolInput.file_path as string) || "";
  if (filePath && isSkippableFile(filePath)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Skip for small edits
  if (isSmallEdit(toolInput, input.tool_name)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Skip Bash commands (usually not feature implementation)
  if (input.tool_name === "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if AskUserQuestion was used
  if (checkToolUsed(recentMessages, "AskUserQuestion")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if conversation has enough requirements gathering
  if (hasRequirementsGathering(recentMessages)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Soft nudge -- not a hard block
  const feedback = createViolationFeedback({
    law: "Interview-First",
    lawNumber: 6,
    title: "Consider Gathering Requirements First",
    problem: "You're about to implement a significant feature without first asking clarifying questions.",
    requiredActions: [
      "Ask the user about their requirements before implementing",
      "Use **AskUserQuestion** to gather preferences and constraints",
      "Understand the 'why' before diving into the 'how'",
      "Clarify scope, edge cases, and expected behavior",
    ],
    examples: [
      '"Before I build this, let me understand: what users will access this?"',
      '"What error handling approach do you prefer?"',
      '"Should this support X or is Y sufficient?"',
    ],
    reference: "skills/core/references/laws/law-06-interview-first.md",
  });

  console.log(JSON.stringify(askDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
