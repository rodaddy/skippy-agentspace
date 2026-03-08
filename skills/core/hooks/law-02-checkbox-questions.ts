#!/usr/bin/env bun
/**
 * law-02-checkbox-questions.ts - LAW 2 Enforcement
 *
 * Enforces: LAW 2 - Checkbox Questions, No Text Walls
 *
 * Blocks when assistant presents multiple options as plain text
 * instead of using AskUserQuestion with checkbox/multiple-choice format.
 *
 * Hook Type: PreToolUse (blocking)
 * Matcher: * (all tools -- checks recent text output)
 */

import type { HookInput, Message, ContentBlock, TextBlock } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  blockDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Option patterns (detect plain-text option presentation)
// ---------------------------------------------------------------------------

const OPTION_PATTERNS = [
  /\b[A-D]\)/gi,
  /\b\d+\.\s+/g,
  /Would you like:.*\n.*\n/gi,
  /Choose:.*\n.*\n/gi,
  /Options?:.*\n.*\n/gi,
  /\bor\b.*\bor\b/gi,
  /which (approach|option|method|way)/gi,
  /do you want (me to|to)?.*\?/gi,
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

function detectOptionPatterns(texts: string[]): boolean {
  for (const text of texts) {
    for (const pattern of OPTION_PATTERNS) {
      pattern.lastIndex = 0;
      if (pattern.test(text)) return true;
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

  const texts = getRecentAssistantText(recentMessages, 2);

  if (!detectOptionPatterns(texts)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Options detected -- check if AskUserQuestion was used
  if (checkToolUsed(recentMessages, "AskUserQuestion", 3)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Find the specific pattern for feedback
  let detectedPattern = "";
  for (const text of texts) {
    if (text.includes("A)") || text.includes("B)")) {
      const lines = text.split("\n");
      const optionLines = lines.filter(
        (line) => /\b[A-D]\)/.test(line) || /\b\d+\./.test(line)
      );
      detectedPattern = optionLines.slice(0, 2).join(", ") + "...";
      break;
    }
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Checkbox Questions - No Text Walls",
    lawNumber: 2,
    title: "Use AskUserQuestion for Options",
    problem:
      "You presented multiple options as plain text, forcing the user to type a response manually.",
    detected: detectedPattern || "Multiple choice options in plain text",
    requiredActions: [
      "Use **AskUserQuestion** tool with checkbox/multiple-choice format",
      "Provide clear question with 2-4 options",
      "Include descriptions for each option showing trade-offs",
      "Set multiSelect: true if multiple answers allowed",
    ],
    examples: [
      'AskUserQuestion({ questions: [{ question: "Which approach?", options: [...] }] })',
      "Batch related questions together (max 4 questions per call)",
    ],
    reference: "skills/core/references/laws/law-02-checkbox-questions.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
