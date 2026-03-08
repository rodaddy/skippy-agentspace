#!/usr/bin/env bun
// skippy-state.ts -- Minimal parser for reconcile's plan/summary data needs.
// Parses YAML frontmatter and markdown task format. No external dependencies.

export interface Task {
  number: number; name: string; files: string[];
  action: string; verify: string; done: string;
}
export type TaskStatus = "DONE" | "MODIFIED" | "SKIPPED" | "ADDED";
type Classified = { task: Task; status: TaskStatus; evidence: string };

// NOTE: Best-effort parser for simple YAML frontmatter. Known limitations:
// - Multiline field values (e.g. `description: |`) only capture the first line
// - Nested arrays-of-objects (mixed sub-lists and sub-objects under one key) may produce garbled output
//   because ctx.obj and ctx.arr are initialized simultaneously for empty-value keys
// For complex YAML, use a real parser (js-yaml, yaml).
export function parseFrontmatter(content: string): Record<string, unknown> {
  content = content.replace(/\r\n/g, "\n");
  const m = content.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const result: Record<string, unknown> = {};
  let ctx = { key: "", obj: null as Record<string, unknown> | null, arr: null as string[] | null, indent: 0 };

  for (const line of m[1].split("\n")) {
    // Nested list item (e.g. "  - value" or "    - value")
    const listItem = line.match(/^(\s+)- (.+)/);
    if (listItem && ctx.arr && listItem[1].length >= ctx.indent) {
      ctx.arr.push(listItem[2].trim().replace(/^["']|["']$/g, ""));
      result[ctx.key] = [...ctx.arr]; continue;
    }
    // Nested key:value (e.g. "  total_phases: 16")
    const nested = line.match(/^(\s{2,})(\w[\w.-]*)\s*:\s*(.*)/);
    if (nested && ctx.obj) {
      const v = nested[3].trim().replace(/^["']|["']$/g, "");
      ctx.obj[nested[2]] = /^\d+$/.test(v) ? parseInt(v, 10) : v === "true" ? true : v === "false" ? false : v;
      result[ctx.key] = { ...ctx.obj }; continue;
    }
    // Top-level key:value
    const kv = line.match(/^(\w[\w.-]*)\s*:\s*(.*)/);
    if (!kv) { ctx.obj = null; ctx.arr = null; continue; }
    const [, key, raw] = kv;
    const val = raw.trim().replace(/^["']|["']$/g, "");
    ctx.key = key; ctx.obj = null; ctx.arr = null;
    if (val.startsWith("[") && val.endsWith("]")) {
      result[key] = val.slice(1, -1).split(",").map(s => s.trim().replace(/^["']|["']$/g, "")).filter(Boolean);
    } else if (val === "" || val === "|") {
      ctx.obj = {}; ctx.arr = []; ctx.indent = 2; result[key] = {};
    } else if (val === "true") result[key] = true;
    else if (val === "false") result[key] = false;
    else if (/^\d+$/.test(val)) result[key] = parseInt(val, 10);
    else result[key] = val;
  }
  return result;
}

export function extractTasks(content: string): Task[] {
  const headings = [...content.matchAll(/^## Task (\d+): (.+)$/gm)];
  return headings.map((h, i) => {
    const block = content.slice(h.index! + h[0].length, headings[i + 1]?.index ?? content.length);
    const f = (n: string) => block.match(new RegExp(`^- ${n}:\\s*(.+)`, "m"))?.[1]?.replace(/`/g, "").trim() ?? "";
    return {
      number: parseInt(h[1], 10), name: h[2].trim(),
      files: f("files").split(",").map(s => s.trim()).filter(Boolean),
      action: f("action"), verify: f("verify"), done: f("done"),
    };
  });
}

export function classifyTaskStatus(planned: Task[], summaryContent: string): Classified[] {
  const lower = summaryContent.toLowerCase();
  const devs = (summaryContent.match(/## Deviations from Plan[\s\S]*?(?=\n## |$)/)?.[0] ?? "").toLowerCase();
  const results: Classified[] = planned.map(task => {
    const allWords = task.name.toLowerCase().split(/\s+/);
    const longWords = allWords.filter(w => w.length > 3);
    // BUG 1 fix: If all words are <=3 chars (e.g. "Add SSH key"), longWords is empty
    // and [].some() returns false, causing false-positive SKIPPED. Fall back to unfiltered words.
    const needle = longWords.length > 0 ? longWords : allWords;
    const found = needle.some(w => lower.includes(w));
    const modified = needle.some(w => devs.includes(w));
    return { task, status: found && modified ? "MODIFIED" : found ? "DONE" : "SKIPPED", evidence: found ? (modified ? "Found with deviations noted" : "Found in summary") : "Not found in summary" };
  });
  // Detect ADDED tasks
  for (const [, name] of summaryContent.matchAll(/\*\*Task \d+: (.+?)\*\*/g)) {
    if (!planned.some(t => t.name.toLowerCase() === name.trim().toLowerCase()))
      results.push({ task: { number: 0, name: name.trim(), files: [], action: "", verify: "", done: "" }, status: "ADDED", evidence: "In summary but not in plan" });
  }
  return results;
}

if (import.meta.main) {
  const [cmd, ...args] = Bun.argv.slice(2);
  const read = async (p: string) => {
    try { return await Bun.file(p).text(); }
    catch { console.error(`Error: File not found: ${p}`); process.exit(1); }
  };
  if (cmd === "parse-frontmatter" && args[0]) console.log(JSON.stringify(parseFrontmatter(await read(args[0])), null, 2));
  else if (cmd === "extract-tasks" && args[0]) console.log(JSON.stringify(extractTasks(await read(args[0])), null, 2));
  else if (cmd === "classify-tasks" && args[0] && args[1])
    console.log(JSON.stringify(classifyTaskStatus(extractTasks(await read(args[0])), await read(args[1])), null, 2));
  else { console.error("Usage: skippy-state.ts <parse-frontmatter|extract-tasks|classify-tasks> <file> [summary]"); process.exit(1); }
}
