/**
 * Security gate scanner -- type definitions.
 *
 * Pure types, no runtime code. Used across all security scanning modules.
 */

/** Threat severity ranking from most to least urgent. */
export type Severity = "critical" | "high" | "medium" | "low";

/** Classification of detected threat behavior. */
export type Category =
  | "exfiltration"
  | "prompt_injection"
  | "destructive"
  | "persistence"
  | "network"
  | "obfuscation"
  | "supply_chain"
  | "privilege_escalation"
  | "credential_exposure"
  | "pai_specific"
  | "agent_config";

/** How much implicit trust a skill receives based on its origin. */
export type TrustLevel = "pai-core" | "pai-proposed" | "external";

/** Overall scan outcome for a skill. */
export type Verdict = "safe" | "caution" | "dangerous";

/** A regex-based pattern that detects a specific threat signal in skill content. */
export interface ThreatPattern {
  /** Unique identifier, snake_case (e.g. "curl_exfil_pipe"). */
  id: string;
  /** The detection regex applied to file content. */
  pattern: RegExp;
  /** What class of threat this pattern detects. */
  category: Category;
  /** How serious a match is. */
  severity: Severity;
  /** Human-readable explanation of what this pattern catches. */
  description: string;
  /** Guidance on when this pattern may fire on benign code. */
  falsePositiveHint?: string;
}

/** A single threat pattern match found during scanning. */
export interface Finding {
  /** The ThreatPattern.id that triggered this finding. */
  patternId: string;
  /** Classification of the detected behavior. */
  category: Category;
  /** Severity inherited from the matched pattern. */
  severity: Severity;
  /** Human-readable description of what was found. */
  description: string;
  /** Relative path within the skill directory. */
  file: string;
  /** Line number where the match occurred, if available. */
  line?: number;
  /** The matched text, truncated to 200 characters. */
  match: string;
  /** Inherited false-positive guidance from the pattern. */
  falsePositiveHint?: string;
}

/** A non-pattern structural concern (file sizes, counts, symlinks, etc.). */
export interface StructuralIssue {
  /** What kind of structural check failed. */
  type:
    | "file_count"
    | "total_size"
    | "file_size"
    | "binary_file"
    | "symlink_escape"
    | "executable_bit";
  /** How serious the structural issue is. */
  severity: Severity;
  /** Human-readable explanation of the issue. */
  description: string;
  /** The file involved, if applicable. */
  file?: string;
  /** The offending value (size in bytes, count, etc.). */
  value?: number;
  /** The threshold that was exceeded. */
  limit?: number;
}

/** Complete result of scanning a single skill. */
export interface ScanResult {
  /** Overall safety determination. */
  verdict: Verdict;
  /** Trust tier assigned to this skill. */
  trustLevel: TrustLevel;
  /** Name of the scanned skill. */
  skillName: string;
  /** Absolute path to the skill directory. */
  skillPath: string;
  /** ISO 8601 timestamp of when the scan completed. */
  scannedAt: string;
  /** All threat pattern matches found. */
  findings: Finding[];
  /** All structural concerns detected. */
  structuralIssues: StructuralIssue[];
  /** One-line human-readable summary of the scan outcome. */
  summary: string;
  /** How long the scan took, in milliseconds. */
  durationMs: number;
}

/** Options passed to the scanner to configure a scan run. */
export interface ScanOptions {
  /** Trust tier to apply -- affects severity thresholds. */
  trustLevel: TrustLevel;
  /** Absolute path to the skill directory to scan. */
  skillPath: string;
  /** Skill name override; defaults to the directory basename. */
  skillName?: string;
  /** Emit detailed output during scanning. */
  verbose?: boolean;
}

/** What the command guard decides to do with a command. */
export type CommandGuardVerdict = "allow" | "warn" | "block";

/** Result of checking a single command against the guard rules. */
export interface CommandCheckResult {
  /** Whether the command is allowed, warned, or blocked. */
  verdict: CommandGuardVerdict;
  /** What was detected in the command, if anything. */
  description?: string;
  /** The pattern that triggered, if any. */
  patternId?: string;
}
