#!/usr/bin/env bun
/**
 * law-04-critical-thinking.ts - LAW 4 Enforcement
 *
 * Enforces: LAW 4 - Critical Thinking Over Sycophancy
 *
 * Blocks implementation when uncritical agreement is detected
 * without identifying potential problems or concerns first.
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

const IMPLEMENTATION_TOOLS = ["Write", "Edit", "NotebookEdit"] as const;

const UNCRITICAL_AGREEMENT_PATTERNS = [
  "great idea",
  "perfect",
  "absolutely",
  "that's exactly right",
  "i completely agree",
  "sounds good",
  "that works",
] as const;

const CRITICAL_THINKING_MARKERS = [
  "however",
  "concern",
  "problem",
  "issue",
  "edge case",
  "but",
  "drawback",
  "limitation",
  "risk",
  "caveat",
  "trade-off",
  "downside",
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

function detectUncriticalAgreement(texts: string[]): string | null {
  for (const text of texts) {
    const lower = text.toLowerCase();
    for (const pattern of UNCRITICAL_AGREEMENT_PATTERNS) {
      if (lower.includes(pattern.toLowerCase())) return pattern;
    }
  }
  return null;
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

  // Only check implementation tools
  if (!input.tool_name || !IMPLEMENTATION_TOOLS.includes(input.tool_name as any)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const texts = getRecentAssistantText(recentMessages, 2);

  // Check for uncritical agreement
  const agreementPattern = detectUncriticalAgreement(texts);
  if (!agreementPattern) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if critical thinking markers are present alongside agreement
  const hasCriticalThinking = texts.some((text) => {
    const lower = text.toLowerCase();
    return CRITICAL_THINKING_MARKERS.some((marker) => lower.includes(marker));
  });

  if (hasCriticalThinking) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Critical Thinking Over Sycophancy",
    lawNumber: 4,
    title: "Critical Analysis Required",
    problem: "You agreed with the user's idea without identifying potential problems.",
    detected: agreementPattern,
    requiredActions: [
      "Identify potential problems with the proposed approach",
      "Consider edge cases, scaling issues, maintenance burden",
      "Question assumptions -- what might not hold true?",
      "Present alternatives or concerns BEFORE agreeing",
      "Only agree AFTER critical analysis shows idea is solid",
    ],
    examples: [
      '"This could work, but I\'m concerned about [X]. Have you considered [Y]?"',
      '"I see three issues: ... Which matters most to you?"',
      '"That handles the happy path, but what about [edge case]?"',
    ],
    reference: "skills/core/references/laws/law-04-critical-thinking.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
