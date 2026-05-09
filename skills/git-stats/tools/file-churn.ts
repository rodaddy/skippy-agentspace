#!/usr/bin/env bun
/**
 * File Churn Analyzer
 *
 * Identifies most frequently modified files in git repository
 * Usage: bun file-churn.ts [--repo PATH] [--limit N] [--since DATE] [--all]
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';

interface FileStats {
  path: string;
  changes: number;
}

function parseArgs(): { repo: string; limit: number; since: string | null; showAll: boolean } {
  const args = process.argv.slice(2);

  if (args.includes('--help')) {
    console.log('Usage: bun file-churn.ts [OPTIONS]');
    console.log('');
    console.log('Analyze file modification frequency in git repository');
    console.log('');
    console.log('Options:');
    console.log('  --repo PATH     Repository path (default: current directory)');
    console.log('  --limit N       Show top N files (default: 20)');
    console.log('  --since DATE    Analyze changes since date (default: all history)');
    console.log('  --all           Show all files (no limit)');
    console.log('  --help          Show this help message');
    console.log('');
    console.log('Examples:');
    console.log('  bun file-churn.ts');
    console.log('  bun file-churn.ts --repo /path/to/repo --limit 50');
    console.log('  bun file-churn.ts --since "3 months ago"');
    console.log('  bun file-churn.ts --since "2025-01-01" --all');
    process.exit(0);
  }

  let repo = '.';
  let limit = 20;
  let since: string | null = null;
  let showAll = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--repo' && args[i + 1]) {
      repo = args[i + 1];
      i++;
    } else if (args[i] === '--limit' && args[i + 1]) {
      limit = parseInt(args[i + 1], 10);
      i++;
    } else if (args[i] === '--since' && args[i + 1]) {
      since = args[i + 1];
      i++;
    } else if (args[i] === '--all') {
      showAll = true;
    }
  }

  return { repo, limit, since, showAll };
}

function getFileChurn(repo: string, since: string | null): FileStats[] {
  // Verify git repo exists
  if (!existsSync(`${repo}/.git`)) {
    throw new Error(`Not a git repository: ${repo}`);
  }

  try {
    // Build git log command with optional date filter
    let cmd = `cd "${repo}" && git log --all --name-only --format=""`;
    if (since) {
      cmd += ` --since="${since}"`;
    }
    cmd += ' 2>/dev/null';

    const output = execSync(cmd, { encoding: 'utf-8' }).trim();

    if (!output) {
      return [];
    }

    // Count file occurrences
    const files = output.split('\n').filter(f => f.trim() !== '');
    const counts: Record<string, number> = {};

    for (const file of files) {
      if (file) {
        counts[file] = (counts[file] || 0) + 1;
      }
    }

    // Convert to array
    const stats: FileStats[] = Object.entries(counts).map(([path, changes]) => ({
      path,
      changes
    }));

    // Sort by change count (descending)
    return stats.sort((a, b) => b.changes - a.changes);

  } catch (error) {
    throw new Error(`Failed to analyze file churn: ${error.message}`);
  }
}

function formatOutput(stats: FileStats[], repo: string, limit: number, since: string | null, showAll: boolean) {
  console.log('\n## 🔥 File Churn Analysis\n');

  const repoPath = execSync(`cd "${repo}" && pwd`, { encoding: 'utf-8' }).trim();
  console.log(`**Repository:** ${repoPath}`);

  if (since) {
    console.log(`**Period:** Since ${since}`);
  } else {
    console.log(`**Period:** All history`);
  }

  console.log(`**Total files modified:** ${stats.length.toLocaleString()}\n`);
  console.log('─'.repeat(70));

  const displayCount = showAll ? stats.length : Math.min(limit, stats.length);

  console.log('\nRank  Changes  File Path');
  console.log('─'.repeat(70));

  for (let i = 0; i < displayCount; i++) {
    const stat = stats[i];
    const rank = (i + 1).toString().padStart(4);
    const changes = stat.changes.toString().padStart(7);
    const path = stat.path;

    console.log(`${rank}  ${changes}  ${path}`);
  }

  if (!showAll && stats.length > limit) {
    console.log(`\n... and ${stats.length - limit} more files`);
  }

  console.log('\n' + '─'.repeat(70) + '\n');
}

// Main execution
try {
  const { repo, limit, since, showAll } = parseArgs();
  const stats = getFileChurn(repo, since);

  if (stats.length === 0) {
    console.log('\n📭 No file changes found in specified period.\n');
    process.exit(0);
  }

  formatOutput(stats, repo, limit, since, showAll);
  process.exit(0);

} catch (error) {
  console.error(`\n❌ Error: ${error.message}\n`);
  process.exit(1);
}
