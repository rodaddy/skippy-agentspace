// novelty.ts -- Checks whether a proposed skill overlaps with existing installed skills.
// Prevents duplicate skill creation by comparing term overlap (Jaccard similarity).
// No external dependencies beyond node:fs/promises and node:path.

import { readdir, readFile, stat } from "node:fs/promises";
import { join, resolve } from "node:path";

const HOME = process.env.HOME ?? Bun.env.HOME ?? "/tmp";
const DEFAULT_SKILLS_DIR = resolve(HOME, ".config/pai/Skills");

const STOP_WORDS = new Set([
  "the", "a", "an", "is", "are", "was", "for", "with", "from", "to", "in",
  "on", "at", "of", "and", "or", "but", "not", "this", "that", "it", "be",
  "has", "have", "had", "do", "does", "did", "will", "would", "can", "could",
  "use", "used", "using",
]);

export interface SkillSummary {
  name: string;
  description: string;
  /** Key terms extracted from the skill description and purpose */
  terms: Set<string>;
  path: string;
}

export interface NoveltyResult {
  /** Is this skill novel enough to propose? */
  isNovel: boolean;
  /** Overlap score 0-1 (0 = completely novel, 1 = exact duplicate) */
  overlapScore: number;
  /** Most similar existing skill, if any */
  closestMatch?: {
    name: string;
    score: number;
    description: string;
  };
  /** Recommendation */
  recommendation: "create" | "update_existing" | "skip";
  /** Human-readable explanation */
  reason: string;
}

export function extractFrontmatter(
  content: string,
): { name?: string; description?: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};

  const yaml = match[1];
  const nameMatch = yaml.match(/^name:\s*(.+)$/m);
  const descMatch = yaml.match(/^description:\s*(.+)$/m);

  return {
    name: nameMatch?.[1]?.trim(),
    description: descMatch?.[1]?.trim(),
  };
}

export function extractTerms(text: string): Set<string> {
  const tokens = text
    .toLowerCase()
    .split(/[\s\-_/.,;:!?()[\]{}'"]+/)
    .filter((t) => t.length >= 3)
    .filter((t) => !STOP_WORDS.has(t));

  return new Set(tokens);
}

export function calculateOverlap(
  termsA: Set<string>,
  termsB: Set<string>,
): number {
  if (termsA.size === 0 && termsB.size === 0) return 0;

  let intersectionSize = 0;
  for (const term of termsA) {
    if (termsB.has(term)) intersectionSize++;
  }

  const unionSize = new Set([...termsA, ...termsB]).size;
  if (unionSize === 0) return 0;

  return intersectionSize / unionSize;
}

export async function loadExistingSkills(
  skillsDir: string,
): Promise<SkillSummary[]> {
  const results: SkillSummary[] = [];

  let entries: Awaited<ReturnType<typeof readdir>>;
  try {
    entries = await readdir(skillsDir, { withFileTypes: true });
  } catch {
    return [];
  }

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name === ".quarantine") continue;

    const skillPath = join(skillsDir, entry.name);
    const skillMdPath = join(skillPath, "SKILL.md");

    try {
      await stat(skillMdPath);
    } catch {
      continue;
    }

    const content = await readFile(skillMdPath, "utf-8");
    const frontmatter = extractFrontmatter(content);

    const name = frontmatter.name ?? entry.name;
    const description = frontmatter.description ?? "";
    const terms = extractTerms(`${name} ${description}`);

    results.push({ name, description, terms, path: skillPath });
  }

  return results;
}

export async function checkNovelty(
  proposedName: string,
  proposedDescription: string,
  skillsDir?: string,
): Promise<NoveltyResult> {
  const dir = skillsDir ?? DEFAULT_SKILLS_DIR;
  const existingSkills = await loadExistingSkills(dir);
  const proposedTerms = extractTerms(`${proposedName} ${proposedDescription}`);

  let highestScore = 0;
  let closest: SkillSummary | undefined;

  for (const skill of existingSkills) {
    const score = calculateOverlap(proposedTerms, skill.terms);
    if (score > highestScore) {
      highestScore = score;
      closest = skill;
    }
  }

  const overlapScore = Math.round(highestScore * 1000) / 1000;
  const isNovel = overlapScore < 0.7;

  let recommendation: NoveltyResult["recommendation"];
  let reason: string;

  if (overlapScore < 0.3) {
    recommendation = "create";
    reason = closest
      ? `Low overlap (${overlapScore}) with nearest skill "${closest.name}". Novel enough to create.`
      : "No existing skills found. Safe to create.";
  } else if (overlapScore <= 0.7) {
    recommendation = "update_existing";
    reason = `Moderate overlap (${overlapScore}) with "${closest!.name}". Consider updating the existing skill instead.`;
  } else {
    recommendation = "skip";
    reason = `High overlap (${overlapScore}) with "${closest!.name}". Would be a duplicate.`;
  }

  const result: NoveltyResult = {
    isNovel,
    overlapScore,
    recommendation,
    reason,
  };

  if (closest) {
    result.closestMatch = {
      name: closest.name,
      score: overlapScore,
      description: closest.description,
    };
  }

  return result;
}
