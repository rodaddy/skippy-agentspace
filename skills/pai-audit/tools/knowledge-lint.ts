#!/usr/bin/env bun
import { readFileSync, existsSync, statSync, readdirSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const MEMORY_DIRS = [
  join(homedir(), ".config", "pai-private", "memory"),
  join(homedir(), ".claude", "projects", "-Volumes-ThunderBolt-Development", "memory"),
];

const STALE_DAYS = 60;

interface MemoryFile {
  path: string;
  filename: string;
  name: string;
  description: string;
  type: string;
  content: string;
  ageDays: number;
  lastModified: string;
  referencedPaths: string[];
  crossRefs: string[];
  topics: string[];
  lineCount: number;
  source: string;
}

interface BrokenRef {
  file: string;
  name: string;
  ref: string;
  location: "local" | "remote";
}

interface LintReport {
  scanned: number;
  staleEntries: Array<{ file: string; name: string; ageDays: number; description: string }>;
  brokenRefs: BrokenRef[];
  orphanedFiles: Array<{ file: string; name: string; description: string }>;
  crossRefMap: Record<string, string[]>;
  topicClusters: Record<string, string[]>;
  allEntries: Array<{ file: string; name: string; type: string; ageDays: number; description: string; lineCount: number }>;
}

function parseArgs(): { command: string; flags: Record<string, string> } {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === "--help") {
    console.log(`knowledge-lint -- scan memory files for staleness, broken refs, and topic overlap

Usage:
  knowledge-lint scan              Full scan of all memory directories
  knowledge-lint scan --json       Output as JSON (for AI processing)
  knowledge-lint stale             Show entries older than ${STALE_DAYS} days
  knowledge-lint broken-refs       Show entries with broken file references
  knowledge-lint topics            Show topic clusters (potential overlaps)
  knowledge-lint orphans           Show entries not referenced by MEMORY.md

Memory directories scanned:
  ~/.config/pai-private/memory/
  ~/.claude/projects/-Volumes-ThunderBolt-Development/memory/`);
    process.exit(0);
  }

  const command = args[0];
  const flags: Record<string, string> = {};
  for (let i = 1; i < args.length; i++) {
    if (args[i].startsWith("--")) {
      if (i + 1 < args.length && !args[i + 1].startsWith("--")) {
        flags[args[i].slice(2)] = args[i + 1];
        i++;
      } else {
        flags[args[i].slice(2)] = "true";
      }
    }
  }
  return { command, flags };
}

function parseFrontmatter(content: string): { name: string; description: string; type: string; body: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)/);
  if (!match) return { name: "", description: "", type: "", body: content };

  const fm = match[1];
  const body = match[2];

  const nameMatch = fm.match(/^name:\s*(.+)$/m);
  const descMatch = fm.match(/^description:\s*(.+)$/m);
  const typeMatch = fm.match(/^type:\s*(.+)$/m);

  return {
    name: nameMatch?.[1]?.trim() || "",
    description: descMatch?.[1]?.trim() || "",
    type: typeMatch?.[1]?.trim() || "",
    body,
  };
}

