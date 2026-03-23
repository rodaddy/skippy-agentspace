/**
 * Structural checks for skill directories.
 *
 * Validates file counts, sizes, binary presence, symlink safety,
 * and executable bit usage. Supplements regex-based pattern scanning.
 */

import { readdir, lstat, realpath, readFile } from "node:fs/promises";
import { join, resolve, relative, extname } from "node:path";
import type { StructuralIssue, Severity } from "./types.ts";

// --- Constants ---

export const MAX_FILES = 50;
export const MAX_TOTAL_SIZE = 1_048_576; // 1MB
export const MAX_FILE_SIZE = 262_144; // 256KB
export const BINARY_EXTENSIONS = [
  ".exe", ".dll", ".so", ".dylib", ".dmg",
  ".bin", ".com", ".msi", ".deb", ".rpm", ".wasm",
];

// --- Internal types ---

interface FileInfo {
  path: string;
  relativePath: string;
  size: number;
  isSymlink: boolean;
  mode: number;
}

// --- Check functions ---

function checkFileCount(files: FileInfo[]): StructuralIssue | null {
  const count = files.length;
  if (count <= 40) return null;
  const severity: Severity = count > MAX_FILES ? "high" : "medium";
  return {
    type: "file_count",
    severity,
    description: `Skill contains ${count} files (limit: ${MAX_FILES})`,
    value: count,
    limit: MAX_FILES,
  };
}

function checkTotalSize(files: FileInfo[]): StructuralIssue | null {
  const total = files.reduce((sum, f) => sum + f.size, 0);
  if (total <= MAX_TOTAL_SIZE) return null;
  return {
    type: "total_size",
    severity: "high",
    description: `Total size ${total} bytes exceeds ${MAX_TOTAL_SIZE} byte limit`,
    value: total,
    limit: MAX_TOTAL_SIZE,
  };
}

function checkFileSizes(files: FileInfo[]): StructuralIssue[] {
  return files
    .filter((f) => f.size > MAX_FILE_SIZE)
    .map((f) => ({
      type: "file_size" as const,
      severity: "high" as const,
      description: `File ${f.relativePath} is ${f.size} bytes (limit: ${MAX_FILE_SIZE})`,
      file: f.relativePath,
      value: f.size,
      limit: MAX_FILE_SIZE,
    }));
}

async function checkBinaryFiles(files: FileInfo[]): Promise<StructuralIssue[]> {
  const issues: StructuralIssue[] = [];
  const executableExts = new Set([".exe", ".dll", ".so", ".dylib"]);

  for (const f of files) {
    const ext = extname(f.path).toLowerCase();
    let isBinary = BINARY_EXTENSIONS.includes(ext);

    if (!isBinary) {
      try {
        const buf = await readFile(f.path);
        const sample = buf.subarray(0, 8192);
        isBinary = sample.includes(0);
      } catch {
        // unreadable file -- skip content check
      }
    }

    if (isBinary) {
      const severity: Severity = executableExts.has(ext) ? "critical" : "high";
      issues.push({
        type: "binary_file",
        severity,
        description: `Binary file detected: ${f.relativePath}`,
        file: f.relativePath,
        value: f.size,
      });
    }
  }

  return issues;
}

async function checkSymlinks(
  files: FileInfo[],
  skillPath: string,
): Promise<StructuralIssue[]> {
  const issues: StructuralIssue[] = [];
  const resolvedRoot = await realpath(skillPath);

  for (const f of files.filter((fi) => fi.isSymlink)) {
    try {
      const target = await realpath(f.path);
      if (!target.startsWith(resolvedRoot + "/") && target !== resolvedRoot) {
        issues.push({
          type: "symlink_escape",
          severity: "critical",
          description: `Symlink ${f.relativePath} escapes skill directory -> ${target}`,
          file: f.relativePath,
        });
      }
    } catch {
      issues.push({
        type: "symlink_escape",
        severity: "critical",
        description: `Symlink ${f.relativePath} has unresolvable target`,
        file: f.relativePath,
      });
    }
  }

  return issues;
}

function checkExecutableBit(files: FileInfo[]): StructuralIssue[] {
  const shellExts = new Set([".sh", ".bash"]);
  return files
    .filter((f) => {
      const isExecutable = (f.mode & 0o111) !== 0;
      const ext = extname(f.path).toLowerCase();
      return isExecutable && !shellExts.has(ext);
    })
    .map((f) => ({
      type: "executable_bit" as const,
      severity: "medium" as const,
      description: `Non-shell file has executable bit: ${f.relativePath}`,
      file: f.relativePath,
    }));
}

// --- Orchestrator ---

export async function checkStructural(
  skillPath: string,
): Promise<StructuralIssue[]> {
  const root = resolve(skillPath);
  const entries = await readdir(root, { recursive: true, withFileTypes: true });

  const files: FileInfo[] = [];
  for (const entry of entries) {
    if (entry.isDirectory()) continue;
    const fullPath = join(entry.parentPath ?? entry.path, entry.name);
    const stats = await lstat(fullPath);
    files.push({
      path: fullPath,
      relativePath: relative(root, fullPath),
      size: stats.size,
      isSymlink: stats.isSymbolicLink(),
      mode: stats.mode,
    });
  }

  const issues: StructuralIssue[] = [];

  const countIssue = checkFileCount(files);
  if (countIssue) issues.push(countIssue);

  const sizeIssue = checkTotalSize(files);
  if (sizeIssue) issues.push(sizeIssue);

  issues.push(...checkFileSizes(files));
  issues.push(...(await checkBinaryFiles(files)));
  issues.push(...(await checkSymlinks(files, root)));
  issues.push(...checkExecutableBit(files));

  return issues;
}
