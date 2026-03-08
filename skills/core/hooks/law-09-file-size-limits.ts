#!/usr/bin/env bun
/**
 * law-09-file-size-limits.ts - LAW 9 Enforcement
 *
 * Enforces: LAW 9 - File Size Limits (750 lines max)
 *
 * Blocks Write operations that would create files exceeding 750 lines.
 * Warns on Edit operations that push files over the limit.
 * Recommends proactive splitting at ~600 lines.
 *
 * Hook Type: PreToolUse (blocking)
 * Matcher: Write|Edit
 */

import type { HookInput } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  blockDecision,
  askDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const MAX_LINES = 750;
const WARN_LINES = 600;

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

  if (!input.tool_name || !["Write", "Edit"].includes(input.tool_name)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const toolInput = input.tool_input || {};

  if (input.tool_name === "Write") {
    // For Write, count lines in the content being written
    const content = (toolInput.content as string) || "";
    const lineCount = content.split("\n").length;

    if (lineCount > MAX_LINES) {
      const feedback = createViolationFeedback({
        law: "File Size Limits",
        lawNumber: 9,
        title: "File Too Large",
        problem: `File would be ${lineCount} lines, exceeding the ${MAX_LINES}-line limit.`,
        detected: `${lineCount} lines (max: ${MAX_LINES})`,
        requiredActions: [
          `Split the file into multiple files (each under ${MAX_LINES} lines)`,
          `Proactively split at ~${WARN_LINES} lines`,
          "Extract logical sections into separate modules",
          "Use index/barrel files to re-export",
        ],
        reference: "skills/core/references/laws/law-09-file-size-limits.md",
      });

      console.log(JSON.stringify(blockDecision(feedback)));
      return;
    }

    if (lineCount > WARN_LINES) {
      const feedback = createViolationFeedback({
        law: "File Size Limits",
        lawNumber: 9,
        title: "File Approaching Limit",
        problem: `File is ${lineCount} lines, approaching the ${MAX_LINES}-line limit. Consider splitting proactively.`,
        detected: `${lineCount} lines (warn at: ${WARN_LINES}, max: ${MAX_LINES})`,
        requiredActions: [
          "Consider splitting the file now before it exceeds the limit",
          "Extract logical sections into separate modules",
        ],
        reference: "skills/core/references/laws/law-09-file-size-limits.md",
      });

      console.log(JSON.stringify(askDecision(feedback)));
      return;
    }
  }

  if (input.tool_name === "Edit") {
    // For Edit, try to check current file size + estimate growth
    const filePath = toolInput.file_path as string;
    if (filePath) {
      try {
        const file = Bun.file(filePath);
        const existingContent = await file.text();
        const currentLines = existingContent.split("\n").length;

        // Estimate new size: current lines + new_string lines - old_string lines
        const oldString = (toolInput.old_string as string) || "";
        const newString = (toolInput.new_string as string) || "";
        const oldLines = oldString.split("\n").length;
        const newLines = newString.split("\n").length;
        const estimatedLines = currentLines - oldLines + newLines;

        if (estimatedLines > MAX_LINES) {
          const feedback = createViolationFeedback({
            law: "File Size Limits",
            lawNumber: 9,
            title: "Edit Would Exceed File Size Limit",
            problem: `File would grow to ~${estimatedLines} lines after edit (current: ${currentLines}, limit: ${MAX_LINES}).`,
            detected: `${currentLines} -> ~${estimatedLines} lines`,
            requiredActions: [
              "Split the file before making this edit",
              "Extract the growing section into a new module",
              `Keep each file under ${MAX_LINES} lines`,
            ],
            reference: "skills/core/references/laws/law-09-file-size-limits.md",
          });

          console.log(JSON.stringify(blockDecision(feedback)));
          return;
        }
      } catch {
        // Can't read file -- fail open
      }
    }
  }

  console.log(JSON.stringify(allowDecision()));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
