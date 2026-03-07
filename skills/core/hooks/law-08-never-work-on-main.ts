#!/usr/bin/env bun
/**
 * law-08-never-work-on-main.ts - LAW 8 Enforcement
 *
 * Enforces: LAW 8 - Never Work on Main/Master/Protected Branches
 *
 * Blocks git commit, git push, git merge on protected branches.
 * Forces creation of feature/WIP branches before any work.
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
// Configuration
// ---------------------------------------------------------------------------

const PROTECTED_BRANCHES = ["main", "master", "develop", "production", "staging"];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isGitCommit(command: string): boolean {
  return (
    command.includes("git commit") &&
    !command.includes("git commit --help") &&
    !command.includes("git commit-tree")
  );
}

function isGitPush(command: string): boolean {
  return command.includes("git push");
}

function isGitMerge(command: string): boolean {
  return command.includes("git merge");
}

/** Session merges are allowed (session-wrap workflow) */
function isSessionMerge(command: string): boolean {
  return command.includes("git merge") && command.includes("session/");
}

async function getCurrentBranch(repoPath: string): Promise<string | null> {
  try {
    const result = Bun.spawnSync(
      ["git", "-C", repoPath, "branch", "--show-current"],
      { stdout: "pipe", stderr: "pipe" }
    );
    const stdout = new TextDecoder().decode(result.stdout);
    return stdout.trim() || null;
  } catch {
    return null;
  }
}

function getRepoPath(command: string, cwd: string): string {
  const cdMatch = command.match(/cd\s+([^\s&|;]+)/);
  if (cdMatch) return cdMatch[1];
  const gitCMatch = command.match(/git\s+-C\s+([^\s]+)/);
  if (gitCMatch) return gitCMatch[1];
  return cwd || process.cwd();
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

  if (input.tool_name !== "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const command = ((input.tool_input?.command as string) || "");

  // Only check git commit/push/merge commands
  if (!isGitCommit(command) && !isGitPush(command) && !isGitMerge(command)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Allow session merges
  if (isSessionMerge(command)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Get current branch
  const repoPath = getRepoPath(command, input.cwd);
  const currentBranch = await getCurrentBranch(repoPath);

  if (!currentBranch) {
    // Can't determine branch -- fail open
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check if on protected branch
  if (!PROTECTED_BRANCHES.includes(currentBranch)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check for mid-merge from session branch (conflict resolution)
  try {
    const mergeMsg = await Bun.file(`${repoPath}/.git/MERGE_MSG`).text();
    if (mergeMsg.includes("session/")) {
      console.log(JSON.stringify(allowDecision()));
      return;
    }
  } catch {
    // No merge in progress -- continue to block
  }

  const timestamp = new Date().toISOString().split("T")[0].replace(/-/g, "");
  const suggestedBranch = `wip/work-${timestamp}`;

  // VIOLATION
  const feedback = createViolationFeedback({
    law: "Never Work on Main/Master/Protected Branches",
    lawNumber: 8,
    title: "Protected Branch Violation",
    problem: `You are attempting to commit/push/merge directly on protected branch: ${currentBranch}`,
    detected: `Current branch: ${currentBranch} (PROTECTED)`,
    requiredActions: [
      `Create a feature branch first: git checkout -b ${suggestedBranch}`,
      "Make your changes on the feature branch",
      "Push the feature branch and create a Pull Request",
      "Never commit directly to protected branches",
    ],
    examples: [
      "feat/ -- New feature",
      "fix/ -- Bug fix",
      "wip/ -- Work in progress",
      "refactor/ -- Code refactoring",
    ],
    reference: "skills/core/references/laws/law-08-never-work-on-main.md",
  });

  console.log(JSON.stringify(blockDecision(feedback)));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
