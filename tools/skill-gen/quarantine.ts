import { mkdir, readdir, rm, stat, rename, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";

const HOME = process.env.HOME ?? Bun.env.HOME ?? "/tmp";
const QUARANTINE_DIR = resolve(HOME, ".config/pai/Skills/.quarantine");
const SKILLS_DIR = resolve(HOME, ".config/pai/Skills");

export interface QuarantineEntry {
  skillName: string;
  path: string;
  createdAt: string;
  hasProposal: boolean;
  hasScanResult: boolean;
  fileCount: number;
}

export async function ensureQuarantineDir(): Promise<void> {
  await mkdir(QUARANTINE_DIR, { recursive: true });
  const gitignorePath = join(QUARANTINE_DIR, ".gitignore");
  try {
    await stat(gitignorePath);
  } catch {
    await writeFile(gitignorePath, "*\n", "utf-8");
  }
}

export async function quarantineSkill(
  skillName: string,
  files: Map<string, string>,
): Promise<string> {
  await ensureQuarantineDir();
  const skillDir = join(QUARANTINE_DIR, skillName);

  try {
    const existing = await stat(skillDir);
    if (existing.isDirectory()) {
      throw new Error(
        `Skill "${skillName}" already exists in quarantine at ${skillDir}`,
      );
    }
  } catch (err: unknown) {
    if (err instanceof Error && "code" in err && (err as NodeJS.ErrnoException).code !== "ENOENT") {
      throw err;
    }
    // ENOENT is expected -- skill doesn't exist yet, proceed
    if (err instanceof Error && !("code" in err)) {
      // Re-throw our own "already exists" error
      throw err;
    }
  }

  await mkdir(skillDir, { recursive: true });

  for (const [relativePath, content] of files) {
    const filePath = join(skillDir, relativePath);
    const fileDir = resolve(filePath, "..");
    await mkdir(fileDir, { recursive: true });
    await writeFile(filePath, content, "utf-8");
  }

  return skillDir;
}

export async function listQuarantined(): Promise<QuarantineEntry[]> {
  try {
    await stat(QUARANTINE_DIR);
  } catch {
    return [];
  }

  const entries = await readdir(QUARANTINE_DIR, { withFileTypes: true });
  const results: QuarantineEntry[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const skillPath = join(QUARANTINE_DIR, entry.name);
    const skillStat = await stat(skillPath);
    const skillFiles = await readdir(skillPath, { recursive: true });

    // Filter to actual files (not directories) for the count
    let fileCount = 0;
    for (const f of skillFiles) {
      const fStat = await stat(join(skillPath, f));
      if (fStat.isFile()) fileCount++;
    }

    let hasProposal = false;
    let hasScanResult = false;
    try {
      await stat(join(skillPath, "PROPOSAL.md"));
      hasProposal = true;
    } catch {}
    try {
      await stat(join(skillPath, "SCAN-RESULT.md"));
      hasScanResult = true;
    } catch {}

    results.push({
      skillName: entry.name,
      path: skillPath,
      createdAt: skillStat.mtime.toISOString(),
      hasProposal,
      hasScanResult,
      fileCount,
    });
  }

  results.sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );

  return results;
}

export async function promoteSkill(skillName: string): Promise<string> {
  const sourcePath = join(QUARANTINE_DIR, skillName);
  const targetPath = join(SKILLS_DIR, skillName);

  try {
    await stat(sourcePath);
  } catch {
    throw new Error(
      `Skill "${skillName}" not found in quarantine at ${sourcePath}`,
    );
  }

  try {
    const existing = await stat(targetPath);
    if (existing.isDirectory()) {
      throw new Error(
        `Skill "${skillName}" already installed at ${targetPath} -- remove it first`,
      );
    }
  } catch (err: unknown) {
    if (err instanceof Error && "code" in err && (err as NodeJS.ErrnoException).code !== "ENOENT") {
      throw err;
    }
    if (err instanceof Error && !("code" in err)) {
      throw err;
    }
  }

  await rename(sourcePath, targetPath);
  return targetPath;
}

export async function removeQuarantined(skillName: string): Promise<void> {
  const skillPath = join(QUARANTINE_DIR, skillName);

  try {
    await stat(skillPath);
  } catch {
    throw new Error(
      `Skill "${skillName}" not found in quarantine at ${skillPath}`,
    );
  }

  await rm(skillPath, { recursive: true, force: true });
}

export async function cleanExpired(maxAgeDays: number = 30): Promise<string[]> {
  const entries = await listQuarantined();
  const cutoff = Date.now() - maxAgeDays * 24 * 60 * 60 * 1000;
  const removed: string[] = [];

  for (const entry of entries) {
    if (new Date(entry.createdAt).getTime() < cutoff) {
      await rm(entry.path, { recursive: true, force: true });
      removed.push(entry.skillName);
    }
  }

  return removed;
}

export { QUARANTINE_DIR };
