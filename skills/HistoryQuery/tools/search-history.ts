#!/usr/bin/env bun
/**
 * PAI History Search Tool
 *
 * Searches across all PAI history (sessions, learnings, decisions, etc.)
 * Usage: bun search-history.ts "search term" [--type sessions|learnings|all]
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const PAI_HOME = process.env.PAI_HOME || join(homedir(), '.config', 'pai');
const HISTORY_DIR = join(PAI_HOME, 'history');

interface SearchResult {
  file: string;
  type: string;
  timestamp: string;
  matches: number;
}

function parseArgs(): { query: string; type: string; limit: number } {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: bun search-history.ts "search term" [--type sessions|learnings|all] [--limit N]');
    process.exit(1);
  }

  let query = args[0];
  let type = 'all';
  let limit = 20;

  for (let i = 1; i < args.length; i++) {
    if (args[i] === '--type' && args[i + 1]) {
      type = args[i + 1];
      i++;
    } else if (args[i] === '--limit' && args[i + 1]) {
      limit = parseInt(args[i + 1], 10);
      i++;
    }
  }

  return { query, type, limit };
}

function searchMarkdownFiles(query: string, type: string): SearchResult[] {
  const results: SearchResult[] = [];

  // Determine which directories to search
  const searchDirs: string[] = [];
  if (type === 'all') {
    searchDirs.push('sessions', 'learnings', 'decisions', 'research', 'execution');
  } else if (type === 'execution') {
    searchDirs.push('execution/features', 'execution/bugs', 'execution/refactors');
  } else {
    searchDirs.push(type);
  }

  for (const dir of searchDirs) {
    const fullPath = join(HISTORY_DIR, dir);
    if (!existsSync(fullPath)) continue;

    try {
      // Search for files containing the query
      const grepCmd = `grep -r "${query}" "${fullPath}" --include="*.md" -l 2>/dev/null || true`;
      const output = execSync(grepCmd, { encoding: 'utf-8' });

      if (output.trim()) {
        const files = output.trim().split('\n');

        for (const file of files) {
          // Count matches in file
          const countCmd = `grep -c "${query}" "${file}" 2>/dev/null || echo 0`;
          const matchCount = parseInt(execSync(countCmd, { encoding: 'utf-8' }).trim(), 10);

          // Extract timestamp from filename
          const filename = file.split('/').pop() || '';
          const timestampMatch = filename.match(/^(\d{4}-\d{2}-\d{2}[-T]\d{2}[:\d]+)/);
          const timestamp = timestampMatch ? timestampMatch[1].replace('T', ' ').replace(/-/g, ':').substring(0, 16) : 'unknown';

          // Determine type from path
          const fileType = file.includes('/sessions/') ? 'session' :
                          file.includes('/learnings/') ? 'learning' :
                          file.includes('/decisions/') ? 'decision' :
                          file.includes('/research/') ? 'research' :
                          file.includes('/features/') ? 'feature' :
                          file.includes('/bugs/') ? 'bug' :
                          file.includes('/refactors/') ? 'refactor' : 'other';

          results.push({
            file,
            type: fileType,
            timestamp,
            matches: matchCount
          });
        }
      }
    } catch (error) {
      // Silent fail for individual directories
    }
  }

  // Sort by timestamp (newest first)
  return results.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
}

function searchJSONL(query: string): { totalEvents: number; byType: Record<string, number> } {
  const rawOutputsDir = join(HISTORY_DIR, 'raw-outputs');
  if (!existsSync(rawOutputsDir)) {
    return { totalEvents: 0, byType: {} };
  }

  try {
    const grepCmd = `find "${rawOutputsDir}" -name "*.jsonl" -exec grep -h "${query}" {} \\; 2>/dev/null || true`;
    const output = execSync(grepCmd, { encoding: 'utf-8' });

    if (!output.trim()) {
      return { totalEvents: 0, byType: {} };
    }

    const lines = output.trim().split('\n');
    const byType: Record<string, number> = {};

    for (const line of lines) {
      try {
        const event = JSON.parse(line);
        const type = event.hook_event_type || 'unknown';
        byType[type] = (byType[type] || 0) + 1;
      } catch {
        // Skip invalid JSON
      }
    }

    return { totalEvents: lines.length, byType };
  } catch (error) {
    return { totalEvents: 0, byType: {} };
  }
}

function formatResults(query: string, mdResults: SearchResult[], jsonlResults: any, limit: number) {
  console.log('\n## 🔍 PAI History Search Results\n');
  console.log(`**Query:** "${query}"`);
  console.log(`**Found:** ${mdResults.length} files, ${jsonlResults.totalEvents} events\n`);
  console.log('─'.repeat(60));

  // Group by type
  const byType: Record<string, SearchResult[]> = {};
  for (const result of mdResults.slice(0, limit)) {
    if (!byType[result.type]) byType[result.type] = [];
    byType[result.type].push(result);
  }

  // Display grouped results
  const typeOrder = ['session', 'learning', 'decision', 'research', 'feature', 'bug', 'refactor', 'other'];

  for (const type of typeOrder) {
    if (!byType[type] || byType[type].length === 0) continue;

    const emoji = type === 'session' ? '📋' :
                  type === 'learning' ? '💡' :
                  type === 'decision' ? '🎯' :
                  type === 'research' ? '🔬' :
                  type === 'feature' ? '✨' :
                  type === 'bug' ? '🐛' :
                  type === 'refactor' ? '♻️' : '📄';

    console.log(`\n### ${emoji} ${type.charAt(0).toUpperCase() + type.slice(1)}s (${byType[type].length})`);

    for (const result of byType[type].slice(0, 5)) {
      const relativePath = result.file.replace(HISTORY_DIR + '/', '');
      console.log(`- **${result.timestamp}** - ${result.matches} match${result.matches > 1 ? 'es' : ''}`);
      console.log(`  \`${relativePath}\``);
    }

    if (byType[type].length > 5) {
      console.log(`  ... and ${byType[type].length - 5} more`);
    }
  }

  // Show event summary if any
  if (jsonlResults.totalEvents > 0) {
    console.log('\n### 📊 Event Log Matches\n');
    console.log(`**Total events:** ${jsonlResults.totalEvents}\n`);

    const sortedTypes = Object.entries(jsonlResults.byType)
      .sort(([, a], [, b]) => (b as number) - (a as number));

    for (const [type, count] of sortedTypes.slice(0, 5)) {
      console.log(`- ${type}: ${count}`);
    }
  }

  if (mdResults.length > limit) {
    console.log(`\n*Showing ${limit} of ${mdResults.length} results. Use --limit N to see more.*`);
  }

  console.log('\n' + '─'.repeat(60));
  console.log('\n**Use:** `cat <file>` to read full content\n');
}

// Main
const { query, type, limit } = parseArgs();

if (!existsSync(HISTORY_DIR)) {
  console.error(`❌ History directory not found: ${HISTORY_DIR}`);
  console.error('   PAI may not have captured any data yet.');
  process.exit(1);
}

const mdResults = searchMarkdownFiles(query, type);
const jsonlResults = searchJSONL(query);

formatResults(query, mdResults, jsonlResults, limit);
