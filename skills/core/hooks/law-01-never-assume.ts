#!/usr/bin/env bun
/**
 * law-01-never-assume.ts - LAW 1 Enforcement
 *
 * Enforces: LAW 1 - Never Assume, Ask When Ambiguous
 *
 * Blocks implementation tools (Write, Edit, Bash) when ambiguity is detected
 * in recent messages and no clarification was sought via AskUserQuestion.
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
// Ambiguity markers
// ---------------------------------------------------------------------------

const AMBIGUITY_MARKERS = [
  "make it better",
  "fix it",
  "improve",
  "optimize",
  "refactor",
  "add error handling",
  "add logging",
  "make it work",
  "add authentication",
  "add tests",
  "add validation",
  "should i",
  "do you want me to",
  "i'll assume",
  "i'll implement",
  "probably means",
  "i think you want",
] as const;

// ---------------------------------------------------------------------------
// Helpers (inlined from shared modules)
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

/**
 * Detect ambiguity in recent text.
 * Returns null if request is clear, otherwise a reason string.
 */
function detectAmbiguity(texts: string[]): string | null {
  const combined = texts.join(" ").toLowerCase();

  // Clear if file:line provided
  if (/\w+\.(ts|js|py|go|rs|java|cpp|c|rb|php|swift):\d+/i.test(combined)) return null;
  // Clear if user deferred
  if (/\b(use your (judgment|judgement)|you decide|your choice|up to you)\b/i.test(combined)) return null;
  // Clear if continuation
  if (/\b(continuing|same (approach|pattern|method) as|already approved|per plan)\b/i.test(combined)) return null;

  for (const text of texts) {
    const lower = text.toLowerCase();
    for (const marker of AMBIGUITY_MARKERS) {
      if (lower.includes(marker.toLowerCase())) {
        return `Keyword ambiguity detected: "${marker}"`;
      }
    }
  }

  return "No clarity markers found (file:line, explicit parameters, or pre-approved plan)";
}

// ---------------------------------------------------------------------------
// Risky bash detection
// ---------------------------------------------------------------------------

const RISKY_BASH_COMMANDS = [
  "python", "node", "bun", "deno",
  "rm ", "mv ", "cp ",
  "psql", "mysql", "mongo",
  "git commit", "git push",
] as const;

function isImplementationTool(toolName: string, toolInput: Record<string, unknown>): boolean {
  if (toolName === "Write" || toolName === "Edit" || toolName === "NotebookEdit") return true;
  if (toolName === "Bash") {
    const cmd = ((toolInput.command as string) || "").toLowerCase();
    return RISKY_BASH_COMMANDS.some((r) => cmd.includes(r.toLowerCase()));
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

  if (!input.tool_name || !input.tool_input || !isImplementationTool(input.tool_name, input.tool_input)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check for ambiguity
  const texts = recentMessages.slice(-3).map((m) => extractTextContent(m.content));
  const ambiguity = detectAmbiguity(texts);

  if (!ambiguity) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if clarification was already sought
  if (checkToolUsed(recentMessages, "AskUserQuestion")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Never Assume - Ask When Ambiguous",
    lawNumber: 1,
    title: "Never Assume",
    problem: "You're about to implement without clarifying ambiguous requirements.",
    detected: ambiguity,
    requiredActions: [
      "Use **AskUserQuestion** to clarify the ambiguity",
      "Present 2-4 options showing different interpretations/approaches",
      "Get user direction BEFORE proceeding with implementation",
    ],
    examples: [
      '"Which approach do you prefer?" (with specific options)',
      '"What specifically should I optimize for?" (speed/memory/readability)',
    ],
    reference: "skills/core/references/laws/law-01-never-assume.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