function extractPaths(content: string): string[] {
  const pathPatterns = [
    /(?:~\/[^\s,)}\]"']+)/g,
    /(?:\/(?:Users|Volumes|home|etc|var|opt|mnt)[^\s,)}\]"']+)/g,
  ];

  const paths = new Set<string>();
  for (const pattern of pathPatterns) {
    const matches = content.matchAll(pattern);
    for (const match of matches) {
      let p = match[0].replace(/[.,:;!?)}\]`'"]+$/, "");
      if (p.includes("*") || p.includes("{") || p.length < 5) continue;
      paths.add(p);
    }
  }
  return [...paths];
}

function extractCrossRefs(content: string, allFilenames: string[]): string[] {
  const refs = new Set<string>();
  for (const fn of allFilenames) {
    const stem = fn.replace(/\.md$/, "");
    if (content.includes(fn) || content.includes(`(${fn})`) || content.includes(`[${stem}]`)) {
      refs.add(fn);
    }
  }
  return [...refs];
}

function extractTopics(content: string, name: string): string[] {
  const topics = new Set<string>();

  const topicPatterns = [
    /\b(?:proxmox|lxc|ansible|caddy|nginx|docker)\b/gi,
    /\b(?:n8n|litellm|vaultwarden|qmd|openclaw)\b/gi,
    /\b(?:acme\s*corp|example\s*inc|initech|globex)\b/gi, // employer names -- customize per user
    /\b(?:pai|skippy|bob|clarisa|april)\b/gi,
    /\b(?:mcp|hook|skill|agent|workflow)\b/gi,
    /\b(?:resume|job\s*search|career|interview|linkedin)\b/gi,
    /\b(?:truenas|smb|nfs|backup)\b/gi,
    /\b(?:audiobook|ffmpeg|media)\b/gi,
    /\b(?:git|github|ci|runner|action)\b/gi,
    /\b(?:claude\s*code|cc|context|compaction)\b/gi,
  ];

  for (const pattern of topicPatterns) {
    const matches = content.matchAll(pattern);
    for (const match of matches) {
      topics.add(match[0].toLowerCase());
    }
  }

  const nameTopics = name.toLowerCase().split(/[-_\s]+/).filter(w => w.length > 2);
  for (const t of nameTopics) topics.add(t);

  return [...topics];
}

function scanMemory(): MemoryFile[] {
  const files: MemoryFile[] = [];

  for (const dir of MEMORY_DIRS) {
    if (!existsSync(dir)) continue;
    const source = dir.includes("pai-private") ? "pai-private" : "auto-memory";

    for (const filename of readdirSync(dir)) {
      if (!filename.endsWith(".md") || filename === "MEMORY.md") continue;
      const filepath = join(dir, filename);
      const stat = statSync(filepath);
      const content = readFileSync(filepath, "utf-8");
      const { name, description, type, body } = parseFrontmatter(content);
      const ageDays = Math.floor((Date.now() - stat.mtimeMs) / (1000 * 60 * 60 * 24));

      files.push({
        path: filepath,
        filename,
        name: name || filename.replace(/\.md$/, ""),
        description,
        type,
        content: body,
        ageDays,
        lastModified: stat.mtime.toISOString().split("T")[0],
        referencedPaths: extractPaths(body),
        crossRefs: [],
        topics: extractTopics(body + " " + name, name),
        lineCount: content.split("\n").length,
        source,
      });
    }
  }

  const allFilenames = files.map(f => f.filename);
  for (const file of files) {
    file.crossRefs = extractCrossRefs(file.content, allFilenames.filter(fn => fn !== file.filename));
  }

  return files;
}

function checkMemoryMdRefs(files: MemoryFile[]): string[] {
  const memoryMdPath = join(homedir(), ".claude", "projects", "-Volumes-ThunderBolt-Development", "memory", "MEMORY.md");
  if (!existsSync(memoryMdPath)) return files.map(f => f.filename);

  const memoryMdContent = readFileSync(memoryMdPath, "utf-8");
  const unreferenced: string[] = [];

  for (const file of files) {
    if (file.source !== "auto-memory") continue;
    if (!memoryMdContent.includes(file.filename)) {
      unreferenced.push(file.filename);
    }
  }
  return unreferenced;
}

function buildReport(files: MemoryFile[]): LintReport {
  const staleEntries = files
    .filter(f => f.ageDays >= STALE_DAYS)
    .sort((a, b) => b.ageDays - a.ageDays)
    .map(f => ({ file: f.filename, name: f.name, ageDays: f.ageDays, description: f.description }));

  const REMOTE_PREFIXES = ["/home/", "/opt/", "/etc/systemd/", "/var/log/", "/mnt/"];
  const brokenRefs: BrokenRef[] = [];
  for (const file of files) {
    for (const ref of file.referencedPaths) {
      const expanded = ref.replace(/^~/, homedir());
      if (!existsSync(expanded)) {
        const isRemote = REMOTE_PREFIXES.some((p) => ref.startsWith(p));
        brokenRefs.push({ file: file.filename, name: file.name, ref, location: isRemote ? "remote" : "local" });
      }
    }
  }

  const orphanedInMemoryMd = checkMemoryMdRefs(files);
  const orphanedFiles = files
    .filter(f => f.source === "auto-memory" && orphanedInMemoryMd.includes(f.filename))
    .map(f => ({ file: f.filename, name: f.name, description: f.description }));

  const crossRefMap: Record<string, string[]> = {};
  for (const file of files) {
    if (file.crossRefs.length > 0) {
      crossRefMap[file.filename] = file.crossRefs;
    }
  }

  const topicIndex: Record<string, string[]> = {};
  for (const file of files) {
    for (const topic of file.topics) {
      if (!topicIndex[topic]) topicIndex[topic] = [];
      topicIndex[topic].push(file.filename);
    }
  }
  const topicClusters: Record<string, string[]> = {};
  for (const [topic, fileList] of Object.entries(topicIndex)) {
    if (fileList.length >= 2) {
      topicClusters[topic] = fileList;
    }
  }

  const allEntries = files
    .sort((a, b) => a.filename.localeCompare(b.filename))
    .map(f => ({
      file: f.filename,
      name: f.name,
      type: f.type,
      ageDays: f.ageDays,
      description: f.description,
      lineCount: f.lineCount,
    }));

  return { scanned: files.length, staleEntries, brokenRefs, orphanedFiles, crossRefMap, topicClusters, allEntries };
}

function printReport(report: LintReport): void {
  console.log(`\nKnowledge Lint Report`);
  console.log(`Scanned ${report.scanned} memory files\n`);

  const issues =
    report.staleEntries.length + report.brokenRefs.length + report.orphanedFiles.length;

  if (issues === 0) {
    console.log("No issues found.\n");
  }

  if (report.staleEntries.length > 0) {
    console.log(`STALE ENTRIES (${report.staleEntries.length} files older than ${STALE_DAYS} days):`);
    for (const e of report.staleEntries) {
      console.log(`  [${e.ageDays}d] ${e.file} -- ${e.description || e.name}`);
    }
    console.log("");
  }

  const localRefs = report.brokenRefs.filter((r) => r.location === "local");
  const remoteRefs = report.brokenRefs.filter((r) => r.location === "remote");

  if (localRefs.length > 0) {
    console.log(`BROKEN LOCAL REFERENCES (${localRefs.length} paths no longer exist on this machine):`);
    for (const r of localRefs) {
      console.log(`  ${r.file}: ${r.ref}`);
    }
    console.log("");
  }

  if (remoteRefs.length > 0) {
    console.log(`REMOTE REFERENCES (${remoteRefs.length} paths on LXCs/servers -- not checkable locally):`);
    for (const r of remoteRefs) {
      console.log(`  ${r.file}: ${r.ref}`);
    }
    console.log("");
  }

  if (report.orphanedFiles.length > 0) {
    console.log(`ORPHANED FILES (${report.orphanedFiles.length} not in MEMORY.md):`);
    for (const o of report.orphanedFiles) {
      console.log(`  ${o.file} -- ${o.description || o.name}`);
    }
    console.log("");
  }

  const multiTopics = Object.entries(report.topicClusters)
    .filter(([_, files]) => files.length >= 3)
    .sort((a, b) => b[1].length - a[1].length);

  if (multiTopics.length > 0) {
    console.log(`TOPIC CLUSTERS (${multiTopics.length} topics spanning 3+ files -- review for overlap):`);
    for (const [topic, fileList] of multiTopics) {
      console.log(`  "${topic}" (${fileList.length} files): ${fileList.join(", ")}`);
    }
    console.log("");
  }

  const localCount = report.brokenRefs.filter((r) => r.location === "local").length;
  const remoteCount = report.brokenRefs.filter((r) => r.location === "remote").length;
  console.log(`Summary: ${report.staleEntries.length} stale, ${localCount} broken local refs, ${remoteCount} remote refs, ${report.orphanedFiles.length} orphaned`);
}

function printStale(files: MemoryFile[]): void {
  const stale = files.filter(f => f.ageDays >= STALE_DAYS).sort((a, b) => b.ageDays - a.ageDays);
  if (stale.length === 0) {
    console.log(`No entries older than ${STALE_DAYS} days.`);
    return;
  }
  console.log(`\nStale entries (${stale.length} files, ${STALE_DAYS}+ days old):\n`);
  for (const f of stale) {
    console.log(`  [${f.ageDays}d] ${f.filename} (${f.source})`);
    console.log(`         ${f.description || f.name}`);
  }
}

function printBrokenRefs(files: MemoryFile[]): void {
  let count = 0;
  for (const file of files) {
    for (const ref of file.referencedPaths) {
      const expanded = ref.replace(/^~/, homedir());
      if (!existsSync(expanded)) {
        if (count === 0) console.log("\nBroken file references:\n");
        console.log(`  ${file.filename}: ${ref}`);
        count++;
      }
    }
  }
  if (count === 0) console.log("No broken file references found.");
}

function printTopics(files: MemoryFile[]): void {
  const topicIndex: Record<string, string[]> = {};
  for (const file of files) {
    for (const topic of file.topics) {
      if (!topicIndex[topic]) topicIndex[topic] = [];
      topicIndex[topic].push(file.filename);
    }
  }

  const clusters = Object.entries(topicIndex)
    .filter(([_, f]) => f.length >= 2)
    .sort((a, b) => b[1].length - a[1].length);

  console.log(`\nTopic clusters (${clusters.length} topics shared across files):\n`);
  for (const [topic, fileList] of clusters) {
    console.log(`  "${topic}" (${fileList.length}): ${fileList.join(", ")}`);
  }
}

function printOrphans(files: MemoryFile[]): void {
  const orphaned = checkMemoryMdRefs(files);
  const orphanFiles = files.filter(f => f.source === "auto-memory" && orphaned.includes(f.filename));
  if (orphanFiles.length === 0) {
    console.log("All auto-memory files are referenced in MEMORY.md.");
    return;
  }
  console.log(`\nOrphaned files (${orphanFiles.length} not in MEMORY.md):\n`);
  for (const f of orphanFiles) {
    console.log(`  ${f.filename} -- ${f.description || f.name}`);
  }
}

const { command, flags } = parseArgs();
const files = scanMemory();

switch (command) {
  case "scan": {
    const report = buildReport(files);
    if (flags.json === "true") {
      console.log(JSON.stringify(report, null, 2));
    } else {
      printReport(report);
    }
    break;
  }
  case "stale":
    printStale(files);
    break;
  case "broken-refs":
    printBrokenRefs(files);
    break;
  case "topics":
    printTopics(files);
    break;
  case "orphans":
    printOrphans(files);
    break;
  default:
    console.error(`Unknown command: ${command}. Use --help for usage.`);
    process.exit(1);
}
