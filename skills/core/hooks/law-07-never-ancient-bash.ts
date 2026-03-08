#!/usr/bin/env bun
/**
 * law-07-never-ancient-bash.ts - LAW 7 Enforcement
 *
 * Enforces: LAW 7 - Never Use Ancient Bash
 *
 * Blocks Write/Edit operations that contain #!/bin/bash shebang.
 * Must use #!/usr/bin/env bash (or zsh/sh) instead.
 *
 * Hook Type: PreToolUse (blocking)
 * Matcher: Write|Edit
 */

import type { HookInput } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  blockDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const ANCIENT_BASH_SHEBANG = "#!/bin/bash";
const MODERN_BASH_SHEBANG = "#!/usr/bin/env bash";

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

  // Only check Write and Edit tools
  if (!input.tool_name || !["Write", "Edit"].includes(input.tool_name)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check content for ancient bash shebang
  const toolInput = input.tool_input || {};
  const content = ((toolInput.content as string) || "") +
    ((toolInput.new_string as string) || "");

  if (!content.includes(ANCIENT_BASH_SHEBANG)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Never Use Ancient Bash",
    lawNumber: 7,
    title: "Use Modern Bash via env",
    problem: `Script uses ancient bash shebang: ${ANCIENT_BASH_SHEBANG}`,
    detected: ANCIENT_BASH_SHEBANG,
    requiredActions: [
      `Replace ${ANCIENT_BASH_SHEBANG} with ${MODERN_BASH_SHEBANG}`,
      "Use #!/usr/bin/env bash for PATH-resolved modern bash",
      "Never use /bin/bash (version 3.2.57 from 2007)",
    ],
    examples: [
      `Bad: ${ANCIENT_BASH_SHEBANG}`,
      `Good: ${MODERN_BASH_SHEBANG}`,
      "Also valid: #!/usr/bin/env zsh, #!/usr/bin/env sh",
    ],
    reference: "skills/core/references/laws/law-07-never-ancient-bash.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
