#!/usr/bin/env bun
/**
 * law-12-private-repos-default.ts - LAW 12 Enforcement
 *
 * Enforces: LAW 12 - Private Repos Default
 *
 * Blocks `gh repo create` commands that don't include `--private`.
 * Hard gate -- repos must be private unless explicitly overridden
 * with `--public` (intentional user override).
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

  const command = ((input.tool_input?.command as string) || "");

  // Only check gh repo create commands
  if (!command.includes("gh repo create")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Allow if --public is explicitly set (intentional user override)
  if (command.includes("--public")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Allow if --private is already set
  if (command.includes("--private")) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION: gh repo create without --private
  const feedback = createViolationFeedback({
    law: "Private Repos Default",
    lawNumber: 12,
    title: "Repos Must Be Private by Default",
    problem: "`gh repo create` called without `--private` flag.",
    detected: command.substring(0, 120),
    requiredActions: [
      "Add `--private` flag to the `gh repo create` command",
      "Only use `--public` if the user explicitly said 'public'",
      "Default to private -- always err on the side of security",
    ],
    examples: [
      "gh repo create my-repo --private",
      'gh repo create my-repo --private --source=. --remote=origin --push',
    ],
    reference: "skills/core/references/laws/law-12-private-repos-default.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
