// post-task-nudge.ts -- Evaluates whether a completed task session should be
// converted into a reusable skill. Called at session-wrap time (option c).
// Pure orchestration of detect.ts and novelty.ts -- no external dependencies.

import { detectReusablePattern, suggestSkillName } from "./detect.ts";
import type { TaskSignal, DetectionResult } from "./detect.ts";
import { checkNovelty } from "./novelty.ts";
import type { NoveltyResult } from "./novelty.ts";

export interface SessionContext {
  /** Brief description of what the session accomplished */
  description: string;
  /** Number of tool calls made during the session */
  toolCallCount: number;
  /** Unique tool types used (e.g., ["Bash", "Read", "Write", "Edit"]) */
  toolTypes: string[];
  /** Number of files created or modified */
  filesTouched: number;
  /** Whether domain-specific knowledge was involved */
  domainSpecific: boolean;
  /** Tags or categories if available */
  tags?: string[];
}

export interface NudgeResult {
  /** Should we suggest skill generation to the user? */
  shouldNudge: boolean;
  /** The detection result from heuristics */
  detection: DetectionResult;
  /** The novelty check result (if detection passed) */
  novelty?: NoveltyResult;
  /** Suggested skill name */
  suggestedName?: string;
  /** Human-readable nudge message for display */
  message: string;
}

/**
 * Transforms SessionContext into the TaskSignal expected by detect.ts.
 */
export function buildTaskSignal(context: SessionContext): TaskSignal {
  return {
    toolCallCount: context.toolCallCount,
    uniqueToolTypes: context.toolTypes.length,
    filesTouched: context.filesTouched,
    domainSpecific: context.domainSpecific,
    description: context.description,
    tags: context.tags,
  };
}

/**
 * Generates the nudge message shown to the user at session-wrap time.
 * Returns empty string when no nudge is warranted.
 */
export function formatNudgeMessage(
  detection: DetectionResult,
  novelty?: NoveltyResult,
): string {
  if (!detection.shouldPropose) return "";

  if (novelty && !novelty.isNovel && novelty.closestMatch) {
    const pct = Math.round(novelty.closestMatch.score * 100);
    return `Similar skill \`${novelty.closestMatch.name}\` already exists (overlap: ${pct}%). Consider updating it instead.`;
  }

  if (detection.suggestedName) {
    return `This session looks reusable as a skill. Suggested name: \`${detection.suggestedName}\`. Run \`/skill-gen draft\` to create it.`;
  }

  return "";
}

/**
 * Main entry point. Two-stage evaluation:
 * 1. Heuristic detection (is the session pattern reusable?)
 * 2. Novelty check (does a similar skill already exist?)
 */
export async function evaluateSession(
  context: SessionContext,
): Promise<NudgeResult> {
  const signal = buildTaskSignal(context);
  const detection = detectReusablePattern(signal);

  if (!detection.shouldPropose) {
    return {
      shouldNudge: false,
      detection,
      message: formatNudgeMessage(detection),
    };
  }

  const name = suggestSkillName(context.description);
  const novelty = await checkNovelty(name, context.description);

  if (!novelty.isNovel) {
    return {
      shouldNudge: false,
      detection,
      novelty,
      suggestedName: name,
      message: formatNudgeMessage(detection, novelty),
    };
  }

  return {
    shouldNudge: true,
    detection,
    novelty,
    suggestedName: name,
    message: formatNudgeMessage(detection),
  };
}
