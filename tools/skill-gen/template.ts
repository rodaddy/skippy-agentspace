// template.ts -- Skill template generator for auto-skill-generation pipeline
// Pure TypeScript string manipulation, no external dependencies.

export const DEFAULT_VERSION = "0.1.0";

const RESERVED_NAMES = ["core", "skippy", "pai", "claude"];
const KEBAB_CASE_RE = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;

export interface SkillMetadata {
  name: string;
  description: string;
  version: string;
  source: "pai-core" | "pai-proposed" | "external";
  generated: string;
  session?: string;
  tags?: string[];
}

export interface SkillContent {
  metadata: SkillMetadata;
  purpose: string;
  usage: string;
  workflow: string[];
  references?: string[];
  triggerPatterns?: string[];
}

export function validateSkillName(
  name: string
): { valid: boolean; reason?: string } {
  if (name.length < 2 || name.length > 50) {
    return { valid: false, reason: "Name must be 2-50 characters" };
  }
  if (name.includes("_")) {
    return { valid: false, reason: "Underscores not allowed, use hyphens" };
  }
  if (name !== name.toLowerCase()) {
    return { valid: false, reason: "Uppercase not allowed" };
  }
  if (name.includes(" ")) {
    return { valid: false, reason: "Spaces not allowed" };
  }
  if (!KEBAB_CASE_RE.test(name)) {
    return { valid: false, reason: "Must be valid kebab-case" };
  }
  if (RESERVED_NAMES.includes(name)) {
    return { valid: false, reason: `"${name}" is a reserved name` };
  }
  return { valid: true };
}

export function generateFrontmatter(metadata: SkillMetadata): string {
  const lines: string[] = ["---"];

  lines.push(`name: ${metadata.name}`);
  lines.push(`description: ${metadata.description}`);
  lines.push("metadata:");
  lines.push(`  version: ${metadata.version}`);
  lines.push(`  source: ${metadata.source}`);
  lines.push(`  generated: ${metadata.generated}`);

  if (metadata.session) {
    lines.push(`  session: ${metadata.session}`);
  }
  if (metadata.tags && metadata.tags.length > 0) {
    lines.push(`  tags: [${metadata.tags.join(", ")}]`);
  }

  lines.push("---");
  return lines.join("\n");
}

export function generateSkillMd(content: SkillContent): string {
  const { metadata, purpose, usage, workflow, references, triggerPatterns } =
    content;

  const sections: string[] = [];

  // Frontmatter
  sections.push(generateFrontmatter(metadata));

  // Title
  sections.push(`\n# ${metadata.name}`);

  // Purpose
  sections.push(`\n${purpose}`);

  // Trigger patterns as "When to Use" if provided
  if (triggerPatterns && triggerPatterns.length > 0) {
    sections.push("\n## When to Use");
    sections.push(
      triggerPatterns.map((pattern) => `- ${pattern}`).join("\n")
    );
  }

  // Usage
  sections.push("\n## Usage");
  sections.push(`\n${usage}`);

  // Workflow (numbered list)
  sections.push("\n## Workflow");
  sections.push(
    workflow.map((step, i) => `${i + 1}. ${step}`).join("\n")
  );

  // References (optional)
  if (references && references.length > 0) {
    sections.push("\n## References");
    sections.push(
      references.map((ref) => `- ${ref}`).join("\n")
    );
  }

  return sections.join("\n") + "\n";
}
