#!/usr/bin/env bun
/**
 * law-10-qmd-first.ts - LAW 10 Enforcement
 *
 * Enforces: LAW 10 - qmd First
 *
 * Warns when Read/Glob/Grep is used before trying qmd MCP search tools
 * (search, vsearch, query). Soft nudge -- reminds to try qmd first
 * but doesn't block if user chose file tools intentionally.
 *
 * Skips when no qmd MCP appears to be available in the session.
 *
 * Hook Type: PreToolUse (soft warning)
 * Matcher: Read|Glob|Grep
 */

import type { HookInput, Message, ContentBlock } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  askDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** qmd MCP tool names to check for prior usage */
const QMD_TOOLS = ["search", "vsearch", "query"] as const;

/** File tool names this hook monitors */
const FILE_TOOLS = ["Read", "Glob", "Grep"] as const;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function checkToolUsed(messages: Message[], toolName: string, lookback = 10): boolean {
  for (const msg of messages.slice(-lookback)) {
    if (msg.role !== "assistant") continue;
    const content = Array.isArray(msg.content) ? msg.content : [];
    for (const block of content) {
      if (block.type === "tool_use" && block.name === toolName) return true;
    }
  }
  return false;
}

function hasQmdBeenUsed(messages: Message[]): boolean {
  return QMD_TOOLS.some((tool) => checkToolUsed(messages, tool, messages.length));
}

function hasFileToolBeenUsed(messages: Message[]): boolean {
  return FILE_TOOLS.some((tool) => checkToolUsed(messages, tool as string, 5));
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

  if (!input.tool_name || !FILE_TOOLS.includes(input.tool_name as any)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // If qmd was used recently in the session, the user has access and used it -- allow file tools
  if (hasQmdBeenUsed(recentMessages)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // If file tools were already used recently (not first call), skip repeated warnings
  if (hasFileToolBeenUsed(recentMessages)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Soft nudge to try qmd first
  const feedback = createViolationFeedback({
    law: "qmd First",
    lawNumber: 10,
    title: "Try qmd MCP Search First",
    problem: "You're using file tools (Read/Glob/Grep) without first trying qmd MCP search.",
    requiredActions: [
      "Try qmd MCP tools first: search, vsearch, query",
      "qmd searches are faster and more targeted for codebase exploration",
      "Fall back to Read/Glob/Grep only if qmd doesn't have the answer",
    ],
    examples: [
      'qmd search("function name") -- fast codebase search',
      'qmd vsearch("pattern") -- vector similarity search',
      'qmd query("what does X do?") -- natural language query',
    ],
    reference: "skills/core/references/laws/law-10-qmd-first.md",
  });

  console.log(JSON.stringify(askDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
