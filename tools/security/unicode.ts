/**
 * Unicode obfuscation detector -- finds invisible/dangerous characters in skill files.
 *
 * Detects zero-width chars, bidi overrides, BOMs in wrong positions,
 * and Cyrillic/Greek homoglyphs that mimic Latin letters.
 */

import { readFile } from "node:fs/promises";
import type { Finding } from "./types.ts";

/** Map of dangerous code points to human-readable descriptions. */
export const INVISIBLE_CHARS: Map<number, string> = new Map([
  [0x200b, "zero-width space"],
  [0x200c, "zero-width non-joiner"],
  [0x200d, "zero-width joiner"],
  [0x200e, "left-to-right mark"],
  [0x200f, "right-to-left mark"],
  [0x202d, "left-to-right override"],
  [0x202e, "right-to-left override"],
  [0x2060, "word joiner"],
  [0xfeff, "zero-width no-break space (BOM)"],
  [0x00ad, "soft hyphen"],
]);

const INVISIBLE_REGEX = /[\u200B\u200C\u200D\u200E\u200F\u202D\u202E\u2060\uFEFF\u00AD]/g;
const RTL_OVERRIDE_POINTS = new Set([0x202d, 0x202e]);

/** Cyrillic characters that visually mimic Latin letters. */
const HOMOGLYPH_MAP: Map<string, string> = new Map([
  ["\u0430", "Cyrillic 'a' (U+0430)"],
  ["\u0435", "Cyrillic 'e' (U+0435)"],
  ["\u043E", "Cyrillic 'o' (U+043E)"],
  ["\u0440", "Cyrillic 'r/p' (U+0440)"],
  ["\u0441", "Cyrillic 'c/s' (U+0441)"],
  ["\u0443", "Cyrillic 'y/u' (U+0443)"],
  ["\u0456", "Cyrillic 'i' (U+0456)"],
  ["\u0455", "Cyrillic 's' (U+0455)"],
  ["\u04BB", "Cyrillic 'h' (U+04BB)"],
]);

const HOMOGLYPH_REGEX = /[\u0430\u0435\u043E\u0440\u0441\u0443\u0456\u0455\u04BB]/g;
const COMMENT_LINE = /^\s*(#|\/\/|<!--|\*|\/\*)/;

function contextSnippet(line: string, index: number, codePoint: number): string {
  const marker = `[U+${codePoint.toString(16).toUpperCase().padStart(4, "0")}]`;
  const start = Math.max(0, index - 25);
  const end = Math.min(line.length, index + 25);
  const before = line.slice(start, index);
  const after = line.slice(index + 1, end);
  return `${before}${marker}${after}`.slice(0, 60);
}

/** Scan content for invisible/dangerous unicode characters. Groups by line. */
export function checkUnicode(filePath: string, content: string): Finding[] {
  const findings: Finding[] = [];
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const matches: { cp: number; index: number; desc: string }[] = [];
    let m: RegExpExecArray | null;
    INVISIBLE_REGEX.lastIndex = 0;
    while ((m = INVISIBLE_REGEX.exec(line)) !== null) {
      const cp = m[0].codePointAt(0)!;
      matches.push({ cp, index: m.index, desc: INVISIBLE_CHARS.get(cp) ?? "unknown" });
    }
    if (matches.length === 0) continue;

    // Group by character class on this line
    const byClass = new Map<string, typeof matches>();
    for (const hit of matches) {
      if (!byClass.has(hit.desc)) byClass.set(hit.desc, []);
      byClass.get(hit.desc)!.push(hit);
    }
    for (const [desc, hits] of byClass) {
      const hasRtl = hits.some((h) => RTL_OVERRIDE_POINTS.has(h.cp));
      const sample = hits[0];
      const countNote = hits.length > 1 ? `${hits.length}x ` : "";
      const patternId = `unicode_${desc.replace(/[^a-z0-9]+/g, "_").replace(/_+$/, "")}`;
      findings.push({
        patternId,
        category: "obfuscation",
        severity: hasRtl ? "critical" : "high",
        description: `${countNote}${desc} detected`,
        file: filePath,
        line: i + 1,
        match: contextSnippet(line, sample.index, sample.cp),
      });
    }
  }
  return findings;
}

/** Detect Cyrillic/Greek homoglyphs in code-like contexts (skip comment lines). */
export function checkHomoglyphs(filePath: string, content: string): Finding[] {
  const findings: Finding[] = [];
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (COMMENT_LINE.test(line)) continue;
    const hits: { char: string; index: number; desc: string }[] = [];
    let m: RegExpExecArray | null;
    HOMOGLYPH_REGEX.lastIndex = 0;
    while ((m = HOMOGLYPH_REGEX.exec(line)) !== null) {
      hits.push({ char: m[0], index: m.index, desc: HOMOGLYPH_MAP.get(m[0]) ?? "unknown" });
    }
    if (hits.length === 0) continue;
    const descs = [...new Set(hits.map((h) => h.desc))].join(", ");
    const countNote = hits.length > 1 ? `${hits.length}x ` : "";
    const sample = hits[0];
    findings.push({
      patternId: "unicode_homoglyph",
      category: "obfuscation",
      severity: "high",
      description: `${countNote}homoglyph: ${descs}`,
      file: filePath,
      line: i + 1,
      match: contextSnippet(line, sample.index, sample.char.codePointAt(0)!),
    });
  }
  return findings;
}

/** Read a file and scan for all unicode threats. Skips binary files. */
export async function scanFileForUnicode(filePath: string): Promise<Finding[]> {
  const buf = await readFile(filePath);
  const head = buf.subarray(0, 1024);
  if (head.includes(0)) return []; // binary file -- skip
  const content = buf.toString("utf-8");
  return [...checkUnicode(filePath, content), ...checkHomoglyphs(filePath, content)];
}
