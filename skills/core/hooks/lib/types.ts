/**
 * Shared type definitions for portable PAI LAW enforcement hooks.
 *
 * Compatibility note: Existing PAI hooks use camelCase (toolName).
 * These portable hooks use snake_case (tool_name) per official Claude Code docs.
 * A compat shim is available in context.ts (normalizeInput) if needed.
 */

// ---------------------------------------------------------------------------
// Hook Input (from Claude Code stdin)
// ---------------------------------------------------------------------------

/**
 * The JSON that Claude Code sends to hooks on stdin.
 * Uses snake_case per official docs: https://code.claude.com/docs/en/hooks
 */
export interface HookInput {
  // Common fields (all events)
  session_id: string;
  transcript_path: string;
  cwd: string;
  permission_mode:
    | "default"
    | "plan"
    | "acceptEdits"
    | "dontAsk"
    | "bypassPermissions";
  hook_event_name: string;

  // PreToolUse / PostToolUse specific
  tool_name?: string;
  tool_input?: Record<string, unknown>;

  // PostToolUse specific
  tool_response?: Record<string, unknown>;

  // SessionStart specific
  source?: "startup" | "resume" | "clear" | "compact";
  model?: string;

  // Subagent fields
  agent_id?: string;
  agent_type?: string;
}

// ---------------------------------------------------------------------------
// Message types (for recentMessages parsing -- unchanged from existing hooks)
// ---------------------------------------------------------------------------

export interface Message {
  role: "user" | "assistant";
  content: ContentBlock[] | string;
}

export type ContentBlock = TextBlock | ToolUseBlock;

export interface TextBlock {
  type: "text";
  text: string;
}

export interface ToolUseBlock {
  type: "tool_use";
  name: string;
  input?: Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Hook Output: PreToolUse (uses hookSpecificOutput wrapper)
// ---------------------------------------------------------------------------

/**
 * Output format for PreToolUse hooks per official Claude Code docs.
 * Uses hookSpecificOutput wrapper -- NOT the older flat format.
 */
export interface PreToolUseOutput {
  hookSpecificOutput: {
    hookEventName: "PreToolUse";
    permissionDecision: "allow" | "deny" | "ask";
    permissionDecisionReason?: string;
    updatedInput?: Record<string, unknown>;
    additionalContext?: string;
  };
}

// ---------------------------------------------------------------------------
// Hook Output: PostToolUse / Stop / UserPromptSubmit (top-level decision)
// ---------------------------------------------------------------------------

/**
 * Output format for non-PreToolUse events that need to block.
 */
export interface TopLevelDecisionOutput {
  decision: "block";
  reason: string;
}

// ---------------------------------------------------------------------------
// Universal output fields (any event)
// ---------------------------------------------------------------------------

export interface UniversalOutput {
  continue?: boolean;
  stopReason?: string;
  suppressOutput?: boolean;
  systemMessage?: string;
}

// ---------------------------------------------------------------------------
// Violation details (for feedback builder)
// ---------------------------------------------------------------------------

/**
 * Details for constructing a LAW violation feedback message.
 * Moved here from feedback-builder.ts for centralized type definitions.
 */
export interface ViolationDetails {
  law: string;
  lawNumber: number;
  title: string;
  problem: string;
  detected?: string;
  requiredActions: string[];
  examples?: string[];
  reference?: string;
}
