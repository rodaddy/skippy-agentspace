#!/usr/bin/env bun
/**
 * law-03-procon-analysis.ts - LAW 3 Enforcement
 *
 * Enforces: LAW 3 - Pro/Con Analysis Before Implementation
 *
 * Blocks implementation tools when multiple approaches are discussed
 * but no structured pros/cons analysis was provided.
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

const MULTIPLE_APPROACH_KEYWORDS = [
  "option",
  "approach",
  "alternative",
  "could also",
  "or we could",
  "another way",
  "instead",
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

function hasMultipleApproaches(texts: string[]): boolean {
  for (const text of texts) {
    const lower = text.toLowerCase();
    for (const keyword of MULTIPLE_APPROACH_KEYWORDS) {
      if (lower.includes(keyword)) return true;
    }
  }
  return false;
}

function hasProsConsAnalysis(texts: string[]): boolean {
  for (const text of texts) {
    const lower = text.toLowerCase();
    if ((lower.includes("pros:") || lower.includes("\u2705")) &&
        (lower.includes("cons:") || lower.includes("\u274c"))) return true;
    if (lower.includes("advantages:") && lower.includes("disadvantages:")) return true;
    if (lower.includes("benefits:") && lower.includes("drawbacks:")) return true;
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

  // Only check implementation tools
  if (!input.tool_name || !IMPLEMENTATION_TOOLS.includes(input.tool_name as any)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const texts = getRecentAssistantText(recentMessages, 3);

  // No multiple approaches discussed -- allow
  if (!hasMultipleApproaches(texts)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Multiple approaches exist -- check for analysis
  if (hasProsConsAnalysis(texts)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if AskUserQuestion was used (acceptable alternative)
  if (checkToolUsed(recentMessages, "AskUserQuestion", 3)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Pro/Con Analysis Before Implementation",
    lawNumber: 3,
    title: "Pro/Con Analysis Required",
    problem: "Multiple valid approaches exist, but you haven't shown trade-offs.",
    requiredActions: [
      "Identify ALL viable alternatives (not just one approach)",
      "Present structured pros/cons for EACH option",
      "Make a recommendation based on context",
      "Use AskUserQuestion to let user choose (per LAW 2)",
    ],
    examples: [
      "Option A: [Name]\\nPros: ... \\nCons: ...",
      "Benefits vs Drawbacks comparison",
      "Advantages/Disadvantages for each approach",
    ],
    reference: "skills/core/references/laws/law-03-procon-analysis.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
