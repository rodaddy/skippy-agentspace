/**
 * Shared context utility for portable PAI LAW enforcement hooks.
 *
 * Enriches hook context with persona and project info.
 * Provides compatibility shim for snake_case / camelCase field names.
 */

import { readFileSync } from "fs";
import type { HookInput } from "./types.ts";

// ---------------------------------------------------------------------------
// Hook Context
// ---------------------------------------------------------------------------

export interface HookContext {
  /** Active persona: "skippy" | "bob" | "clarisa" | "april" */
  persona: string;
  /** Current project directory */
  projectDir: string;
  /** Path to skills/core/hooks/lib/ directory */
  skillDir: string;
}

/**
 * Build shared hook context from environment and session state.
 *
 * Persona detection priority:
 *   1. PAI_PERSONA env var (explicit override)
 *   2. $HOME/.config/pai/.current-session JSON file (persona field)
 *   3. Default: "skippy"
 */
export function getContext(): HookContext {
  const persona =
    process.env.PAI_PERSONA ||
    detectPersonaFromSession() ||
    "skippy";

  return {
    persona,
    projectDir: process.env.CLAUDE_PROJECT_DIR || process.cwd(),
    skillDir: import.meta.dir,
  };
}

// ---------------------------------------------------------------------------
// Subagent detection
// ---------------------------------------------------------------------------

/**
 * Check if the current execution is inside a Claude Code subagent.
 * Many hooks skip enforcement for subagents to avoid blocking delegated work.
 */
export function isSubagent(): boolean {
  return process.env.CLAUDE_CODE_AGENT !== undefined;
}

// ---------------------------------------------------------------------------
// Input normalization (camelCase -> snake_case compatibility)
// ---------------------------------------------------------------------------

/**
 * Normalize hook input to snake_case field names.
 *
 * Handles both the official snake_case format (tool_name, tool_input)
 * and the legacy camelCase format (toolName, toolInput) used by older hooks.
 * Always returns snake_case per official Claude Code docs.
 */
export function normalizeInput(raw: Record<string, unknown>): HookInput {
  return {
    // Common fields -- try snake_case first, fall back to any existing value
    session_id: (raw.session_id ?? raw.sessionId ?? "") as string,
    transcript_path: (raw.transcript_path ?? raw.transcriptPath ?? "") as string,
    cwd: (raw.cwd ?? "") as string,
    permission_mode: (raw.permission_mode ?? raw.permissionMode ?? "default") as HookInput["permission_mode"],
    hook_event_name: (raw.hook_event_name ?? raw.hookEventName ?? "") as string,

    // Tool-specific fields -- snake_case with camelCase fallback
    tool_name: (raw.tool_name ?? raw.toolName) as string | undefined,
    tool_input: (raw.tool_input ?? raw.toolInput) as Record<string, unknown> | undefined,
    tool_response: (raw.tool_response ?? raw.toolResponse) as Record<string, unknown> | undefined,

    // Session fields
    source: (raw.source) as HookInput["source"],
    model: (raw.model) as string | undefined,

    // Subagent fields
    agent_id: (raw.agent_id ?? raw.agentId) as string | undefined,
    agent_type: (raw.agent_type ?? raw.agentType) as string | undefined,
  };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function detectPersonaFromSession(): string | null {
  try {
    const home = process.env.HOME || "";
    const sessionFile = `${home}/.config/pai/.current-session`;
    const data = JSON.parse(readFileSync(sessionFile, "utf-8"));
    return (data.persona as string) || null;
  } catch {
    return null;
  }
}
