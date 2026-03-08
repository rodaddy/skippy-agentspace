#!/usr/bin/env bun
/**
 * law-11-no-secrets-in-git.ts - LAW 11 Enforcement
 *
 * Enforces: LAW 11 - No Secrets in Git
 *
 * Complementary to ggshield. Pre-checks for potential secrets patterns
 * before git add/commit/push. Uses askDecision (warn, don't block)
 * since ggshield is the real gate.
 *
 * Hook Type: PreToolUse (warning)
 * Matcher: Bash
 */

import type { HookInput } from "./lib/types.ts";
import { normalizeInput, isSubagent } from "./lib/context.ts";
import {
  allowDecision,
  askDecision,
  createViolationFeedback,
} from "./lib/feedback.ts";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** Git commands that could introduce secrets */
const GIT_COMMANDS = ["git add", "git commit", "git push"] as const;

/** File patterns likely containing secrets */
const SECRET_FILE_PATTERNS = [
  /\.env$/i,
  /\.env\.\w+$/i,
  /credentials\.json$/i,
  /secrets?\.\w+$/i,
  /\.pem$/i,
  /\.key$/i,
  /id_rsa/i,
  /id_ed25519/i,
  /\.p12$/i,
  /\.pfx$/i,
  /service[_-]?account.*\.json$/i,
] as const;

/** Patterns in command args that suggest secrets */
const SECRET_CONTENT_PATTERNS = [
  /api[_-]?key\s*=/i,
  /secret\s*=/i,
  /password\s*=/i,
  /token\s*=/i,
  /ANTHROPIC_API_KEY/i,
  /OPENAI_API_KEY/i,
  /AWS_SECRET/i,
  /GITHUB_TOKEN/i,
  /DATABASE_URL.*:\/\//i,
] as const;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isGitCommand(command: string): boolean {
  return GIT_COMMANDS.some((gc) => command.includes(gc));
}

function hasSecretFilePattern(command: string): string | null {
  for (const pattern of SECRET_FILE_PATTERNS) {
    const match = command.match(pattern);
    if (match) return match[0];
  }
  return null;
}

function hasSecretContentPattern(command: string): string | null {
  for (const pattern of SECRET_CONTENT_PATTERNS) {
    const match = command.match(pattern);
    if (match) return match[0];
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

  if (input.tool_name !== "Bash") {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  const command = ((input.tool_input?.command as string) || "");

  if (!isGitCommand(command)) {
    console.log(JSON.stringify(allowDecision()));
    return;
  }

  // Check for secret file patterns
  const secretFile = hasSecretFilePattern(command);
  if (secretFile) {
    const feedback = createViolationFeedback({
      law: "No Secrets in Git",
      lawNumber: 11,
      title: "Potential Secret File Detected",
      problem: "Git command references a file that commonly contains secrets.",
      detected: secretFile,
      requiredActions: [
        "Verify this file does NOT contain secrets",
        "Add sensitive files to .gitignore",
        "Use environment variables or a secrets manager instead",
        "ggshield will also check, but catching early is better",
      ],
      reference: "skills/core/references/laws/law-11-no-secrets-in-git.md",
    });

    console.log(JSON.stringify(askDecision(feedback)));
    return;
  }

  // Check for secret content patterns in command
  const secretContent = hasSecretContentPattern(command);
  if (secretContent) {
    const feedback = createViolationFeedback({
      law: "No Secrets in Git",
      lawNumber: 11,
      title: "Potential Secret in Command",
      problem: "Git command may contain or reference secrets.",
      detected: secretContent,
      requiredActions: [
        "Never hardcode secrets in committed files",
        "Use .env files (gitignored) or environment variables",
        "Use vaultwarden-secrets MCP or secret CLI for credential access",
      ],
      reference: "skills/core/references/laws/law-11-no-secrets-in-git.md",
    });

    console.log(JSON.stringify(askDecision(feedback)));
    return;
  }

  console.log(JSON.stringify(allowDecision()));
}

try {
  await main();
} catch {
  console.log(JSON.stringify(allowDecision()));
}
