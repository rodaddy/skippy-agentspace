// detect.ts -- Heuristics for detecting reusable patterns in completed tasks.
// Decides whether a post-task "auto-skill-generation" nudge should fire.
// Pure logic, no external dependencies.

export interface TaskSignal {
  /** Number of distinct tool calls in the task */
  toolCallCount: number;
  /** Number of unique tool types used (Bash, Read, Write, Edit, etc.) */
  uniqueToolTypes: number;
  /** Number of files touched (created or modified) */
  filesTouched: number;
  /** Whether the task involved domain-specific knowledge (infra, deployment, API patterns) */
  domainSpecific: boolean;
  /** Brief description of what was accomplished */
  description: string;
  /** Tags/categories if available */
  tags?: string[];
}

export interface DetectionResult {
  /** Should we propose skill generation? */
  shouldPropose: boolean;
  /** Confidence score 0-1 */
  confidence: number;
  /** Human-readable reason for the decision */
  reason: string;
  /** Suggested skill name (kebab-case) if shouldPropose is true */
  suggestedName?: string;
}

const ONE_OFF_PATTERNS =
  /\b(fix|bug|debug|typo|hotfix|patch|workaround|hack|temp|temporary)\b/i;

const REUSABLE_PATTERNS =
  /\b(setup|deploy|configure|migrate|pipeline|workflow|install|provision|scaffold|bootstrap|create|generate|build)\b/i;

const EXPLORATORY_PATTERNS = /\b(test|experiment|try)\b/i;

const FILLER_WORDS = new Set([
  "the", "a", "an", "for", "with", "from", "to", "in", "on", "at",
  "and", "or", "of", "is", "was", "by", "up", "new",
]);

/**
 * Returns true if the description suggests a non-reusable task.
 */
export function isLikelyOneOff(description: string): boolean {
  return ONE_OFF_PATTERNS.test(description);
}

/**
 * Returns true if the description suggests a reusable workflow.
 */
export function isLikelyReusable(description: string): boolean {
  return REUSABLE_PATTERNS.test(description);
}

/**
 * Extract a kebab-case skill name from a task description.
 * Strips filler words, lowercases, joins with hyphens, truncates to 30 chars.
 */
export function suggestSkillName(description: string): string {
  const words = description
    .replace(/[^a-zA-Z0-9\s]/g, "")
    .split(/\s+/)
    .map((w) => w.toLowerCase())
    .filter((w) => w.length > 0 && !FILLER_WORDS.has(w));

  if (words.length === 0) return "unnamed-skill";

  let name = words.join("-");
  if (name.length > 30) {
    // Truncate at the last full word boundary within 30 chars
    name = name.slice(0, 30);
    const lastHyphen = name.lastIndexOf("-");
    if (lastHyphen > 0) {
      name = name.slice(0, lastHyphen);
    }
  }

  return name;
}

/**
 * Main entry point. Evaluates a TaskSignal against heuristics and returns
 * whether to propose auto-generating a skill.
 */
export function detectReusablePattern(signal: TaskSignal): DetectionResult {
  const desc = signal.description;

  // Hard reject: too simple
  if (signal.toolCallCount < 3) {
    return {
      shouldPropose: false,
      confidence: 0,
      reason: "Too few tool calls -- task is too simple to warrant a skill",
    };
  }

  let confidence = 0;
  const reasons: string[] = [];

  // Positive heuristics
  if (signal.toolCallCount >= 5) {
    confidence += 0.2;
    reasons.push("multi-step task (5+ tool calls)");
  }
  if (signal.uniqueToolTypes >= 3) {
    confidence += 0.15;
    reasons.push("uses 3+ tool types");
  }
  if (signal.filesTouched >= 2) {
    confidence += 0.1;
    reasons.push("touches multiple files");
  }
  if (signal.domainSpecific) {
    confidence += 0.25;
    reasons.push("domain-specific knowledge");
  }
  if (isLikelyReusable(desc)) {
    confidence += 0.15;
    reasons.push("description suggests reusable workflow");
  }

  // Negative heuristics
  if (isLikelyOneOff(desc)) {
    confidence -= 0.3;
    reasons.push("description suggests one-off fix");
  }
  if (EXPLORATORY_PATTERNS.test(desc)) {
    confidence -= 0.2;
    reasons.push("description suggests exploratory work");
  }

  // Clamp to [0, 1]
  confidence = Math.max(0, Math.min(1, confidence));

  const shouldPropose = confidence >= 0.5;

  return {
    shouldPropose,
    confidence: Math.round(confidence * 100) / 100,
    reason: shouldPropose
      ? `Skill candidate: ${reasons.join(", ")}`
      : `Below threshold: ${reasons.length > 0 ? reasons.join(", ") : "insufficient signal"}`,
    suggestedName: shouldPropose ? suggestSkillName(desc) : undefined,
  };
}
